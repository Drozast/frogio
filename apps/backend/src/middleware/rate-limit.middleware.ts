import rateLimit from 'express-rate-limit';
import { RedisStore } from 'rate-limit-redis';
import Redis from 'ioredis';

// Redis client compartido para rate limiting
const redisClient = new Redis(process.env.REDIS_URL || 'redis://localhost:6379');

const makeRedisStore = (prefix: string) =>
  new RedisStore({
    // @ts-expect-error - sendCommand signature differs across versions
    sendCommand: (...args: string[]) => redisClient.call(...args),
    prefix: `rl:${prefix}:`,
  });

// Auth rate limit: protección anti-brute force para login/register
// 20 intentos por IP cada 15 minutos es suficiente para uso legítimo
export const authRateLimit = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 20,
  message: { error: 'Demasiados intentos. Intente nuevamente en 15 minutos.', code: 'RATE_LIMIT_EXCEEDED' },
  standardHeaders: true,
  legacyHeaders: false,
  store: makeRedisStore('auth'),
  keyGenerator: (req) => {
    const forwarded = req.headers['x-forwarded-for'];
    return (Array.isArray(forwarded) ? forwarded[0] : forwarded) || req.ip || 'unknown';
  },
});

// Password reset: límite estricto para evitar spam de emails
export const passwordResetRateLimit = rateLimit({
  windowMs: 60 * 60 * 1000,
  max: 5,
  message: { error: 'Demasiados intentos de recuperación. Intente nuevamente en 1 hora.', code: 'RATE_LIMIT_EXCEEDED' },
  standardHeaders: true,
  legacyHeaders: false,
  store: makeRedisStore('pwd_reset'),
});

// File upload rate limit: 100 subidas por IP cada 15 minutos
export const uploadRateLimit = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  message: { error: 'Demasiadas subidas de archivos. Intente nuevamente más tarde.', code: 'RATE_LIMIT_EXCEEDED' },
  standardHeaders: true,
  legacyHeaders: false,
  store: makeRedisStore('upload'),
});
