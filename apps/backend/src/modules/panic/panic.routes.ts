import { Router } from 'express';
import { PanicController } from './panic.controller.js';
import { authMiddleware, roleGuard, type AuthRequest } from '../../middleware/auth.middleware.js';

const router = Router();
const panicController = new PanicController();

// All routes require authentication
router.use(authMiddleware);

// Any authenticated user can create a panic alert
router.post('/', (req, res) => panicController.create(req as AuthRequest, res));

// User can cancel their own alert
router.patch('/:id/cancel', (req, res) => panicController.cancel(req as AuthRequest, res));

// Inspectors and admins can view and respond to alerts
router.get('/active', roleGuard('inspector', 'admin'), (req, res) => panicController.findActive(req as AuthRequest, res));
router.get('/stats', roleGuard('inspector', 'admin'), (req, res) => panicController.getStats(req as AuthRequest, res));
router.get('/', roleGuard('inspector', 'admin'), (req, res) => panicController.findAll(req as AuthRequest, res));
router.get('/:id', roleGuard('inspector', 'admin'), (req, res) => panicController.findById(req as AuthRequest, res));
router.patch('/:id/respond', roleGuard('inspector', 'admin'), (req, res) => panicController.respond(req as AuthRequest, res));
router.patch('/:id/resolve', roleGuard('inspector', 'admin'), (req, res) => panicController.resolve(req as AuthRequest, res));

export default router;
