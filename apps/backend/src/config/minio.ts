import { Client } from 'minio';
import { env } from './env.js';

// MinIO is optional - only initialize if credentials are provided
export const minioClient = env.MINIO_ENDPOINT && env.MINIO_ACCESS_KEY && env.MINIO_SECRET_KEY
  ? new Client({
      endPoint: env.MINIO_ENDPOINT,
      port: env.MINIO_PORT,
      useSSL: env.MINIO_USE_SSL,
      accessKey: env.MINIO_ACCESS_KEY,
      secretKey: env.MINIO_SECRET_KEY,
    })
  : null;

// Inicializar bucket si no existe
export async function initializeMinio() {
  if (!minioClient) {
    console.log('ℹ️  MinIO not configured (optional)');
    return;
  }

  try {
    const bucketExists = await minioClient.bucketExists(env.MINIO_BUCKET);

    if (!bucketExists) {
      await minioClient.makeBucket(env.MINIO_BUCKET, 'us-east-1');
      console.log(`✅ MinIO bucket '${env.MINIO_BUCKET}' created`);

      // Configurar política pública para lectura (opcional)
      const policy = {
        Version: '2012-10-17',
        Statement: [
          {
            Effect: 'Allow',
            Principal: { AWS: ['*'] },
            Action: ['s3:GetObject'],
            Resource: [`arn:aws:s3:::${env.MINIO_BUCKET}/*`],
          },
        ],
      };

      await minioClient.setBucketPolicy(
        env.MINIO_BUCKET,
        JSON.stringify(policy)
      );
    } else {
      console.log(`✅ MinIO bucket '${env.MINIO_BUCKET}' already exists`);
    }
  } catch (error) {
    console.error('❌ MinIO initialization error:', error);
    throw error;
  }
}

export default minioClient;
