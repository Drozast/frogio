import { Router } from 'express';
import { UsersController } from './users.controller.js';
import { authMiddleware, roleGuard, type AuthRequest } from '../../middleware/auth.middleware.js';

const router = Router();
const usersController = new UsersController();

// All routes require authentication and admin role
router.use(authMiddleware);
router.use(roleGuard('admin'));

// Stats endpoint
router.get('/stats', (req, res) => usersController.getStats(req as AuthRequest, res));

// CRUD operations
router.get('/', (req, res) => usersController.findAll(req as AuthRequest, res));
router.post('/', (req, res) => usersController.create(req as AuthRequest, res));
router.get('/:id', (req, res) => usersController.findById(req as AuthRequest, res));
router.patch('/:id', (req, res) => usersController.update(req as AuthRequest, res));
router.delete('/:id', (req, res) => usersController.delete(req as AuthRequest, res));

// Special operations
router.patch('/:id/toggle-status', (req, res) => usersController.toggleStatus(req as AuthRequest, res));
router.patch('/:id/password', (req, res) => usersController.updatePassword(req as AuthRequest, res));

export default router;
