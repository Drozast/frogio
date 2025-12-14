export interface CreateInfractionDto {
  userId: string;
  type: 'trafico' | 'ruido' | 'basura' | 'construccion' | 'otro';
  description: string;
  address: string;
  latitude?: number;
  longitude?: number;
  amount: number; // Fine amount in CLP
  vehiclePlate?: string;
}

export interface UpdateInfractionDto {
  status?: 'pendiente' | 'pagada' | 'anulada';
  paymentMethod?: 'efectivo' | 'transferencia' | 'tarjeta' | 'webpay';
  paymentReference?: string;
  notes?: string;
}
