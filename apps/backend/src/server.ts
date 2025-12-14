import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import compression from 'compression';
import { Server } from 'socket.io';
import { createServer } from 'http';
import { env } from './config/env.js';
import { logger } from './config/logger.js';
import { initializeMinio } from './config/minio.js';
import prisma from './config/database.js';
import redis from './config/redis.js';

const app = express();
const httpServer = createServer(app);
const io = new Server(httpServer, {
  cors: {
    origin: env.CORS_ORIGINS,
    credentials: true,
  },
});

// Middleware de seguridad
app.use(helmet());
app.use(compression());
app.use(cors({
  origin: env.CORS_ORIGINS,
  credentials: true,
}));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Request logging
app.use((req, res, next) => {
  logger.http(`${req.method} ${req.url}`);
  next();
});

// Health check
app.get('/health', async (req, res) => {
  try {
    await prisma.$queryRaw`SELECT 1`;
    await redis.ping();

    res.json({
      status: 'ok',
      timestamp: new Date().toISOString(),
      services: {
        database: 'connected',
        redis: 'connected',
      },
    });
  } catch (error) {
    res.status(503).json({
      status: 'error',
      timestamp: new Date().toISOString(),
      error: error instanceof Error ? error.message : 'Unknown error',
    });
  }
});

// API Routes (placeholder - implementaremos después)
app.get('/api', (req, res) => {
  res.json({
    name: 'FROGIO API',
    version: '1.0.0',
    description: 'Sistema de Gestión de Seguridad Pública Municipal',
  });
});

// Socket.io (notificaciones en tiempo real)
io.on('connection', (socket) => {
  logger.info(`Client connected: ${socket.id}`);

  socket.on('disconnect', () => {
    logger.info(`Client disconnected: ${socket.id}`);
  });
});

// Export io para uso en otros módulos
export { io };

// Error handling
app.use((err: Error, req: express.Request, res: express.Response, next: express.NextFunction) => {
  logger.error(err.stack || err.message);

  res.status(500).json({
    error: env.isDevelopment ? err.message : 'Internal server error',
    ...(env.isDevelopment && { stack: err.stack }),
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    error: 'Not found',
    path: req.url,
  });
});

// Inicializar servicios y servidor
async function bootstrap() {
  try {
    // Verificar conexión a PostgreSQL
    await prisma.$connect();
    logger.info('✅ PostgreSQL connected');

    // Verificar conexión a Redis
    await redis.ping();
    logger.info('✅ Redis connected');

    // Inicializar MinIO
    await initializeMinio();

    // Iniciar servidor
    httpServer.listen(env.PORT, () => {
      logger.info(`🚀 Server running on port ${env.PORT}`);
      logger.info(`📝 Environment: ${env.NODE_ENV}`);
      logger.info(`🌐 API URL: ${env.API_URL}`);
    });
  } catch (error) {
    logger.error('Failed to start server:', error);
    process.exit(1);
  }
}

// Graceful shutdown
process.on('SIGTERM', async () => {
  logger.info('SIGTERM received, shutting down gracefully...');
  httpServer.close(async () => {
    await prisma.$disconnect();
    await redis.quit();
    logger.info('Server closed');
    process.exit(0);
  });
});

bootstrap();
