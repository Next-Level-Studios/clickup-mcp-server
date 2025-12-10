# ---------- Builder ----------
FROM node:20-alpine AS builder

WORKDIR /app

# 1. Copy package files
COPY package*.json ./

# 2. Install ALL dependencies (devDependencies needed for build)
RUN npm ci

# 3. NOW copy the rest of the source code (including tsconfig.json)
COPY . .

# 4. Build the TypeScript code
RUN npm run build

# ---------- Runtime ----------
FROM node:20-alpine

WORKDIR /app

# Copy only what we actually need at runtime
COPY --from=builder /app/build ./build
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package*.json ./

# Optional: copy .env.example or other tiny runtime files if you use them
# COPY --from=builder /app/.env.example ./

EXPOSE 3231

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3231/health', (r) => process.exit(r.statusCode === 200 ? 0 : 1))" || exit 1

CMD ["node", "build/index.js"]
