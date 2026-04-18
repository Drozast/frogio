import { Router } from 'express';
import { AdminImportsController } from './admin-imports.controller.js';
import { authMiddleware, roleGuard, type AuthRequest } from '../../middleware/auth.middleware.js';

const router = Router();
const controller = new AdminImportsController();

// All import endpoints require authentication + admin role.
router.use(authMiddleware);
router.use(roleGuard('admin'));

router.post('/citations', (req, res) =>
  controller.importCitations(req as AuthRequest, res)
);
router.post('/reports', (req, res) =>
  controller.importReports(req as AuthRequest, res)
);
router.post('/vehicles', (req, res) =>
  controller.importVehicles(req as AuthRequest, res)
);
router.post('/users', (req, res) =>
  controller.importUsers(req as AuthRequest, res)
);

export default router;
