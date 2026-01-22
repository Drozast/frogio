import { minioClient } from '../../config/minio.js';
import prisma from '../../config/database.js';
import { env } from '../../config/env.js';
import crypto from 'crypto';

export class FilesService {
  private readonly BUCKET = env.MINIO_BUCKET;

  async uploadFile(
    file: Express.Multer.File,
    entityType: string,
    entityId: string,
    uploadedBy: string,
    tenantId: string
  ) {
    if (!minioClient) {
      throw new Error('MinIO no está configurado. El almacenamiento de archivos no está disponible.');
    }

    // Generate unique filename
    const fileExtension = file.originalname.split('.').pop();
    const uniqueFilename = `${crypto.randomUUID()}.${fileExtension}`;
    const storagePath = `${tenantId}/${entityType}/${entityId}/${uniqueFilename}`;

    // Upload to MinIO
    await minioClient.putObject(this.BUCKET, storagePath, file.buffer, file.size, {
      'Content-Type': file.mimetype,
      'X-Uploaded-By': uploadedBy,
    });

    // Save metadata to database
    const [fileRecord] = await prisma.$queryRawUnsafe<any[]>(
      `INSERT INTO "${tenantId}".files
       (entity_type, entity_id, filename, original_filename, mime_type, size_bytes, storage_path, uploaded_by, created_at)
       VALUES ($1, $2::uuid, $3, $4, $5, $6, $7, $8::uuid, NOW())
       RETURNING *`,
      entityType,
      entityId,
      uniqueFilename,
      file.originalname,
      file.mimetype,
      file.size,
      storagePath,
      uploadedBy
    );

    // Convert BigInt to Number for JSON serialization
    return {
      ...fileRecord,
      size_bytes: Number(fileRecord.size_bytes),
    };
  }

  async getFileUrl(fileId: string, tenantId: string): Promise<string> {
    if (!minioClient) {
      throw new Error('MinIO no está configurado. El almacenamiento de archivos no está disponible.');
    }

    const [file] = await prisma.$queryRawUnsafe<any[]>(
      `SELECT * FROM "${tenantId}".files WHERE id = $1::uuid LIMIT 1`,
      fileId
    );

    if (!file) {
      throw new Error('Archivo no encontrado');
    }

    // Generate presigned URL (valid for 1 hour)
    const url = await minioClient.presignedGetObject(this.BUCKET, file.storage_path, 3600);
    return url;
  }

  async getFilesByEntity(entityType: string, entityId: string, tenantId: string) {
    const files = await prisma.$queryRawUnsafe<any[]>(
      `SELECT f.*, u.first_name as uploaded_by_first_name, u.last_name as uploaded_by_last_name
       FROM "${tenantId}".files f
       LEFT JOIN "${tenantId}".users u ON f.uploaded_by = u.id
       WHERE f.entity_type = $1 AND f.entity_id = $2::uuid
       ORDER BY f.created_at DESC`,
      entityType,
      entityId
    );

    // Convert BigInt to Number for JSON serialization
    return files.map(f => ({
      ...f,
      size_bytes: Number(f.size_bytes),
    }));
  }

  async deleteFile(fileId: string, tenantId: string) {
    if (!minioClient) {
      throw new Error('MinIO no está configurado. El almacenamiento de archivos no está disponible.');
    }

    const [file] = await prisma.$queryRawUnsafe<any[]>(
      `SELECT * FROM "${tenantId}".files WHERE id = $1::uuid LIMIT 1`,
      fileId
    );

    if (!file) {
      throw new Error('Archivo no encontrado');
    }

    // Delete from MinIO
    await minioClient.removeObject(this.BUCKET, file.storage_path);

    // Delete from database
    await prisma.$queryRawUnsafe(
      `DELETE FROM "${tenantId}".files WHERE id = $1::uuid`,
      fileId
    );

    return { message: 'Archivo eliminado exitosamente' };
  }
}
