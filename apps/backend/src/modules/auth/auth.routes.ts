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

// Password recovery (public)
router.post('/forgot-password', (req, res) => authController.forgotPassword(req, res));
router.post('/reset-password', (req, res) => authController.resetPassword(req, res));

// Protected routes
router.get('/me', authMiddleware, (req, res) => authController.me(req as AuthRequest, res));

// Profile routes (protected)
router.get('/profile', authMiddleware, (req, res) => authController.getProfile(req as AuthRequest, res));
router.patch('/profile', authMiddleware, (req, res) => authController.updateProfile(req as AuthRequest, res));

export default router;
