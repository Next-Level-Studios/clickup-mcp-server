# Dockerfile for taazkareem/clickup-mcp-server (TypeScript, matches original repo)
FROM node:18-alpine AS builder

WORKDIR /app

# Copy package files
COPY package.json package-lock.json* ./

# Install all deps for build
RUN npm ci

# Copy source and build TS to JS
COPY src ./src
COPY tsconfig.json ./
RUN npm run build

# Runtime stage (smaller image)
FROM node:18-alpine AS runtime

WORKDIR /app

# Copy built JS and prod deps
COPY --from=builder /app/build ./build
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./

# Expose MCP default port
EXPOSE 3231

# Health check for Dokploy/Traefik
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3231 || exit 1

# Run the built server
CMD ["node", "build/index.js"]
