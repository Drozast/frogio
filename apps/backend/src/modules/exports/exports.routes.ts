import { Router } from 'express';
import { ExportsController } from './exports.controller.js';
import { authMiddleware, roleGuard, type AuthRequest } from '../../middleware/auth.middleware.js';

const router = Router();
const exportsController = new ExportsController();

// All routes require authentication and admin role
router.use(authMiddleware);
router.use(roleGuard('admin'));

// Export endpoints
router.get('/reports', (req, res) => exportsController.exportReports(req as AuthRequest, res));
router.get('/infractions', (req, res) => exportsController.exportInfractions(req as AuthRequest, res));
router.get('/users', (req, res) => exportsController.exportUsers(req as AuthRequest, res));
router.get('/vehicles', (req, res) => exportsController.exportVehicles(req as AuthRequest, res));

// Statistics report
router.get('/statistics', (req, res) => exportsController.getStatisticsReport(req as AuthRequest, res));

export default router;
