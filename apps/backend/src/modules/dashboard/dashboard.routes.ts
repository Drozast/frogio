import { Router } from 'express';
import { DashboardController } from './dashboard.controller.js';
import { authMiddleware, roleGuard, type AuthRequest } from '../../middleware/auth.middleware.js';

const router = Router();
const dashboardController = new DashboardController();

// All routes require authentication (inspectors and admins only)
router.use(authMiddleware);

// Get dashboard statistics
router.get('/stats', roleGuard('inspector', 'admin'), (req, res) =>
  dashboardController.getStats(req as AuthRequest, res)
);

export default router;
