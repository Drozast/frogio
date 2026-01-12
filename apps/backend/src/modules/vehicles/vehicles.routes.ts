import { Router } from 'express';
import { VehiclesController } from './vehicles.controller.js';
import { authMiddleware, roleGuard, type AuthRequest } from '../../middleware/auth.middleware.js';

const router = Router();
const vehiclesController = new VehiclesController();

// All routes require authentication
router.use(authMiddleware);

// ===== VEHICLE LOGS (Usage Tracking) - Must be before /:id routes =====

// Get all logs with filters (admin only)
router.get('/logs', roleGuard('admin'), (req, res) => vehiclesController.getAllLogs(req as AuthRequest, res));

// Get active vehicle usage (inspectors/admins)
router.get('/logs/active', roleGuard('inspector', 'admin'), (req, res) => vehiclesController.getActiveUsage(req as AuthRequest, res));

// Get my vehicle usage logs (any authenticated user)
router.get('/logs/my', (req, res) => vehiclesController.getMyLogs(req as AuthRequest, res));

// Start vehicle usage (inspectors/admins)
router.post('/logs/start', roleGuard('inspector', 'admin'), (req, res) => vehiclesController.startUsage(req as AuthRequest, res));

// End vehicle usage (inspectors/admins)
router.patch('/logs/:logId/end', roleGuard('inspector', 'admin'), (req, res) => vehiclesController.endUsage(req as AuthRequest, res));

// Cancel vehicle usage (admins only)
router.patch('/logs/:logId/cancel', roleGuard('admin'), (req, res) => vehiclesController.cancelUsage(req as AuthRequest, res));

// Get specific log by ID
router.get('/logs/:logId', roleGuard('inspector', 'admin'), (req, res) => vehiclesController.getLogById(req as AuthRequest, res));

// ===== VEHICLE CRUD =====

// Search vehicle by plate (inspectors/admins only)
router.get('/plate/:plate', roleGuard('inspector', 'admin'), (req, res) => vehiclesController.findByPlate(req as AuthRequest, res));

// All authenticated users can create and list vehicles
router.post('/', (req, res) => vehiclesController.create(req as AuthRequest, res));
router.get('/', (req, res) => vehiclesController.findAll(req as AuthRequest, res));

// Get logs for a specific vehicle (must be before /:id)
router.get('/:vehicleId/logs', roleGuard('inspector', 'admin'), (req, res) => vehiclesController.getVehicleLogs(req as AuthRequest, res));

// Dynamic ID routes last
router.get('/:id', (req, res) => vehiclesController.findById(req as AuthRequest, res));
router.patch('/:id', (req, res) => vehiclesController.update(req as AuthRequest, res));
router.delete('/:id', roleGuard('admin'), (req, res) => vehiclesController.delete(req as AuthRequest, res));

export default router;
