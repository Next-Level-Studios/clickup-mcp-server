# ---------- Builder ----------
FROM node:20-alpine AS builder

WORKDIR /app

# Copy only package files first
COPY package*.json ./

# Install dependencies BUT skip the deadly "prepare" script
RUN npm ci --ignore-scripts

# Now copy source code (tsconfig.json finally arrives)
COPY . .

# Manually run the build script now that everything exists
RUN npm run build

# Re-install only production dependencies for the final image (tiny & secure)
RUN npm ci --only=production

# ---------- Runtime ----------
FROM node:20-alpine

WORKDIR /app

COPY --from=builder /app/build ./build
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./

EXPOSE 3231

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3231/health', (r) => process.exit(r.statusCode === 200 ? 0 : 1))" || exit 1

CMD ["node", "build/index.js"]
