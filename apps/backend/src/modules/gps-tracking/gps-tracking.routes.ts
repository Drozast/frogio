import { Router } from 'express';
import { GpsTrackingController } from './gps-tracking.controller';
import { authMiddleware, AuthRequest, roleGuard } from '../../middleware/auth.middleware';

const router = Router();
const gpsController = new GpsTrackingController();

// All routes require authentication
router.use(authMiddleware);

// POST /api/gps/batch - Insert batch of GPS points (inspectors and admins)
router.post('/batch', roleGuard('inspector', 'admin'), (req, res) =>
  gpsController.insertBatch(req as AuthRequest, res)
);

// GET /api/gps/vehicles/live - Get live positions (all authenticated users)
router.get('/vehicles/live', (req, res) =>
  gpsController.getLivePositions(req as AuthRequest, res)
);

// GET /api/gps/vehicle/:vehicleId/live - Get specific vehicle position
router.get('/vehicle/:vehicleId/live', (req, res) =>
  gpsController.getVehiclePosition(req as AuthRequest, res)
);

// GET /api/gps/log/:logId/route - Get route for a log
router.get('/log/:logId/route', (req, res) =>
  gpsController.getRouteHistory(req as AuthRequest, res)
);

// GET /api/gps/vehicle/:vehicleId/history - Get history by date range
router.get('/vehicle/:vehicleId/history', (req, res) =>
  gpsController.getVehicleHistory(req as AuthRequest, res)
);

// GET /api/gps/stats - Get statistics (admins only)
router.get('/stats', roleGuard('admin'), (req, res) =>
  gpsController.getStats(req as AuthRequest, res)
);

// DELETE /api/gps/cleanup - Cleanup old points (admins only)
router.delete('/cleanup', roleGuard('admin'), (req, res) =>
  gpsController.cleanup(req as AuthRequest, res)
);

export default router;
