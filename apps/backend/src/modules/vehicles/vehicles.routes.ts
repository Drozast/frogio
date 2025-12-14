import { Router } from 'express';
import { VehiclesController } from './vehicles.controller.js';
import { authMiddleware, roleGuard, type AuthRequest } from '../../middleware/auth.middleware.js';

const router = Router();
const vehiclesController = new VehiclesController();

// All routes require authentication
router.use(authMiddleware);

// Search vehicle by plate (inspectors/admins only)
router.get('/plate/:plate', roleGuard('inspector', 'admin'), (req, res) => vehiclesController.findByPlate(req as AuthRequest, res));

// All authenticated users can create and list vehicles
router.post('/', (req, res) => vehiclesController.create(req as AuthRequest, res));
router.get('/', (req, res) => vehiclesController.findAll(req as AuthRequest, res));
router.get('/:id', (req, res) => vehiclesController.findById(req as AuthRequest, res));

// Citizens can update their own, inspectors/admins can update any
router.patch('/:id', (req, res) => vehiclesController.update(req as AuthRequest, res));

// Only Admins can delete vehicles
router.delete('/:id', roleGuard('admin'), (req, res) => vehiclesController.delete(req as AuthRequest, res));

export default router;
