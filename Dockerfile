# ═══════════════════════════════════════════════════════════════
# ShopFlow — Multi-Stage Dockerfile
# Stage 1: deps    → install production dependencies
# Stage 2: runtime → lean node:18-alpine image
# ═══════════════════════════════════════════════════════════════

# ── Stage 1: Install dependencies ────────────────────────────
FROM node:18-alpine AS deps
WORKDIR /app
COPY backend/package*.json ./
RUN npm install --only=production && npm cache clean --force

# ── Stage 2: Runtime ─────────────────────────────────────────
FROM node:18-alpine AS runtime

LABEL maintainer="musty101"
LABEL project="shopflow-ecommerce"

# Create non-root user for security
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# Copy node_modules from deps stage
COPY --from=deps /app/node_modules ./node_modules

# Copy backend source
COPY backend/ ./backend/

# Copy frontend (served as static files by Express)
COPY frontend/ ./frontend/

# Set working directory to backend
WORKDIR /app/backend

# Run as non-root
USER appuser

EXPOSE 5000

HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD wget -qO- http://localhost:5000/health || exit 1

CMD ["node", "server.js"]
