# Multi-stage build para optimizar tamaño de imagen

# Stage 1: Build
FROM node:22-alpine AS builder

WORKDIR /app

# Copiar package files
COPY package*.json ./
COPY tsconfig.json ./
COPY prisma ./prisma/

# Instalar dependencias (usar npm install en lugar de npm ci)
RUN npm install

# Copiar código fuente
COPY src ./src

# Generar Prisma Client
RUN npx prisma generate

# Build
RUN npm run build

# Stage 2: Production
FROM node:22-alpine

WORKDIR /app

# Instalar solo dependencias de producción (usar npm install en lugar de npm ci)
COPY package*.json ./
RUN npm install --omit=dev

# Copiar Prisma schema y generated client
COPY --from=builder /app/prisma ./prisma
COPY --from=builder /app/node_modules/.prisma ./node_modules/.prisma

# Copiar build
COPY --from=builder /app/dist ./dist

# Crear directorio de logs
RUN mkdir -p logs

# Usuario no-root
RUN addgroup -g 1001 -S nodejs && adduser -S nodejs -u 1001
RUN chown -R nodejs:nodejs /app
USER nodejs

EXPOSE 3000

# Healthcheck
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

CMD ["node", "dist/server.js"]
