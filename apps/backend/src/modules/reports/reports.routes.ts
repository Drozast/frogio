import { Router } from 'express';
import { ReportsController } from './reports.controller.js';
import { authMiddleware, roleGuard, type AuthRequest } from '../../middleware/auth.middleware.js';

const router = Router();
const reportsController = new ReportsController();

// All routes require authentication
router.use(authMiddleware);

// Citizens, Inspectors, Admins can create reports
router.post('/', (req, res) => reportsController.create(req as AuthRequest, res));

// All authenticated users can list and view reports (filtered by role in controller)
router.get('/', (req, res) => reportsController.findAll(req as AuthRequest, res));
router.get('/:id', (req, res) => reportsController.findById(req as AuthRequest, res));

// Version history - Inspectors and Admins can view
router.get('/:id/versions', roleGuard('inspector', 'admin'), (req, res) => reportsController.getVersionHistory(req as AuthRequest, res));
router.get('/:id/versions/:versionNumber', roleGuard('inspector', 'admin'), (req, res) => reportsController.getVersion(req as AuthRequest, res));

// Only Inspectors and Admins can update/delete reports
router.patch('/:id', roleGuard('inspector', 'admin'), (req, res) => reportsController.update(req as AuthRequest, res));
router.delete('/:id', roleGuard('admin'), (req, res) => reportsController.delete(req as AuthRequest, res));

export default router;
