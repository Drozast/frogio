import { Router } from 'express';
import { AuthController } from './auth.controller.js';
import { authMiddleware, type AuthRequest } from '../../middleware/auth.middleware.js';
import { authRateLimit, passwordResetRateLimit } from '../../middleware/rate-limit.middleware.js';

const router = Router();
const authController = new AuthController();

// Public routes (rate limited)
router.post('/register', authRateLimit, (req, res) => authController.register(req, res));
router.post('/login', authRateLimit, (req, res) => authController.login(req, res));
router.post('/refresh', (req, res) => authController.refreshToken(req, res));
router.post('/logout', (req, res) => authController.logout(req, res));

// Password recovery (stricter rate limit)
router.post('/forgot-password', passwordResetRateLimit, (req, res) => authController.forgotPassword(req, res));
router.post('/reset-password', passwordResetRateLimit, (req, res) => authController.resetPassword(req, res));

// Protected routes
router.get('/me', authMiddleware, (req, res) => authController.me(req as AuthRequest, res));

// Profile routes (protected)
router.get('/profile', authMiddleware, (req, res) => authController.getProfile(req as AuthRequest, res));
router.patch('/profile', authMiddleware, (req, res) => authController.updateProfile(req as AuthRequest, res));

export default router;
