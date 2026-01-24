'use client';

type BadgeVariant = 'success' | 'warning' | 'error' | 'info' | 'default' | 'primary';

interface BadgeProps {
  children: React.ReactNode;
  variant?: BadgeVariant;
  size?: 'sm' | 'md' | 'lg';
  dot?: boolean;
}

export default function Badge({ children, variant = 'default', size = 'md', dot = false }: BadgeProps) {
  const variants = {
    success: 'bg-success-100 text-success-600 ring-success-600/20',
    warning: 'bg-warning-100 text-warning-600 ring-warning-600/20',
    error: 'bg-red-100 text-red-700 ring-red-600/20',
    info: 'bg-info-100 text-info-600 ring-info-600/20',
    default: 'bg-muted text-muted-foreground ring-border',
    primary: 'bg-primary/10 text-primary ring-primary/20',
  };

  const dotColors = {
    success: 'bg-success-600',
    warning: 'bg-warning-600',
    error: 'bg-red-600',
    info: 'bg-info-600',
    default: 'bg-muted-foreground',
    primary: 'bg-primary',
  };

  const sizes = {
    sm: 'px-2 py-0.5 text-[10px]',
    md: 'px-2.5 py-1 text-xs',
    lg: 'px-3 py-1.5 text-sm',
  };

  return (
    <span
      className={`
        inline-flex items-center gap-1.5 rounded-full font-medium ring-1 ring-inset
        ${variants[variant]} ${sizes[size]}
      `}
    >
      {dot && (
        <span className={`w-1.5 h-1.5 rounded-full ${dotColors[variant]}`}></span>
      )}
      {children}
    </span>
  );
}

// Status Badge específico para reportes
export function StatusBadge({ status }: { status: string }) {
  const statusConfig: Record<string, { variant: BadgeVariant; label: string }> = {
    pendiente: { variant: 'warning', label: 'Pendiente' },
    en_proceso: { variant: 'info', label: 'En Proceso' },
    resuelto: { variant: 'success', label: 'Resuelto' },
    rechazado: { variant: 'error', label: 'Rechazado' },
    archivado: { variant: 'default', label: 'Archivado' },
  };

  const config = statusConfig[status] || { variant: 'default' as BadgeVariant, label: status };

  return (
    <Badge variant={config.variant} dot>
      {config.label}
    </Badge>
  );
}

// Priority Badge específico para prioridades
export function PriorityBadge({ priority }: { priority: string }) {
  const priorityConfig: Record<string, { variant: BadgeVariant; label: string }> = {
    baja: { variant: 'default', label: 'Baja' },
    media: { variant: 'info', label: 'Media' },
    alta: { variant: 'warning', label: 'Alta' },
    urgente: { variant: 'error', label: 'Urgente' },
  };

  const config = priorityConfig[priority] || { variant: 'default' as BadgeVariant, label: priority };

  return (
    <Badge variant={config.variant} size="sm">
      {config.label}
    </Badge>
  );
}

// Role Badge para usuarios
export function RoleBadge({ role }: { role: string }) {
  const roleConfig: Record<string, { variant: BadgeVariant; label: string }> = {
    admin: { variant: 'primary', label: 'Administrador' },
    inspector: { variant: 'info', label: 'Inspector' },
    citizen: { variant: 'default', label: 'Ciudadano' },
  };

  const config = roleConfig[role] || { variant: 'default' as BadgeVariant, label: role };

  return (
    <Badge variant={config.variant}>
      {config.label}
    </Badge>
  );
}
