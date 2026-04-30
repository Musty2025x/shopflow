# 🛍 ShopFlow — E-Commerce App on EC2 + RDS MySQL

Full-stack e-commerce application: **Node.js + Express** backend, vanilla JS frontend, **AWS RDS MySQL** database, containerised with **Docker + docker-compose**, reverse proxied by **Nginx**.

---

## 📁 Project Structure

```
shopflow/
├── backend/
│   ├── config/
│   │   ├── db.js          # RDS MySQL connection pool
│   │   ├── migrate.js     # Creates all tables
│   │   └── seed.js        # Sample products & admin user
│   ├── middleware/
│   │   └── auth.js        # JWT auth + admin guard
│   ├── routes/
│   │   ├── auth.js        # POST /register /login GET /me
│   │   ├── products.js    # CRUD + search + pagination
│   │   ├── categories.js  # GET/POST categories
│   │   ├── cart.js        # GET/POST/PUT/DELETE cart
│   │   └── orders.js      # POST checkout, GET orders
│   ├── server.js          # Express entry point
│   └── package.json
├── frontend/
│   └── index.html         # Full SPA: products, cart, auth, checkout
├── nginx/
│   └── nginx.conf         # Reverse proxy to Node.js
├── Dockerfile             # Multi-stage build
├── docker-compose.yml     # app + nginx + dozzle
├── .env.example           # Environment variable template
└── deploy.sh              # EC2 bootstrap script
```

---

## ⚙️ AWS Setup

### Step 1 — Create RDS MySQL instance

1. **AWS Console → RDS → Create database**
2. Engine: **MySQL 8.0**
3. Template: **Free tier** (dev) or **Production**
4. DB identifier: `shopflow`
5. Master username: `shopflow_user`
6. Master password: (save this!)
7. Initial database name: `shopflow-user`
8. **VPC**: same VPC as your EC2 instance
9. **Public access**: No (EC2 accesses it privately)
10. Security group inbound: allow **port 3306** from EC2 security group

Copy the **Endpoint** from RDS → it goes in your `.env` as `DB_HOST`.

### Step 2 — Launch EC2

- AMI: Ubuntu 22.04 LTS
- Type: t3.small or t3.medium
- Security Group inbound: 22 (SSH), 80 (HTTP), 8080 (logs)
- Same VPC as RDS

---

## 🚀 Deploy

### Option A — User Data (auto on launch)

Paste `deploy.sh` into EC2 → Advanced → User data.

### Option B — Manual SSH

```bash
ssh -i your-key.pem ubuntu@<EC2-IP>

# Clone and run deploy script
git clone https://github.com/YOUR_USERNAME/shopflow.git /opt/shopflow
cd /opt/shopflow
chmod +x deploy.sh
./deploy.sh
```

### Step 3 — Configure .env

```bash
sudo nano /opt/shopflow/.env
```

Fill in your RDS details:
```env
DB_HOST=your-rds-instance.xxxxxxxx.us-east-1.rds.amazonaws.com
DB_NAME=shopflow
DB_USER=shopflow_user
DB_PASSWORD=your-strong-password
JWT_SECRET=change-this-to-a-long-random-secret
```

### Step 4 — Start

```bash
cd /opt/shopflow
docker-compose up -d --build
docker-compose exec app node backend/config/migrate.js
docker-compose exec app node backend/config/seed.js
```

---

## 🌐 Access

| URL | Description |
|-----|-------------|
| `http://<EC2-IP>/` | ShopFlow storefront |
| `http://<EC2-IP>/api/products` | Products API |
| `http://<EC2-IP>/health` | Health check |
| `http://<EC2-IP>:8080` | Dozzle log viewer |

**Default admin:** `admin@shopflow.com` / `admin123`

---

## 📡 API Reference

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/api/auth/register` | — | Register user |
| POST | `/api/auth/login` | — | Login |
| GET | `/api/auth/me` | ✅ | Get profile |
| GET | `/api/products` | — | List products (search, filter, page) |
| GET | `/api/products/:slug` | — | Product detail |
| POST | `/api/products` | Admin | Create product |
| PUT | `/api/products/:id` | Admin | Update product |
| DELETE | `/api/products/:id` | Admin | Delete product |
| GET | `/api/categories` | — | All categories |
| GET | `/api/cart` | ✅ | View cart |
| POST | `/api/cart` | ✅ | Add to cart |
| PUT | `/api/cart/:id` | ✅ | Update quantity |
| DELETE | `/api/cart/:id` | ✅ | Remove item |
| POST | `/api/orders` | ✅ | Place order (checkout) |
| GET | `/api/orders` | ✅ | My orders |
| GET | `/api/orders/all` | Admin | All orders |

---

## 🔧 Useful Commands

```bash
# Rebuild after code changes
docker-compose up -d --build

# View live logs
docker-compose logs -f app
docker-compose logs -f nginx

# Shell into app container
docker-compose exec app sh

# Re-run migrations
docker-compose exec app node backend/config/migrate.js

# Restart single service
docker-compose restart app
```

---

## 🗂 GitLab Portfolio
```
gitlab.com/musty2025x/devops-portfolio-2025
└── shopflow-ec2-rds/
```
