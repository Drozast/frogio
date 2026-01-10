import { Router } from 'express';
import { TripLogsController } from './trip-logs.controller.js';
import { authMiddleware, roleGuard, type AuthRequest } from '../../middleware/auth.middleware.js';

const router = Router();
const tripLogsController = new TripLogsController();

// All routes require authentication and inspector/admin role
router.use(authMiddleware);
router.use(roleGuard('inspector', 'admin'));

// Get my active trip
router.get('/my/active', (req, res) => tripLogsController.findMyActive(req as AuthRequest, res));

// Get my trips
router.get('/my', (req, res) => tripLogsController.findMyTrips(req as AuthRequest, res));

// Get stats
router.get('/stats', (req, res) => tripLogsController.getStats(req as AuthRequest, res));

// Start new trip
router.post('/', (req, res) => tripLogsController.create(req as AuthRequest, res));

// Get all trips (admin only sees all, inspector sees own)
router.get('/', (req, res) => tripLogsController.findAll(req as AuthRequest, res));

// Get specific trip
router.get('/:id', (req, res) => tripLogsController.findById(req as AuthRequest, res));

// End trip
router.patch('/:id/end', (req, res) => tripLogsController.endTrip(req as AuthRequest, res));

// Cancel trip
router.patch('/:id/cancel', (req, res) => tripLogsController.cancelTrip(req as AuthRequest, res));

// Add entry to trip
router.post('/:id/entries', (req, res) => tripLogsController.addEntry(req as AuthRequest, res));

export default router;
