import { Router } from 'express';
import { MedicalRecordsController } from './medical-records.controller.js';
import { authMiddleware, roleGuard, type AuthRequest } from '../../middleware/auth.middleware.js';

const router = Router();
const medicalRecordsController = new MedicalRecordsController();

// All routes require authentication
router.use(authMiddleware);

// Get my own medical record
router.get('/me', (req, res) => medicalRecordsController.findMyRecord(req as AuthRequest, res));

// Citizens and health workers can create medical records
router.post('/', (req, res) => medicalRecordsController.create(req as AuthRequest, res));

// All authenticated users can list and view medical records (filtered by role in controller)
router.get('/', (req, res) => medicalRecordsController.findAll(req as AuthRequest, res));
router.get('/:id', (req, res) => medicalRecordsController.findById(req as AuthRequest, res));

// Citizens can update their own, inspectors/admins can update any
router.patch('/:id', (req, res) => medicalRecordsController.update(req as AuthRequest, res));

// Only Admins can delete medical records
router.delete('/:id', roleGuard('admin'), (req, res) => medicalRecordsController.delete(req as AuthRequest, res));

export default router;
