import * as Minio from 'minio';
import { config } from './index.js';

export const minioClient = new Minio.Client({
  endPoint: config.minio.endpoint,
  port: config.minio.port,
  useSSL: config.minio.useSSL,
  accessKey: config.minio.accessKey,
  secretKey: config.minio.secretKey,
});

export async function initializeMinio(): Promise<void> {
  const bucketName = config.minio.bucketName;

  try {
    const exists = await minioClient.bucketExists(bucketName);

    if (!exists) {
      await minioClient.makeBucket(bucketName, 'us-east-1');
      console.log(`✅ Bucket "${bucketName}" creado exitosamente`);

      // Configurar política pública para lectura
      const policy = {
        Version: '2012-10-17',
        Statement: [
          {
            Effect: 'Allow',
            Principal: { AWS: ['*'] },
            Action: ['s3:GetObject'],
            Resource: [`arn:aws:s3:::${bucketName}/*`],
          },
        ],
      };

      await minioClient.setBucketPolicy(bucketName, JSON.stringify(policy));
      console.log(`✅ Política de bucket configurada`);
    } else {
      console.log(`✅ Bucket "${bucketName}" ya existe`);
    }
  } catch (error) {
    console.error('❌ Error al inicializar MinIO:', error);
  }
}
