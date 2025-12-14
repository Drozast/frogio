import { Response } from 'express';
import { MedicalRecordsService } from './medical-records.service.js';
import type { AuthRequest } from '../../middleware/auth.middleware.js';
import type { CreateMedicalRecordDto, UpdateMedicalRecordDto } from './medical-records.types.js';

const medicalRecordsService = new MedicalRecordsService();

export class MedicalRecordsController {
  async create(req: AuthRequest, res: Response): Promise<void> {
    try {
      const data: CreateMedicalRecordDto = req.body;
      const tenantId = req.user!.tenantId;

      const record = await medicalRecordsService.create(data, tenantId);

      res.status(201).json(record);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al crear ficha médica';
      res.status(400).json({ error: message });
    }
  }

  async findAll(req: AuthRequest, res: Response): Promise<void> {
    try {
      const tenantId = req.user!.tenantId;

      // Citizens can only see their own medical records
      const householdHeadId = req.user!.role === 'citizen' ? req.user!.userId : undefined;

      const records = await medicalRecordsService.findAll(tenantId, householdHeadId);

      res.json(records);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al obtener fichas médicas';
      res.status(400).json({ error: message });
    }
  }

  async findById(req: AuthRequest, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const tenantId = req.user!.tenantId;

      const record = await medicalRecordsService.findById(id, tenantId);

      // Citizens can only see their own medical records
      if (req.user!.role === 'citizen' && record.household_head_id !== req.user!.userId) {
        res.status(403).json({ error: 'No tienes permiso para ver esta ficha médica' });
        return;
      }

      res.json(record);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al obtener ficha médica';
      res.status(400).json({ error: message });
    }
  }

  async findMyRecord(req: AuthRequest, res: Response): Promise<void> {
    try {
      const userId = req.user!.userId;
      const tenantId = req.user!.tenantId;

      const record = await medicalRecordsService.findByHouseholdHead(userId, tenantId);

      if (!record) {
        res.status(404).json({ error: 'No tienes una ficha médica registrada' });
        return;
      }

      res.json(record);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al obtener ficha médica';
      res.status(400).json({ error: message });
    }
  }

  async update(req: AuthRequest, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const data: UpdateMedicalRecordDto = req.body;
      const tenantId = req.user!.tenantId;

      // Citizens can only update their own records
      if (req.user!.role === 'citizen') {
        const existingRecord = await medicalRecordsService.findById(id, tenantId);
        if (existingRecord.household_head_id !== req.user!.userId) {
          res.status(403).json({ error: 'No tienes permiso para actualizar esta ficha médica' });
          return;
        }
      }

      const record = await medicalRecordsService.update(id, data, tenantId);

      res.json(record);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al actualizar ficha médica';
      res.status(400).json({ error: message });
    }
  }

  async delete(req: AuthRequest, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const tenantId = req.user!.tenantId;

      const result = await medicalRecordsService.delete(id, tenantId);

      res.json(result);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al eliminar ficha médica';
      res.status(400).json({ error: message });
    }
  }
}
