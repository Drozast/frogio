import { Router } from 'express';
import { CitationsController } from './citations.controller.js';
import { authMiddleware, roleGuard, type AuthRequest } from '../../middleware/auth.middleware.js';

const router = Router();
const citationsController = new CitationsController();

// All routes require authentication
router.use(authMiddleware);

// Get upcoming citations
router.get('/upcoming', (req, res) => citationsController.getUpcoming(req as AuthRequest, res));

// Get statistics
router.get('/stats', roleGuard('inspector', 'admin'), (req, res) => citationsController.getStats(req as AuthRequest, res));

// Bulk import from Excel
router.post('/import', roleGuard('admin'), (req, res) => citationsController.bulkImport(req as AuthRequest, res));

// Only Inspectors and Admins can create citations
router.post('/', roleGuard('inspector', 'admin'), (req, res) => citationsController.create(req as AuthRequest, res));

// All authenticated users can list and view citations (filtered by role in controller)
router.get('/', (req, res) => citationsController.findAll(req as AuthRequest, res));
router.get('/:id', (req, res) => citationsController.findById(req as AuthRequest, res));

// Only Inspectors and Admins can update/delete citations
router.patch('/:id', roleGuard('inspector', 'admin'), (req, res) => citationsController.update(req as AuthRequest, res));
router.delete('/:id', roleGuard('admin'), (req, res) => citationsController.delete(req as AuthRequest, res));

export default router;
