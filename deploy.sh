#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# ShopFlow — EC2 Bootstrap / Deploy Script
# Run as EC2 User Data OR manually after SSH
# Ubuntu 22.04 / Amazon Linux 2023
# ═══════════════════════════════════════════════════════════════
set -euo pipefail
exec > >(tee /var/log/shopflow-deploy.log) 2>&1

APP_DIR="/opt/shopflow"
REPO_URL="${REPO_URL:-https://github.com/Musty2025x/shopflow.git}"

banner() { echo ""; echo "══════════════════════════════════"; echo "  $1"; echo "══════════════════════════════════"; }

banner "ShopFlow EC2 Deploy — $(date)"

# ── 1. System deps ────────────────────────────────────────────
banner "[1/6] System update"
if command -v apt-get &>/dev/null; then
  apt-get update -y && apt-get install -y curl git unzip
else
  dnf update -y && dnf install -y curl git unzip
fi

# ── 2. Docker ─────────────────────────────────────────────────
banner "[2/6] Installing Docker"
if ! command -v docker &>/dev/null; then
  curl -fsSL https://get.docker.com | sh
  systemctl enable docker && systemctl start docker
  usermod -aG docker ubuntu 2>/dev/null || usermod -aG docker ec2-user 2>/dev/null || true
fi
docker --version

# ── 3. Docker Compose ─────────────────────────────────────────
banner "[3/6] Installing Docker Compose"
if ! command -v docker-compose &>/dev/null; then
  curl -SL "https://github.com/docker/compose/releases/download/v2.27.0/docker-compose-linux-x86_64" \
    -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
fi
docker-compose --version

# ── 4. Clone / pull repo ──────────────────────────────────────
banner "[4/6] Setting up app"
if [ -d "$APP_DIR/.git" ]; then
  echo "Pulling latest..."
  cd "$APP_DIR" && git pull
else
  git clone "$REPO_URL" "$APP_DIR"
fi

cd "$APP_DIR"

# Copy env file if not present
if [ ! -f .env ]; then
  cp .env.example .env
  echo ""
  echo "⚠  .env created from .env.example"
  echo "   Edit /opt/shopflow/.env with your RDS credentials before continuing!"
  echo "   Then re-run: cd /opt/shopflow && docker-compose up -d --build"
  exit 0
fi

# ── 5. Build & start ──────────────────────────────────────────
banner "[5/6] Building and starting containers"
docker-compose down --remove-orphans 2>/dev/null || true
docker-compose up -d --build

echo "Waiting for app to be ready..."
sleep 20
docker ps

# ── 6. Run migrations + seed ──────────────────────────────────
banner "[6/6] Running DB migrations"
docker-compose exec -T app node backend/config/migrate.js && echo "  Migrations OK"
docker-compose exec -T app node backend/config/seed.js    && echo "  Seed OK"

# ── Health check ──────────────────────────────────────────────
HTTP=$(curl -so /dev/null -w "%{http_code}" http://localhost/health || echo "000")
echo ""
echo "HTTP health check: $HTTP"

PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "YOUR_EC2_IP")

banner "Deploy complete — $(date)"
echo "  🌐  App:      http://$PUBLIC_IP/"
echo "  📋  Logs:     http://$PUBLIC_IP:8080"
echo "  🔑  SSH:      ssh -i <key.pem> ubuntu@$PUBLIC_IP"
echo ""
echo "  Admin login:  admin@shopflow.com / admin123"
echo ""
echo "  Useful commands:"
echo "  docker-compose logs -f app         # app logs"
echo "  docker-compose exec app sh         # shell into app"
echo "  cat /var/log/shopflow-deploy.log   # this log"
