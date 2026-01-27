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
import authRoutes from './modules/auth/auth.routes.js';
import usersRoutes from './modules/users/users.routes.js';
import reportsRoutes from './modules/reports/reports.routes.js';
import infractionsRoutes from './modules/infractions/infractions.routes.js';
import citationsRoutes from './modules/citations/citations.routes.js';
import medicalRecordsRoutes from './modules/medical-records/medical-records.routes.js';
import vehiclesRoutes from './modules/vehicles/vehicles.routes.js';
import filesRoutes from './modules/files/files.routes.js';
import notificationsRoutes from './modules/notifications/notifications.routes.js';
import dashboardRoutes from './modules/dashboard/dashboard.routes.js';
import panicRoutes from './modules/panic/panic.routes.js';
import tripLogsRoutes from './modules/trip-logs/trip-logs.routes.js';
import exportsRoutes from './modules/exports/exports.routes.js';
import gpsTrackingRoutes from './modules/gps-tracking/gps-tracking.routes.js';
import geofencesRoutes from './modules/geofences/geofences.routes.js';

const app = express();
const httpServer = createServer(app);

// Socket.IO with CORS
const socketCorsOrigin = process.env.CORS_ORIGIN === '*'
  ? '*'
  : process.env.CORS_ORIGIN?.split(',') || ['http://localhost:3000'];

const io = new Server(httpServer, {
  cors: {
    origin: socketCorsOrigin,
    credentials: true,
  },
});

// Middleware de seguridad
app.use(helmet());
app.use(compression());

// CORS configuration - Allow all origins if "*" is set, otherwise use specific origins
const corsOrigin = env.CORS_ORIGINS[0] === '*'
  ? true // Allow all origins
  : env.CORS_ORIGINS;

app.use(cors({
  origin: corsOrigin,
  credentials: true,
}));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Request logging
app.use((_req, _res, next) => {
  logger.http(`${_req.method} ${_req.url}`);
  next();
});

// Health check
app.get('/health', async (_req, res) => {
  try {
    // Check database (required)
    await prisma.$queryRaw`SELECT 1`;

    const services: Record<string, string> = {
      database: 'connected',
    };

    // Check redis (optional)
    if (redis) {
      try {
        await redis.ping();
        services.redis = 'connected';
      } catch (redisError) {
        services.redis = 'unavailable';
      }
    } else {
      services.redis = 'not configured';
    }

    res.json({
      status: 'ok',
      timestamp: new Date().toISOString(),
      services,
    });
  } catch (error) {
    res.status(503).json({
      status: 'error',
      timestamp: new Date().toISOString(),
      error: error instanceof Error ? error.message : 'Unknown error',
    });
  }
});

// API Routes
app.get('/api', (_req, res) => {
  res.json({
    name: 'FROGIO API',
    version: '1.0.0',
    description: 'Sistema de Gestión de Seguridad Pública Municipal',
  });
});

app.use('/api/auth', authRoutes);
app.use('/api/users', usersRoutes);
app.use('/api/reports', reportsRoutes);
app.use('/api/infractions', infractionsRoutes);
app.use('/api/citations', citationsRoutes);
app.use('/api/medical-records', medicalRecordsRoutes);
app.use('/api/vehicles', vehiclesRoutes);
app.use('/api/files', filesRoutes);
app.use('/api/notifications', notificationsRoutes);
app.use('/api/dashboard', dashboardRoutes);
app.use('/api/panic', panicRoutes);
app.use('/api/trip-logs', tripLogsRoutes);
app.use('/api/exports', exportsRoutes);
app.use('/api/gps', gpsTrackingRoutes);
app.use('/api/geofences', geofencesRoutes);

// Socket.io (notificaciones en tiempo real)
io.on('connection', (socket) => {
  logger.info(`Client connected: ${socket.id}`);

  socket.on('disconnect', () => {
    logger.info(`Client disconnected: ${socket.id}`);
  });
});

// Socket.IO Fleet namespace for real-time GPS tracking
const fleetNamespace = io.of('/fleet');

fleetNamespace.on('connection', (socket) => {
  logger.info(`🚗 Fleet client connected: ${socket.id}`);

  // Join tenant room
  socket.on('join:tenant', (tenantId: string) => {
    socket.join(`tenant:${tenantId}`);
    logger.info(`Fleet client ${socket.id} joined tenant: ${tenantId}`);
  });

  // Leave tenant room
  socket.on('leave:tenant', (tenantId: string) => {
    socket.leave(`tenant:${tenantId}`);
    logger.info(`Fleet client ${socket.id} left tenant: ${tenantId}`);
  });

  // Join specific vehicle room (for inspectors)
  socket.on('join:vehicle', (vehicleId: string) => {
    socket.join(`vehicle:${vehicleId}`);
    logger.info(`Fleet client ${socket.id} tracking vehicle: ${vehicleId}`);
  });

  // Leave vehicle room
  socket.on('leave:vehicle', (vehicleId: string) => {
    socket.leave(`vehicle:${vehicleId}`);
  });

  socket.on('disconnect', () => {
    logger.info(`🚗 Fleet client disconnected: ${socket.id}`);
  });
});

// Store io in app for use in controllers
app.set('io', io);

// Export io para uso en otros módulos
export { io };

// Error handling
app.use((err: Error, _req: express.Request, res: express.Response, _next: express.NextFunction) => {
  logger.error(err.stack || err.message);

  res.status(500).json({
    error: env.isDevelopment ? err.message : 'Internal server error',
    ...(env.isDevelopment && { stack: err.stack }),
  });
});

// 404 handler
app.use((_req: express.Request, res: express.Response) => {
  res.status(404).json({
    error: 'Not found',
    path: _req.url,
  });
});

// Inicializar servicios y servidor
async function bootstrap() {
  try {
    // Verificar conexión a PostgreSQL
    await prisma.$connect();
    logger.info('✅ PostgreSQL connected');

    // Auto-fix database constraints if needed
    try {
      await prisma.$executeRawUnsafe(`
        ALTER TABLE santa_juana.panic_alerts
          DROP CONSTRAINT IF EXISTS panic_alerts_status_check;
        ALTER TABLE santa_juana.panic_alerts
          ADD CONSTRAINT panic_alerts_status_check
          CHECK (status IN ('active', 'responding', 'resolved', 'cancelled', 'dismissed'));
      `);
      logger.info('✅ Database constraints verified');
    } catch (e) {
      logger.warn('Could not verify database constraints (table may not exist yet)');
    }

    // Verificar conexión a Redis (optional)
    if (redis) {
      await redis.ping();
      logger.info('✅ Redis connected');
    } else {
      logger.info('ℹ️  Redis not configured (optional)');
    }

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
    if (redis) {
      await redis.quit();
    }
    logger.info('Server closed');
    process.exit(0);
  });
});

bootstrap();
