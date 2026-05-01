#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# ShopFlow — EC2 Bootstrap Script
# Passed as user_data via Terraform templatefile()
# Runs on first boot — installs Docker, clones repo,
# writes .env, runs migrations, starts docker-compose
# ═══════════════════════════════════════════════════════════════
set -euo pipefail

LOG="/var/log/shopflow-bootstrap.log"
exec > >(tee -a "$LOG") 2>&1

# ── Template vars injected by Terraform ──────────────────────
APP_DIR="${app_dir}"
REPO_URL="${repo_url}"
DB_HOST="${db_host}"
DB_PORT="${db_port}"
DB_NAME="${db_name}"
DB_USER="${db_user}"
DB_PASSWORD="${db_password}"
JWT_SECRET="${jwt_secret}"

banner() {
  echo ""
  echo "══════════════════════════════════════════"
  echo "  $1"
  echo "══════════════════════════════════════════"
}

banner "ShopFlow Bootstrap — $(date)"
echo "  APP_DIR:  $APP_DIR"
echo "  REPO_URL: $REPO_URL"
echo "  DB_HOST:  $DB_HOST"

# ── 1. System update ─────────────────────────────────────────
banner "[1/7] System update"
apt-get update -y
apt-get install -y curl git unzip mysql-client

# ── 2. Install Docker ─────────────────────────────────────────
banner "[2/7] Installing Docker"
curl -fsSL https://get.docker.com | sh
systemctl enable docker
systemctl start docker
usermod -aG docker ubuntu
echo "  Docker $(docker --version) installed"

# ── 3. Install Docker Compose v2 ─────────────────────────────
banner "[3/7] Installing Docker Compose"
curl -SL "https://github.com/docker/compose/releases/download/v2.27.0/docker-compose-linux-x86_64" \
  -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
echo "  Docker Compose $(/usr/local/bin/docker-compose --version) installed"

# ── 4. Clone repo ─────────────────────────────────────────────
banner "[4/7] Cloning repository"
if [ -d "$APP_DIR/.git" ]; then
  echo "  Repo exists — pulling latest..."
  cd "$APP_DIR" && git pull
else
  git clone "$REPO_URL" "$APP_DIR"
fi
echo "  Repo cloned to $APP_DIR"

# ── 5. Write .env ─────────────────────────────────────────────
banner "[5/7] Writing .env"
cat > "$APP_DIR/.env" << ENVEOF
NODE_ENV=production
PORT=5000
JWT_SECRET=$JWT_SECRET
DB_HOST=$DB_HOST
DB_PORT=$DB_PORT
DB_NAME=$DB_NAME
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD
DB_SSL=false
CORS_ORIGIN=*
ENVEOF
echo "  .env written"

# ── 6. Wait for RDS to be available ──────────────────────────
banner "[6/7] Waiting for RDS MySQL"
echo "  Testing connection to $DB_HOST:$DB_PORT..."
RETRY=0
until mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" \
      -e "SELECT 1;" > /dev/null 2>&1; do
  RETRY=$((RETRY + 1))
  [ $RETRY -ge 20 ] && echo "  ERROR: RDS not reachable after 20 retries" && exit 1
  echo "  Waiting for RDS... ($RETRY/20)"
  sleep 15
done
echo "  RDS is reachable!"

# Create database if it doesn't exist
mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" \
  -e "CREATE DATABASE IF NOT EXISTS \`$DB_NAME\`;"
echo "  Database '$DB_NAME' ready"

# ── 7. Build and start containers ─────────────────────────────
banner "[7/7] Starting docker-compose"
cd "$APP_DIR"
/usr/local/bin/docker-compose down --remove-orphans 2>/dev/null || true
/usr/local/bin/docker-compose up -d --build

echo "  Waiting 30s for containers to be ready..."
sleep 30
docker ps

# Run migrations and seed
echo "  Running DB migrations..."
/usr/local/bin/docker-compose exec -T app node config/migrate.js && echo "  Migrations OK"

echo "  Seeding database..."
/usr/local/bin/docker-compose exec -T app node config/seed.js && echo "  Seed OK"

# ── Health check ──────────────────────────────────────────────
HTTP=$(curl -so /dev/null -w "%%{http_code}" http://localhost/ || echo "000")
echo ""
echo "  HTTP health check: $HTTP"

PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "unknown")

banner "Bootstrap complete — $(date)"
echo "  App:        http://$PUBLIC_IP/"
echo "  Log viewer: http://$PUBLIC_IP:8080"
echo "  SSH:        ssh -i <key.pem> ubuntu@$PUBLIC_IP"
echo "  Admin:      admin@shopflow.com / admin123"
echo ""
echo "  Monitor:    sudo tail -f $LOG"
echo "  App logs:   docker logs -f shopflow_app"
