import { Router } from 'express';
import multer from 'multer';
import { FilesController } from './files.controller.js';
import { authMiddleware, roleGuard, type AuthRequest } from '../../middleware/auth.middleware.js';

const router = Router();
const filesController = new FilesController();

// Ruta pública para servir archivos (sin autenticación, con caché)
// Esta ruta DEBE ir ANTES del middleware de autenticación
router.get('/serve/:tenantId/:fileId', (req, res) => filesController.serveFile(req, res));

// Configure multer for memory storage
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB max file size
  },
  fileFilter: (_req, file, cb) => {
    // Allowed file types
    const allowedMimes = [
      'image/jpeg',
      'image/jpg',
      'image/png',
      'image/gif',
      'image/webp',
      'application/pdf',
      'application/msword',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'application/vnd.ms-excel',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    ];

    if (allowedMimes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Tipo de archivo no permitido'));
    }
  },
});

// All routes require authentication
router.use(authMiddleware);

// Upload file
router.post('/upload', upload.single('file'), (req, res) => filesController.upload(req as AuthRequest, res));

// Get file URL (presigned)
router.get('/:id/url', (req, res) => filesController.getFileUrl(req as AuthRequest, res));

// Get files by entity
router.get('/:entityType/:entityId', (req, res) => filesController.getByEntity(req as AuthRequest, res));

// Delete file (admins only)
router.delete('/:id', roleGuard('admin'), (req, res) => filesController.delete(req as AuthRequest, res));

export default router;
