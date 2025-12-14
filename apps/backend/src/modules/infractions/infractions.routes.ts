import { Router } from 'express';
import { InfractionsController } from './infractions.controller.js';
import { authMiddleware, roleGuard, type AuthRequest } from '../../middleware/auth.middleware.js';

const router = Router();
const infractionsController = new InfractionsController();

// All routes require authentication
router.use(authMiddleware);

// Get statistics
router.get('/stats', (req, res) => infractionsController.getStats(req as AuthRequest, res));

// Only Inspectors and Admins can create infractions
router.post('/', roleGuard('inspector', 'admin'), (req, res) => infractionsController.create(req as AuthRequest, res));

// All authenticated users can list and view infractions (filtered by role in controller)
router.get('/', (req, res) => infractionsController.findAll(req as AuthRequest, res));
router.get('/:id', (req, res) => infractionsController.findById(req as AuthRequest, res));

// Only Inspectors and Admins can update/delete infractions
router.patch('/:id', roleGuard('inspector', 'admin'), (req, res) => infractionsController.update(req as AuthRequest, res));
router.delete('/:id', roleGuard('admin'), (req, res) => infractionsController.delete(req as AuthRequest, res));

export default router;
