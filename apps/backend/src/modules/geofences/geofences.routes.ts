import { Router } from 'express';
import { GeofencesController } from './geofences.controller';
import { authMiddleware, AuthRequest, roleGuard } from '../../middleware/auth.middleware';

const router = Router();
const geofencesController = new GeofencesController();

// All routes require authentication
router.use(authMiddleware);

// POST /api/geofences - Create geofence (admin only)
router.post('/', roleGuard('admin'), (req, res) =>
  geofencesController.create(req as AuthRequest, res)
);

// GET /api/geofences - List all geofences
router.get('/', (req, res) =>
  geofencesController.findAll(req as AuthRequest, res)
);

// GET /api/geofences/events/recent - Get recent events (must be before :id)
router.get('/events/recent', (req, res) =>
  geofencesController.getRecentEvents(req as AuthRequest, res)
);

// POST /api/geofences/check - Check if point is in geofences
router.post('/check', (req, res) =>
  geofencesController.checkPoint(req as AuthRequest, res)
);

// GET /api/geofences/:id - Get geofence by ID
router.get('/:id', (req, res) =>
  geofencesController.findById(req as AuthRequest, res)
);

// GET /api/geofences/:id/events - Get events for a geofence
router.get('/:id/events', (req, res) =>
  geofencesController.getGeofenceEvents(req as AuthRequest, res)
);

// PATCH /api/geofences/:id - Update geofence (admin only)
router.patch('/:id', roleGuard('admin'), (req, res) =>
  geofencesController.update(req as AuthRequest, res)
);

// DELETE /api/geofences/:id - Delete geofence (admin only)
router.delete('/:id', roleGuard('admin'), (req, res) =>
  geofencesController.delete(req as AuthRequest, res)
);

export default router;
