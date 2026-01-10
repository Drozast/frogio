'use client';

type BadgeVariant = 'success' | 'warning' | 'error' | 'info' | 'default';

interface BadgeProps {
  children: React.ReactNode;
  variant?: BadgeVariant;
  size?: 'sm' | 'md';
}

export default function Badge({ children, variant = 'default', size = 'md' }: BadgeProps) {
  const variants = {
    success: 'bg-green-100 text-green-800',
    warning: 'bg-yellow-100 text-yellow-800',
    error: 'bg-red-100 text-red-800',
    info: 'bg-blue-100 text-blue-800',
    default: 'bg-gray-100 text-gray-800',
  };

  const sizes = {
    sm: 'px-2 py-0.5 text-xs',
    md: 'px-2.5 py-0.5 text-sm',
  };

  return (
    <span
      className={`inline-flex items-center rounded-full font-medium ${variants[variant]} ${sizes[size]}`}
    >
      {children}
    </span>
  );
}

// Status Badge específico para reportes
export function StatusBadge({ status }: { status: string }) {
  const statusMap: Record<string, BadgeVariant> = {
    pendiente: 'warning',
    en_proceso: 'info',
    resuelto: 'success',
    rechazado: 'error',
    archivado: 'default',
  };

  return (
    <Badge variant={statusMap[status] || 'default'}>
      {status.replace('_', ' ').toUpperCase()}
    </Badge>
  );
}

// Priority Badge específico para prioridades
export function PriorityBadge({ priority }: { priority: string }) {
  const priorityMap: Record<string, BadgeVariant> = {
    baja: 'default',
    media: 'info',
    alta: 'warning',
    urgente: 'error',
  };

  return (
    <Badge variant={priorityMap[priority] || 'default'}>
      {priority.toUpperCase()}
    </Badge>
  );
}
