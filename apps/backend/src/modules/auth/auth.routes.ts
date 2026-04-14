import { Router } from 'express';
import { AuthController } from './auth.controller.js';
import { authMiddleware, type AuthRequest } from '../../middleware/auth.middleware.js';
import prisma from '../../config/database.js';
import { logger } from '../../config/logger.js';

const router = Router();
const authController = new AuthController();

// Public routes
router.post('/register', (req, res) => authController.register(req, res));
router.post('/login', (req, res) => authController.login(req, res));
router.post('/apple', (req, res) => authController.appleSignIn(req, res));
router.post('/google', (req, res) => authController.googleSignIn(req, res));
router.post('/refresh', (req, res) => authController.refreshToken(req, res));
router.post('/logout', (req, res) => authController.logout(req, res));

// Password recovery (stricter rate limit)
router.post('/forgot-password', (req, res) => authController.forgotPassword(req, res));
router.post('/reset-password', (req, res) => authController.resetPassword(req, res));

// Protected routes
router.get('/me', authMiddleware, (req, res) => authController.me(req as AuthRequest, res));

// Profile routes (protected)
router.get('/profile', authMiddleware, (req, res) => authController.getProfile(req as AuthRequest, res));
router.patch('/profile', authMiddleware, (req, res) => authController.updateProfile(req as AuthRequest, res));

// Device token registration (for push notifications)
router.post('/device-token', authMiddleware, async (req, res) => {
  try {
    const { deviceToken, platform } = req.body;
    const userId = (req as AuthRequest).user!.userId;
    const tenantId = (req as AuthRequest).user!.tenantId;

    if (!deviceToken || !platform) {
      res.status(400).json({ error: 'deviceToken and platform required' });
      return;
    }

    await prisma.$queryRawUnsafe(
      `INSERT INTO "${tenantId}".device_tokens (user_id, device_token, platform, is_active, updated_at)
       VALUES ($1::uuid, $2, $3, true, NOW())
       ON CONFLICT (user_id, device_token) DO UPDATE SET is_active = true, updated_at = NOW()`,
      userId, deviceToken, platform
    );

    logger.info(`Device token registered: ${platform} for user ${userId}`);
    res.json({ success: true });
  } catch (e) {
    logger.error(`Device token registration error: ${e}`);
    res.status(500).json({ error: 'Error registering device token' });
  }
});

export default router;
