import rateLimit from 'express-rate-limit';
import { RedisStore } from 'rate-limit-redis';
import Redis from 'ioredis';
import { env } from '../config/env.js';

// Redis client compartido para rate limiting
const redisClient = new Redis(process.env.REDIS_URL || 'redis://localhost:6379');

const makeRedisStore = (prefix: string) =>
  new RedisStore({
    // @ts-expect-error - sendCommand signature differs across versions
    sendCommand: (...args: string[]) => redisClient.call(...args),
    prefix: `rl:${prefix}:`,
  });

// Strict rate limit for auth endpoints (login, register, forgot-password)
export const authRateLimit = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 10,
  message: { error: 'Demasiados intentos. Intente nuevamente en 15 minutos.', code: 'RATE_LIMIT_EXCEEDED' },
  standardHeaders: true,
  legacyHeaders: false,
  store: makeRedisStore('auth'),
  keyGenerator: (req) => {
    const forwarded = req.headers['x-forwarded-for'];
    return (Array.isArray(forwarded) ? forwarded[0] : forwarded) || req.ip || 'unknown';
  },
});

// Moderate rate limit for password reset
export const passwordResetRateLimit = rateLimit({
  windowMs: 60 * 60 * 1000,
  max: 3,
  message: { error: 'Demasiados intentos de recuperación. Intente nuevamente en 1 hora.', code: 'RATE_LIMIT_EXCEEDED' },
  standardHeaders: true,
  legacyHeaders: false,
  store: makeRedisStore('pwd_reset'),
});

// General API rate limit
export const apiRateLimit = rateLimit({
  windowMs: env.RATE_LIMIT_WINDOW_MS,
  max: env.RATE_LIMIT_MAX_REQUESTS,
  message: { error: 'Demasiadas solicitudes. Intente nuevamente más tarde.', code: 'RATE_LIMIT_EXCEEDED' },
  standardHeaders: true,
  legacyHeaders: false,
  store: makeRedisStore('api'),
});

// File upload rate limit
export const uploadRateLimit = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 30,
  message: { error: 'Demasiadas subidas de archivos. Intente nuevamente más tarde.', code: 'RATE_LIMIT_EXCEEDED' },
  standardHeaders: true,
  legacyHeaders: false,
  store: makeRedisStore('upload'),
});
