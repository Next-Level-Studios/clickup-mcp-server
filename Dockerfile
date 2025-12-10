# Build stage
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production && npm cache clean --force

# Copy source code
COPY . .

# Production stage
FROM node:20-alpine

WORKDIR /app

# Copy built dependencies from builder
COPY --from=builder /app/node_modules ./node_modules

# Copy source code
COPY . .

# Expose port
EXPOSE 3231

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3231/health', (res) => { process.exit(res.statusCode === 200 ? 0 : 1) })"

# Start the server
CMD ["npm", "start"]
