import Redis from 'ioredis';
import { env } from './env.js';

// Redis is optional - only initialize if URL is provided
export const redis = env.REDIS_URL ? new Redis(env.REDIS_URL, {
  maxRetriesPerRequest: 3,
  retryStrategy(times) {
    const delay = Math.min(times * 50, 2000);
    return delay;
  },
}) : null;

if (redis) {
  redis.on('connect', () => {
    console.log('✅ Redis connected');
  });

  redis.on('error', (err) => {
    console.error('❌ Redis error:', err);
  });
} else {
  console.log('ℹ️  Redis not configured (optional)');
}

export default redis;
