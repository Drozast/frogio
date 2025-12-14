import { Router } from 'express';
import { AuthController } from './auth.controller.js';
import { authMiddleware, type AuthRequest } from '../../middleware/auth.middleware.js';

const router = Router();
const authController = new AuthController();

// Public routes
router.post('/register', (req, res) => authController.register(req, res));
router.post('/login', (req, res) => authController.login(req, res));
router.post('/refresh', (req, res) => authController.refreshToken(req, res));
router.post('/logout', (req, res) => authController.logout(req, res));

// Protected routes
router.get('/me', authMiddleware, (req, res) => authController.me(req as AuthRequest, res));

export default router;
