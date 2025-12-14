import { config } from 'dotenv';
import { z } from 'zod';

config();

const envSchema = z.object({
  // Server
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
  PORT: z.string().default('3000'),
  API_URL: z.string().url(),

  // Database
  DATABASE_URL: z.string().url(),

  // Redis
  REDIS_URL: z.string().url(),

  // JWT
  JWT_SECRET: z.string().min(32),
  JWT_REFRESH_SECRET: z.string().min(32),
  JWT_EXPIRES_IN: z.string().default('15m'),
  JWT_REFRESH_EXPIRES_IN: z.string().default('7d'),

  // OAuth Google
  GOOGLE_CLIENT_ID: z.string().optional(),
  GOOGLE_CLIENT_SECRET: z.string().optional(),
  GOOGLE_CALLBACK_URL: z.string().url().optional(),

  // OAuth Facebook
  FACEBOOK_APP_ID: z.string().optional(),
  FACEBOOK_APP_SECRET: z.string().optional(),
  FACEBOOK_CALLBACK_URL: z.string().url().optional(),

  // MinIO
  MINIO_ENDPOINT: z.string(),
  MINIO_PORT: z.string().default('9000'),
  MINIO_USE_SSL: z.string().default('false'),
  MINIO_ACCESS_KEY: z.string(),
  MINIO_SECRET_KEY: z.string(),
  MINIO_BUCKET: z.string().default('frogio-files'),

  // ntfy
  NTFY_URL: z.string().url(),

  // SMTP
  SMTP_HOST: z.string(),
  SMTP_PORT: z.string().default('587'),
  SMTP_SECURE: z.string().default('false'),
  SMTP_USER: z.string(),
  SMTP_PASSWORD: z.string(),
  SMTP_FROM: z.string(),

  // CORS
  CORS_ORIGIN: z.string(),

  // Rate Limiting
  RATE_LIMIT_WINDOW_MS: z.string().default('900000'),
  RATE_LIMIT_MAX_REQUESTS: z.string().default('100'),
});

const parsed = envSchema.safeParse(process.env);

if (!parsed.success) {
  console.error('❌ Invalid environment variables:', parsed.error.flatten().fieldErrors);
  throw new Error('Invalid environment variables');
}

export const env = {
  ...parsed.data,
  PORT: parseInt(parsed.data.PORT),
  MINIO_PORT: parseInt(parsed.data.MINIO_PORT),
  MINIO_USE_SSL: parsed.data.MINIO_USE_SSL === 'true',
  SMTP_PORT: parseInt(parsed.data.SMTP_PORT),
  SMTP_SECURE: parsed.data.SMTP_SECURE === 'true',
  RATE_LIMIT_WINDOW_MS: parseInt(parsed.data.RATE_LIMIT_WINDOW_MS),
  RATE_LIMIT_MAX_REQUESTS: parseInt(parsed.data.RATE_LIMIT_MAX_REQUESTS),
  CORS_ORIGINS: parsed.data.CORS_ORIGIN.split(','),
  isDevelopment: parsed.data.NODE_ENV === 'development',
  isProduction: parsed.data.NODE_ENV === 'production',
  isTest: parsed.data.NODE_ENV === 'test',
};

export type Env = typeof env;
