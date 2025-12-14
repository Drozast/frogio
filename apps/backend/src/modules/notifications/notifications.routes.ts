import { Router } from 'express';
import { NotificationsController } from './notifications.controller.js';
import { authMiddleware, type AuthRequest } from '../../middleware/auth.middleware.js';

const router = Router();
const notificationsController = new NotificationsController();

// All routes require authentication
router.use(authMiddleware);

// Get my notifications
router.get('/', (req, res) => notificationsController.getMyNotifications(req as AuthRequest, res));

// Get unread count
router.get('/unread/count', (req, res) => notificationsController.getUnreadCount(req as AuthRequest, res));

// Mark as read
router.patch('/:id/read', (req, res) => notificationsController.markAsRead(req as AuthRequest, res));

// Mark all as read
router.patch('/read-all', (req, res) => notificationsController.markAllAsRead(req as AuthRequest, res));

// Delete notification
router.delete('/:id', (req, res) => notificationsController.deleteNotification(req as AuthRequest, res));

// Send test notification (for testing)
router.post('/test', (req, res) => notificationsController.sendTestNotification(req as AuthRequest, res));

export default router;
