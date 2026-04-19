'use client';

import { useState, useMemo, useCallback, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
  ArrowPathIcon,
  PlusIcon,
  MagnifyingGlassIcon,
  XMarkIcon,
  ShieldCheckIcon,
  IdentificationIcon,
  UserIcon,
  UsersIcon,
  CheckCircleIcon,
  EnvelopeIcon,
  PhoneIcon,
  CalendarDaysIcon,
  FingerPrintIcon,
  LockClosedIcon,
  TrashIcon,
  ArrowsRightLeftIcon,
  NoSymbolIcon,
  EyeIcon,
  EyeSlashIcon,
} from '@heroicons/react/24/outline';
import { FROGIO_COLORS } from '@/lib/theme';
import {
  createUser,
  updateUser,
  toggleUserStatus,
  updateUserPassword,
  deleteUser,
  pick,
  type CreateUserBody,
} from '@/lib/admin-api';

// ─────────────────────────────────────────────────────────────────────────────
// Types
// ─────────────────────────────────────────────────────────────────────────────

interface RawUser {
  id: string;
  email: string;
  first_name?: string;
  firstName?: string;
  last_name?: string;
  lastName?: string;
  rut?: string | null;
  phone?: string | null;
  role: string;
  is_active?: boolean;
  isActive?: boolean;
  created_at?: string;
  createdAt?: string;
  [k: string]: unknown;
}

interface NormalizedUser {
  id: string;
  email: string;
  firstName: string;
  lastName: string;
  fullName: string;
  rut: string | null;
  phone: string | null;
  role: string;
  isActive: boolean;
  createdAt: string | null;
}

interface UsersClientProps {
  initialUsers: RawUser[];
  currentUserId: string | null;
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

function normalize(raw: RawUser): NormalizedUser {
  const firstName = (pick<string>(raw, 'firstName', 'first_name') || '').trim();
  const lastName = (pick<string>(raw, 'lastName', 'last_name') || '').trim();
  const isActive = pick<boolean>(raw, 'isActive', 'is_active');
  const createdAt = pick<string>(raw, 'createdAt', 'created_at') || null;
  const rut = (pick<string>(raw, 'rut') || '').trim();
  const phone = (pick<string>(raw, 'phone') || '').trim();
  return {
    id: String(raw.id),
    email: String(raw.email || ''),
    firstName,
    lastName,
    fullName: [firstName, lastName].filter(Boolean).join(' '),
    rut: rut || null,
    phone: phone || null,
    role: String(raw.role || 'citizen').toLowerCase(),
    isActive: isActive ?? true,
    createdAt,
  };
}

function roleColor(role: string): string {
  switch (role.toLowerCase()) {
    case 'admin':
      return FROGIO_COLORS.emergency;
    case 'inspector':
      return FROGIO_COLORS.info;
    case 'citizen':
      return FROGIO_COLORS.primary;
    default:
      return FROGIO_COLORS.textSecondary;
  }
}

function roleLabel(role: string): string {
  switch (role.toLowerCase()) {
    case 'admin':
      return 'ADMIN';
    case 'inspector':
      return 'INSPECTOR';
    case 'citizen':
      return 'CIUDADANO';
    default:
      return role.toUpperCase();
  }
}

function computeInitials(name: string, email: string): string {
  const base = name.trim() || email.trim();
  if (!base) return '?';
  const parts = base.split(/[\s@]+/).filter(Boolean);
  if (parts.length === 0) return base[0].toUpperCase();
  if (parts.length === 1) {
    return (parts[0].length >= 2
      ? parts[0].substring(0, 2)
      : parts[0]
    ).toUpperCase();
  }
  return (parts[0][0] + parts[1][0]).toUpperCase();
}

function formatDate(d: string | null): string {
  if (!d) return 'Desconocido';
  try {
    const date = new Date(d);
    if (Number.isNaN(date.getTime())) return 'Desconocido';
    return date.toLocaleDateString('es-CL', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
    });
  } catch {
    return 'Desconocido';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Toast
// ─────────────────────────────────────────────────────────────────────────────

interface Toast {
  id: number;
  message: string;
  type: 'success' | 'error';
}

let toastIdCounter = 0;

// ─────────────────────────────────────────────────────────────────────────────
// Main component
// ─────────────────────────────────────────────────────────────────────────────

export default function UsersClient({
  initialUsers,
  currentUserId,
}: UsersClientProps) {
  const [users, setUsers] = useState<NormalizedUser[]>(() =>
    (initialUsers || []).map(normalize)
  );
  const [isLoading, setIsLoading] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [roleFilter, setRoleFilter] = useState<
    'all' | 'admin' | 'inspector' | 'citizen'
  >('all');
  const [activeFilter, setActiveFilter] = useState<'all' | 'active' | 'inactive'>(
    'all'
  );
  const [selectedUser, setSelectedUser] = useState<NormalizedUser | null>(null);
  const [createOpen, setCreateOpen] = useState(false);
  const [toasts, setToasts] = useState<Toast[]>([]);

  const showToast = useCallback(
    (message: string, type: 'success' | 'error' = 'success') => {
      const id = ++toastIdCounter;
      setToasts((prev) => [...prev, { id, message, type }]);
      setTimeout(() => {
        setToasts((prev) => prev.filter((t) => t.id !== id));
      }, 3500);
    },
    []
  );

  const refresh = useCallback(async () => {
    setIsLoading(true);
    try {
      const token = document.cookie
        .split('; ')
        .find((r) => r.startsWith('accessToken='))
        ?.split('=')[1];
      if (!token) return;
      const apiBase =
        process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000';
      const res = await fetch(`${apiBase}/api/users`, {
        headers: {
          Authorization: `Bearer ${token}`,
          'X-Tenant-ID':
            process.env.NEXT_PUBLIC_TENANT_ID || 'santa_juana',
        },
        cache: 'no-store',
      });
      if (res.ok) {
        const json = await res.json();
        const list: RawUser[] = Array.isArray(json)
          ? json
          : Array.isArray(json?.data)
          ? json.data
          : [];
        setUsers(list.map(normalize));
      }
    } catch (err) {
      console.error('refresh error', err);
    } finally {
      setIsLoading(false);
    }
  }, []);

  const filtered = useMemo(() => {
    const q = searchQuery.trim().toLowerCase();
    return users.filter((u) => {
      if (roleFilter !== 'all' && u.role !== roleFilter) return false;
      if (activeFilter === 'active' && !u.isActive) return false;
      if (activeFilter === 'inactive' && u.isActive) return false;
      if (q) {
        const hay =
          `${u.firstName} ${u.lastName} ${u.email}`.toLowerCase();
        if (!hay.includes(q)) return false;
      }
      return true;
    });
  }, [users, searchQuery, roleFilter, activeFilter]);

  const counts = useMemo(() => {
    return {
      total: users.length,
      admins: users.filter((u) => u.role === 'admin').length,
      inspectors: users.filter((u) => u.role === 'inspector').length,
      citizens: users.filter((u) => u.role === 'citizen').length,
      actives: users.filter((u) => u.isActive).length,
    };
  }, [users]);

  // ───────── Actions ─────────

  const handleToggleStatus = async (user: NormalizedUser) => {
    try {
      await toggleUserStatus(user.id);
      const next = { ...user, isActive: !user.isActive };
      setUsers((prev) => prev.map((u) => (u.id === user.id ? next : u)));
      setSelectedUser((cur) => (cur && cur.id === user.id ? next : cur));
      showToast(next.isActive ? 'Usuario activado' : 'Usuario desactivado');
    } catch (err) {
      console.error(err);
      showToast('No se pudo actualizar el estado', 'error');
    }
  };

  const handleUpdateRole = async (
    user: NormalizedUser,
    newRole: 'admin' | 'inspector' | 'citizen'
  ) => {
    try {
      await updateUser(user.id, { role: newRole });
      const next = { ...user, role: newRole };
      setUsers((prev) => prev.map((u) => (u.id === user.id ? next : u)));
      setSelectedUser((cur) => (cur && cur.id === user.id ? next : cur));
      showToast('Rol actualizado');
    } catch (err) {
      console.error(err);
      showToast('No se pudo actualizar el rol', 'error');
    }
  };

  const handleChangePassword = async (
    user: NormalizedUser,
    password: string
  ) => {
    try {
      await updateUserPassword(user.id, password);
      showToast('Contraseña actualizada');
    } catch (err) {
      console.error(err);
      showToast('No se pudo actualizar la contraseña', 'error');
    }
  };

  const handleDelete = async (user: NormalizedUser) => {
    try {
      await deleteUser(user.id);
      setUsers((prev) => prev.filter((u) => u.id !== user.id));
      setSelectedUser(null);
      showToast('Usuario eliminado');
    } catch (err) {
      console.error(err);
      showToast('No se pudo eliminar', 'error');
    }
  };

  const handleCreate = async (
    body: CreateUserBody
  ): Promise<{ ok: boolean; error?: string }> => {
    try {
      await createUser(body);
      showToast('Usuario creado');
      await refresh();
      return { ok: true };
    } catch (err) {
      const msg = err instanceof Error ? err.message : 'Error al crear usuario';
      return { ok: false, error: msg };
    }
  };

  // ───────── Render ─────────

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-start gap-3">
        <div
          className="w-1 self-stretch rounded-full"
          style={{
            background: `linear-gradient(180deg, ${FROGIO_COLORS.primaryDark}, ${FROGIO_COLORS.primary})`,
            minHeight: 44,
          }}
        />
        <div className="flex-1 min-w-0">
          <h2 className="text-2xl font-bold text-gray-900">Personal</h2>
          <p className="text-sm text-gray-500">
            Gestión de usuarios y roles · {counts.total} en total
          </p>
        </div>
        <div className="flex items-center gap-2">
          <button
            type="button"
            onClick={refresh}
            disabled={isLoading}
            className="inline-flex items-center justify-center w-10 h-10 rounded-lg border transition-colors disabled:opacity-50"
            style={{
              borderColor: `${FROGIO_COLORS.primary}33`,
              backgroundColor: `${FROGIO_COLORS.primary}10`,
              color: FROGIO_COLORS.primaryDark,
            }}
            aria-label="Refrescar"
          >
            <ArrowPathIcon
              className={`w-5 h-5 ${isLoading ? 'animate-spin' : ''}`}
            />
          </button>
          <button
            type="button"
            onClick={() => setCreateOpen(true)}
            className="inline-flex items-center gap-2 px-4 py-2 rounded-lg text-white font-semibold shadow-sm transition-all hover:shadow-md"
            style={{
              background: `linear-gradient(135deg, ${FROGIO_COLORS.primaryDark}, ${FROGIO_COLORS.primary})`,
            }}
          >
            <PlusIcon className="w-5 h-5" />
            <span className="hidden sm:inline">Nuevo usuario</span>
          </button>
        </div>
      </div>

      {/* Stats row */}
      <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-5 gap-3">
        <StatMini
          label="Total"
          count={counts.total}
          color={FROGIO_COLORS.textPrimary}
          icon={<UsersIcon className="w-5 h-5" />}
        />
        <StatMini
          label="Admins"
          count={counts.admins}
          color={FROGIO_COLORS.emergency}
          icon={<ShieldCheckIcon className="w-5 h-5" />}
        />
        <StatMini
          label="Inspectores"
          count={counts.inspectors}
          color={FROGIO_COLORS.info}
          icon={<IdentificationIcon className="w-5 h-5" />}
        />
        <StatMini
          label="Ciudadanos"
          count={counts.citizens}
          color={FROGIO_COLORS.primary}
          icon={<UserIcon className="w-5 h-5" />}
        />
        <StatMini
          label="Activos"
          count={counts.actives}
          color={FROGIO_COLORS.success}
          icon={<CheckCircleIcon className="w-5 h-5" />}
        />
      </div>

      {/* Filters */}
      <div className="bg-white rounded-xl border border-gray-200 p-4 space-y-3">
        <div className="relative">
          <MagnifyingGlassIcon className="w-5 h-5 absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Buscar por nombre o email..."
            className="w-full pl-10 pr-10 py-2.5 rounded-lg border border-gray-300 text-sm focus:outline-none focus:ring-2 focus:ring-green-500/40 focus:border-green-500"
          />
          {searchQuery && (
            <button
              onClick={() => setSearchQuery('')}
              className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
              aria-label="Limpiar"
            >
              <XMarkIcon className="w-4 h-4" />
            </button>
          )}
        </div>
        <div className="flex flex-wrap gap-2">
          <RoleChip
            value="all"
            label="Todos"
            active={roleFilter === 'all'}
            color={FROGIO_COLORS.primary}
            onClick={() => setRoleFilter('all')}
            icon={<UsersIcon className="w-4 h-4" />}
          />
          <RoleChip
            value="admin"
            label="Admin"
            active={roleFilter === 'admin'}
            color={FROGIO_COLORS.emergency}
            onClick={() => setRoleFilter('admin')}
            icon={<ShieldCheckIcon className="w-4 h-4" />}
          />
          <RoleChip
            value="inspector"
            label="Inspector"
            active={roleFilter === 'inspector'}
            color={FROGIO_COLORS.info}
            onClick={() => setRoleFilter('inspector')}
            icon={<IdentificationIcon className="w-4 h-4" />}
          />
          <RoleChip
            value="citizen"
            label="Ciudadano"
            active={roleFilter === 'citizen'}
            color={FROGIO_COLORS.primary}
            onClick={() => setRoleFilter('citizen')}
            icon={<UserIcon className="w-4 h-4" />}
          />
          <div className="ml-auto flex items-center gap-1 rounded-full bg-gray-100 p-1 text-xs">
            {(['all', 'active', 'inactive'] as const).map((v) => (
              <button
                key={v}
                onClick={() => setActiveFilter(v)}
                className={`px-3 py-1 rounded-full font-semibold transition-all ${
                  activeFilter === v
                    ? 'bg-white shadow text-gray-900'
                    : 'text-gray-500 hover:text-gray-700'
                }`}
              >
                {v === 'all' ? 'Todos' : v === 'active' ? 'Activos' : 'Inactivos'}
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* Cards grid / states */}
      {isLoading && users.length === 0 ? (
        <SkeletonGrid />
      ) : filtered.length === 0 ? (
        <EmptyState hasUsers={users.length > 0} onCreate={() => setCreateOpen(true)} />
      ) : (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
          <AnimatePresence>
            {filtered.map((user, i) => (
              <motion.div
                key={user.id}
                initial={{ opacity: 0, y: 12 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -8 }}
                transition={{
                  duration: 0.32,
                  delay: Math.min(i * 0.04, 0.4),
                  ease: [0.22, 1, 0.36, 1],
                }}
              >
                <UserCard user={user} onClick={() => setSelectedUser(user)} />
              </motion.div>
            ))}
          </AnimatePresence>
        </div>
      )}

      {/* Detail panel */}
      <AnimatePresence>
        {selectedUser && (
          <UserDetailPanel
            user={selectedUser}
            currentUserId={currentUserId}
            onClose={() => setSelectedUser(null)}
            onToggleStatus={() => handleToggleStatus(selectedUser)}
            onUpdateRole={(role) => handleUpdateRole(selectedUser, role)}
            onChangePassword={(pwd) =>
              handleChangePassword(selectedUser, pwd)
            }
            onDelete={() => handleDelete(selectedUser)}
          />
        )}
      </AnimatePresence>

      {/* Create modal */}
      <AnimatePresence>
        {createOpen && (
          <CreateUserModal
            onClose={() => setCreateOpen(false)}
            onSubmit={handleCreate}
          />
        )}
      </AnimatePresence>

      {/* Toasts */}
      <div className="fixed bottom-4 right-4 z-[200] flex flex-col gap-2">
        <AnimatePresence>
          {toasts.map((t) => (
            <motion.div
              key={t.id}
              initial={{ opacity: 0, y: 16, scale: 0.95 }}
              animate={{ opacity: 1, y: 0, scale: 1 }}
              exit={{ opacity: 0, y: 8, scale: 0.95 }}
              transition={{ duration: 0.2 }}
              className="px-4 py-3 rounded-lg text-white text-sm font-medium shadow-lg"
              style={{
                backgroundColor:
                  t.type === 'success'
                    ? FROGIO_COLORS.success
                    : FROGIO_COLORS.emergency,
              }}
            >
              {t.message}
            </motion.div>
          ))}
        </AnimatePresence>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// StatMini
// ─────────────────────────────────────────────────────────────────────────────

function StatMini({
  label,
  count,
  color,
  icon,
}: {
  label: string;
  count: number;
  color: string;
  icon: React.ReactNode;
}) {
  return (
    <div
      className="bg-white rounded-xl border p-3 flex items-center gap-3 shadow-sm"
      style={{ borderColor: `${color}26` }}
    >
      <div
        className="flex items-center justify-center w-10 h-10 rounded-lg"
        style={{ backgroundColor: `${color}1A`, color }}
      >
        {icon}
      </div>
      <div className="min-w-0">
        <div
          className="text-xl font-bold leading-none tabular-nums"
          style={{ color }}
        >
          {count}
        </div>
        <div className="text-xs text-gray-500 mt-1 truncate">{label}</div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// RoleChip
// ─────────────────────────────────────────────────────────────────────────────

function RoleChip({
  value,
  label,
  active,
  color,
  onClick,
  icon,
}: {
  value: string;
  label: string;
  active: boolean;
  color: string;
  onClick: () => void;
  icon: React.ReactNode;
}) {
  return (
    <button
      key={value}
      onClick={onClick}
      className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-semibold transition-all"
      style={
        active
          ? {
              background: `linear-gradient(135deg, ${color}E6, ${color})`,
              color: '#fff',
              boxShadow: `0 4px 12px ${color}59`,
              border: '1px solid transparent',
            }
          : {
              backgroundColor: '#fff',
              color: FROGIO_COLORS.textSecondary,
              border: `1px solid ${FROGIO_COLORS.border}`,
            }
      }
    >
      <span style={{ color: active ? '#fff' : color }}>{icon}</span>
      {label}
    </button>
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// UserCard
// ─────────────────────────────────────────────────────────────────────────────

function UserCard({
  user,
  onClick,
}: {
  user: NormalizedUser;
  onClick: () => void;
}) {
  const color = roleColor(user.role);
  return (
    <button
      type="button"
      onClick={onClick}
      className="group w-full text-left bg-white rounded-xl border border-gray-200 shadow-sm hover:shadow-md transition-all overflow-hidden relative"
    >
      <div
        className="absolute left-0 top-0 bottom-0 w-1"
        style={{ backgroundColor: color }}
      />
      <div className="pl-4 pr-3 py-3 flex items-center gap-3">
        {/* Avatar */}
        <div
          className="flex items-center justify-center w-12 h-12 rounded-full text-white font-bold text-base shrink-0"
          style={{
            background: `linear-gradient(135deg, ${color}D9, ${color})`,
            boxShadow: `0 4px 14px ${color}59`,
            border: '2px solid #fff',
          }}
        >
          {computeInitials(user.fullName, user.email)}
        </div>

        <div className="flex-1 min-w-0">
          <div className="font-bold text-gray-900 text-sm truncate">
            {user.fullName || 'Sin nombre'}
          </div>
          <div className="flex items-center gap-1 text-xs text-gray-500 mt-0.5">
            <EnvelopeIcon className="w-3 h-3 shrink-0" />
            <span className="truncate">{user.email}</span>
          </div>
          <div className="mt-2 flex items-center gap-1.5 flex-wrap">
            <RolePill role={user.role} />
            <StatusPill active={user.isActive} />
          </div>
          {(user.rut || user.phone) && (
            <div className="mt-1.5 flex items-center gap-3 text-[11px] text-gray-400">
              {user.rut && <span>RUT: {user.rut}</span>}
              {user.phone && <span>{user.phone}</span>}
            </div>
          )}
        </div>

        <svg
          className="w-4 h-4 text-gray-300 shrink-0 group-hover:translate-x-0.5 transition-transform"
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth={2}
            d="M9 5l7 7-7 7"
          />
        </svg>
      </div>
    </button>
  );
}

function RolePill({ role }: { role: string }) {
  const color = roleColor(role);
  return (
    <span
      className="inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-bold tracking-wide"
      style={{
        backgroundColor: `${color}1F`,
        color,
        border: `1px solid ${color}4D`,
      }}
    >
      {roleLabel(role)}
    </span>
  );
}

function StatusPill({ active }: { active: boolean }) {
  const color = active ? FROGIO_COLORS.success : FROGIO_COLORS.textTertiary;
  return (
    <span
      className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-semibold"
      style={{ backgroundColor: `${color}1F`, color }}
    >
      <span
        className="w-1.5 h-1.5 rounded-full"
        style={{ backgroundColor: color }}
      />
      {active ? 'Activo' : 'Inactivo'}
    </span>
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Skeleton + EmptyState
// ─────────────────────────────────────────────────────────────────────────────

function SkeletonGrid() {
  return (
    <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
      {Array.from({ length: 6 }).map((_, i) => (
        <div
          key={i}
          className="bg-white rounded-xl border border-gray-200 p-4 animate-pulse"
        >
          <div className="flex items-center gap-3">
            <div className="w-12 h-12 rounded-full bg-gray-200" />
            <div className="flex-1 space-y-2">
              <div className="h-3 rounded bg-gray-200 w-1/2" />
              <div className="h-3 rounded bg-gray-100 w-3/4" />
              <div className="flex gap-2">
                <div className="h-4 rounded-full bg-gray-100 w-16" />
                <div className="h-4 rounded-full bg-gray-100 w-14" />
              </div>
            </div>
          </div>
        </div>
      ))}
    </div>
  );
}

function EmptyState({
  hasUsers,
  onCreate,
}: {
  hasUsers: boolean;
  onCreate: () => void;
}) {
  return (
    <div className="bg-white rounded-xl border border-gray-200 py-16 px-6 text-center">
      <div
        className="mx-auto w-20 h-20 rounded-full flex items-center justify-center mb-4"
        style={{
          background: `linear-gradient(135deg, ${FROGIO_COLORS.primary}2E, ${FROGIO_COLORS.accent}10)`,
        }}
      >
        <UsersIcon
          className="w-10 h-10"
          style={{ color: FROGIO_COLORS.primary }}
        />
      </div>
      <div className="text-lg font-bold text-gray-900">Sin resultados</div>
      <p className="text-sm text-gray-500 mt-1 max-w-sm mx-auto">
        {hasUsers
          ? 'Ningún usuario coincide con los filtros. Prueba ajustando la búsqueda o el rol.'
          : 'Aún no hay usuarios registrados. Crea el primero con el botón "Nuevo usuario".'}
      </p>
      {!hasUsers && (
        <button
          onClick={onCreate}
          className="mt-5 inline-flex items-center gap-2 px-4 py-2 rounded-lg text-white font-semibold"
          style={{
            background: `linear-gradient(135deg, ${FROGIO_COLORS.primaryDark}, ${FROGIO_COLORS.primary})`,
          }}
        >
          <PlusIcon className="w-4 h-4" />
          Crear usuario
        </button>
      )}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// User detail panel (modal sheet)
// ─────────────────────────────────────────────────────────────────────────────

function UserDetailPanel({
  user,
  currentUserId,
  onClose,
  onToggleStatus,
  onUpdateRole,
  onChangePassword,
  onDelete,
}: {
  user: NormalizedUser;
  currentUserId: string | null;
  onClose: () => void;
  onToggleStatus: () => void | Promise<void>;
  onUpdateRole: (
    role: 'admin' | 'inspector' | 'citizen'
  ) => void | Promise<void>;
  onChangePassword: (password: string) => void | Promise<void>;
  onDelete: () => void | Promise<void>;
}) {
  const isSelf = currentUserId !== null && user.id === currentUserId;
  const [busy, setBusy] = useState(false);
  const [showRoleMenu, setShowRoleMenu] = useState(false);
  const [showPwdInput, setShowPwdInput] = useState(false);
  const [pwd, setPwd] = useState('');
  const [pwdError, setPwdError] = useState<string | null>(null);
  const [showPwd, setShowPwd] = useState(false);
  const [showConfirmDelete, setShowConfirmDelete] = useState(false);

  const color = roleColor(user.role);

  // Lock body scroll
  useEffect(() => {
    const prev = document.body.style.overflow;
    document.body.style.overflow = 'hidden';
    return () => {
      document.body.style.overflow = prev;
    };
  }, []);

  const wrap = async (fn: () => Promise<void> | void) => {
    setBusy(true);
    try {
      await fn();
    } finally {
      setBusy(false);
    }
  };

  const submitPassword = async () => {
    if (pwd.length < 8) {
      setPwdError('Mínimo 8 caracteres');
      return;
    }
    setPwdError(null);
    await wrap(async () => {
      await onChangePassword(pwd);
      setPwd('');
      setShowPwdInput(false);
    });
  };

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      transition={{ duration: 0.2 }}
      className="fixed inset-0 z-[100] flex items-end sm:items-center justify-center bg-black/50 backdrop-blur-sm p-0 sm:p-4"
      onClick={onClose}
    >
      <motion.div
        initial={{ opacity: 0, y: 32 }}
        animate={{ opacity: 1, y: 0 }}
        exit={{ opacity: 0, y: 32 }}
        transition={{ duration: 0.25, ease: [0.22, 1, 0.36, 1] }}
        className="w-full sm:max-w-lg bg-white sm:rounded-2xl rounded-t-2xl shadow-2xl max-h-[92vh] overflow-hidden flex flex-col"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header */}
        <div className="px-5 pt-5 pb-4 border-b border-gray-100">
          <div className="flex items-start gap-4">
            <div
              className="flex items-center justify-center w-16 h-16 rounded-full text-white font-bold text-lg shrink-0"
              style={{
                background: `linear-gradient(135deg, ${color}D9, ${color})`,
                boxShadow: `0 6px 18px ${color}59`,
              }}
            >
              {computeInitials(user.fullName, user.email)}
            </div>
            <div className="flex-1 min-w-0">
              <div className="text-lg font-bold text-gray-900 truncate">
                {user.fullName || 'Sin nombre'}
              </div>
              <div className="text-sm text-gray-500 truncate">{user.email}</div>
              <div className="mt-2 flex items-center gap-1.5 flex-wrap">
                <RolePill role={user.role} />
                <StatusPill active={user.isActive} />
                {isSelf && (
                  <span className="inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-bold bg-amber-50 text-amber-700 border border-amber-200">
                    Tú
                  </span>
                )}
              </div>
            </div>
            <button
              onClick={onClose}
              className="text-gray-400 hover:text-gray-600 -mt-1 -mr-1"
              aria-label="Cerrar"
            >
              <XMarkIcon className="w-6 h-6" />
            </button>
          </div>
        </div>

        {/* Body */}
        <div className="flex-1 overflow-y-auto p-5 space-y-3">
          {/* Info tiles */}
          <InfoTile
            icon={<IdentificationIcon className="w-4 h-4" />}
            label="RUT"
            value={user.rut || 'No registrado'}
          />
          <InfoTile
            icon={<PhoneIcon className="w-4 h-4" />}
            label="Teléfono"
            value={user.phone || 'No registrado'}
          />
          <InfoTile
            icon={<CalendarDaysIcon className="w-4 h-4" />}
            label="Registrado"
            value={formatDate(user.createdAt)}
          />
          <InfoTile
            icon={<FingerPrintIcon className="w-4 h-4" />}
            label="ID"
            value={user.id}
            mono
          />

          {/* Actions */}
          <div className="pt-2 space-y-2">
            <ActionButton
              icon={
                user.isActive ? (
                  <NoSymbolIcon className="w-5 h-5" />
                ) : (
                  <CheckCircleIcon className="w-5 h-5" />
                )
              }
              label={user.isActive ? 'Desactivar' : 'Activar'}
              color={user.isActive ? FROGIO_COLORS.warning : FROGIO_COLORS.success}
              disabled={busy}
              onClick={() => wrap(onToggleStatus)}
            />

            {/* Cambiar rol */}
            <div>
              <ActionButton
                icon={<ArrowsRightLeftIcon className="w-5 h-5" />}
                label="Cambiar rol"
                color={FROGIO_COLORS.info}
                disabled={busy}
                onClick={() => setShowRoleMenu((v) => !v)}
              />
              {showRoleMenu && (
                <div className="mt-2 grid grid-cols-3 gap-2">
                  {(['admin', 'inspector', 'citizen'] as const).map((r) => {
                    const c = roleColor(r);
                    const active = user.role === r;
                    return (
                      <button
                        key={r}
                        disabled={busy}
                        onClick={async () => {
                          if (active) {
                            setShowRoleMenu(false);
                            return;
                          }
                          await wrap(() => onUpdateRole(r));
                          setShowRoleMenu(false);
                        }}
                        className="px-2 py-2 rounded-lg text-xs font-semibold transition-all disabled:opacity-50"
                        style={
                          active
                            ? {
                                backgroundColor: `${c}1F`,
                                color: c,
                                border: `1.5px solid ${c}`,
                              }
                            : {
                                backgroundColor: '#fff',
                                color: FROGIO_COLORS.textSecondary,
                                border: `1px solid ${FROGIO_COLORS.border}`,
                              }
                        }
                      >
                        {roleLabel(r)}
                      </button>
                    );
                  })}
                </div>
              )}
            </div>

            {/* Cambiar contraseña */}
            <div>
              <ActionButton
                icon={<LockClosedIcon className="w-5 h-5" />}
                label="Cambiar contraseña"
                color={FROGIO_COLORS.primary}
                disabled={busy}
                onClick={() => setShowPwdInput((v) => !v)}
              />
              {showPwdInput && (
                <div className="mt-2 space-y-2">
                  <div className="relative">
                    <input
                      type={showPwd ? 'text' : 'password'}
                      value={pwd}
                      onChange={(e) => setPwd(e.target.value)}
                      placeholder="Nueva contraseña (mín. 8)"
                      className="w-full pr-10 pl-3 py-2 rounded-lg border border-gray-300 text-sm focus:outline-none focus:ring-2 focus:ring-green-500/40 focus:border-green-500"
                    />
                    <button
                      type="button"
                      onClick={() => setShowPwd((v) => !v)}
                      className="absolute right-2 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
                    >
                      {showPwd ? (
                        <EyeSlashIcon className="w-4 h-4" />
                      ) : (
                        <EyeIcon className="w-4 h-4" />
                      )}
                    </button>
                  </div>
                  {pwdError && (
                    <div className="text-xs text-red-600">{pwdError}</div>
                  )}
                  <div className="flex gap-2">
                    <button
                      onClick={() => {
                        setShowPwdInput(false);
                        setPwd('');
                        setPwdError(null);
                      }}
                      className="flex-1 px-3 py-2 rounded-lg text-sm font-semibold border border-gray-300 text-gray-700 hover:bg-gray-50"
                    >
                      Cancelar
                    </button>
                    <button
                      onClick={submitPassword}
                      disabled={busy}
                      className="flex-1 px-3 py-2 rounded-lg text-sm font-semibold text-white disabled:opacity-50"
                      style={{ backgroundColor: FROGIO_COLORS.primary }}
                    >
                      Guardar
                    </button>
                  </div>
                </div>
              )}
            </div>

            {/* Eliminar */}
            <ActionButton
              icon={<TrashIcon className="w-5 h-5" />}
              label={isSelf ? 'No puedes eliminarte' : 'Eliminar usuario'}
              color={FROGIO_COLORS.emergency}
              disabled={busy || isSelf}
              onClick={() => setShowConfirmDelete(true)}
            />
          </div>
        </div>

        {/* Confirm delete dialog */}
        {showConfirmDelete && (
          <div
            className="absolute inset-0 z-10 bg-black/40 backdrop-blur-sm flex items-center justify-center p-4"
            onClick={() => setShowConfirmDelete(false)}
          >
            <div
              className="w-full max-w-sm bg-white rounded-xl shadow-xl p-5"
              onClick={(e) => e.stopPropagation()}
            >
              <div className="flex items-center gap-3">
                <div
                  className="w-10 h-10 rounded-full flex items-center justify-center"
                  style={{ backgroundColor: `${FROGIO_COLORS.emergency}1F` }}
                >
                  <TrashIcon
                    className="w-5 h-5"
                    style={{ color: FROGIO_COLORS.emergency }}
                  />
                </div>
                <div>
                  <div className="font-bold text-gray-900">
                    Eliminar usuario
                  </div>
                  <div className="text-xs text-gray-500">
                    Esta acción no se puede deshacer
                  </div>
                </div>
              </div>
              <p className="text-sm text-gray-700 mt-3">
                ¿Seguro que deseas eliminar a{' '}
                <span className="font-semibold">
                  {user.fullName || user.email}
                </span>
                ?
              </p>
              <div className="flex gap-2 mt-4">
                <button
                  onClick={() => setShowConfirmDelete(false)}
                  className="flex-1 px-3 py-2 rounded-lg text-sm font-semibold border border-gray-300 text-gray-700 hover:bg-gray-50"
                >
                  Cancelar
                </button>
                <button
                  onClick={async () => {
                    setShowConfirmDelete(false);
                    await wrap(onDelete);
                  }}
                  className="flex-1 px-3 py-2 rounded-lg text-sm font-semibold text-white"
                  style={{ backgroundColor: FROGIO_COLORS.emergency }}
                >
                  Eliminar
                </button>
              </div>
            </div>
          </div>
        )}
      </motion.div>
    </motion.div>
  );
}

function InfoTile({
  icon,
  label,
  value,
  mono,
}: {
  icon: React.ReactNode;
  label: string;
  value: string;
  mono?: boolean;
}) {
  return (
    <div className="flex items-start gap-3 p-3 rounded-lg border border-gray-100 bg-gray-50/60">
      <div className="text-gray-400 mt-0.5">{icon}</div>
      <div className="min-w-0 flex-1">
        <div className="text-[10px] uppercase tracking-wider text-gray-400 font-semibold">
          {label}
        </div>
        <div
          className={`text-sm text-gray-900 mt-0.5 break-all ${
            mono ? 'font-mono' : 'font-medium'
          }`}
        >
          {value}
        </div>
      </div>
    </div>
  );
}

function ActionButton({
  icon,
  label,
  color,
  disabled,
  onClick,
}: {
  icon: React.ReactNode;
  label: string;
  color: string;
  disabled?: boolean;
  onClick: () => void;
}) {
  return (
    <button
      type="button"
      disabled={disabled}
      onClick={onClick}
      className="w-full flex items-center gap-3 px-4 py-3 rounded-lg font-semibold text-sm transition-all disabled:opacity-50 disabled:cursor-not-allowed"
      style={{
        backgroundColor: `${color}14`,
        color,
        border: `1px solid ${color}40`,
      }}
    >
      <span>{icon}</span>
      <span className="flex-1 text-left">{label}</span>
      <svg
        className="w-3.5 h-3.5 opacity-70"
        fill="none"
        stroke="currentColor"
        viewBox="0 0 24 24"
      >
        <path
          strokeLinecap="round"
          strokeLinejoin="round"
          strokeWidth={2.5}
          d="M9 5l7 7-7 7"
        />
      </svg>
    </button>
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Create user modal
// ─────────────────────────────────────────────────────────────────────────────

function CreateUserModal({
  onClose,
  onSubmit,
}: {
  onClose: () => void;
  onSubmit: (
    body: CreateUserBody
  ) => Promise<{ ok: boolean; error?: string }>;
}) {
  const [email, setEmail] = useState('');
  const [firstName, setFirstName] = useState('');
  const [lastName, setLastName] = useState('');
  const [rut, setRut] = useState('');
  const [phone, setPhone] = useState('');
  const [role, setRole] = useState<'admin' | 'inspector'>('inspector');
  const [password, setPassword] = useState('');
  const [showPwd, setShowPwd] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [submitError, setSubmitError] = useState<string | null>(null);

  // Lock body scroll
  useEffect(() => {
    const prev = document.body.style.overflow;
    document.body.style.overflow = 'hidden';
    return () => {
      document.body.style.overflow = prev;
    };
  }, []);

  const validate = (): boolean => {
    const e: Record<string, string> = {};
    const trimmedEmail = email.trim();
    if (!trimmedEmail) e.email = 'Requerido';
    else if (!/^[\w.+-]+@([\w-]+\.)+[\w-]{2,}$/.test(trimmedEmail))
      e.email = 'Email no válido';
    if (!firstName.trim()) e.firstName = 'Requerido';
    if (!lastName.trim()) e.lastName = 'Requerido';
    if (!password) e.password = 'Requerido';
    else if (password.length < 8) e.password = 'Mínimo 8 caracteres';
    setErrors(e);
    return Object.keys(e).length === 0;
  };

  const submit = async () => {
    setSubmitError(null);
    if (!validate()) return;
    setSubmitting(true);
    const result = await onSubmit({
      email: email.trim(),
      first_name: firstName.trim(),
      last_name: lastName.trim(),
      rut: rut.trim() || undefined,
      phone: phone.trim() || undefined,
      role,
      password,
    });
    setSubmitting(false);
    if (result.ok) {
      onClose();
    } else {
      setSubmitError(result.error || 'Error al crear usuario');
    }
  };

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      transition={{ duration: 0.2 }}
      className="fixed inset-0 z-[100] flex items-end sm:items-center justify-center bg-black/50 backdrop-blur-sm p-0 sm:p-4"
      onClick={onClose}
    >
      <motion.div
        initial={{ opacity: 0, y: 32 }}
        animate={{ opacity: 1, y: 0 }}
        exit={{ opacity: 0, y: 32 }}
        transition={{ duration: 0.25, ease: [0.22, 1, 0.36, 1] }}
        className="w-full sm:max-w-lg bg-white sm:rounded-2xl rounded-t-2xl shadow-2xl max-h-[92vh] overflow-hidden flex flex-col"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="px-5 pt-5 pb-3 border-b border-gray-100 flex items-center gap-3">
          <div
            className="w-10 h-10 rounded-lg flex items-center justify-center"
            style={{ backgroundColor: `${FROGIO_COLORS.primary}1F` }}
          >
            <PlusIcon
              className="w-5 h-5"
              style={{ color: FROGIO_COLORS.primary }}
            />
          </div>
          <div className="flex-1">
            <div className="text-lg font-bold text-gray-900">
              Crear nuevo usuario
            </div>
            <div className="text-xs text-gray-500">
              Solo admins e inspectores. Ciudadanos se auto-registran.
            </div>
          </div>
          <button
            onClick={onClose}
            className="text-gray-400 hover:text-gray-600"
            aria-label="Cerrar"
          >
            <XMarkIcon className="w-6 h-6" />
          </button>
        </div>

        <div className="flex-1 overflow-y-auto p-5 space-y-3">
          {submitError && (
            <div className="px-3 py-2 rounded-lg bg-red-50 text-red-700 text-sm border border-red-200">
              {submitError}
            </div>
          )}
          <Field
            label="Email"
            error={errors.email}
            value={email}
            onChange={(v) => setEmail(v.replace(/\s/g, ''))}
            type="email"
            placeholder="usuario@ejemplo.cl"
          />
          <div className="grid grid-cols-2 gap-3">
            <Field
              label="Nombre"
              error={errors.firstName}
              value={firstName}
              onChange={setFirstName}
              placeholder="Juan"
            />
            <Field
              label="Apellido"
              error={errors.lastName}
              value={lastName}
              onChange={setLastName}
              placeholder="Pérez"
            />
          </div>
          <div className="grid grid-cols-2 gap-3">
            <Field
              label="RUT"
              value={rut}
              onChange={setRut}
              placeholder="12345678-9"
            />
            <Field
              label="Teléfono"
              value={phone}
              onChange={setPhone}
              type="tel"
              placeholder="+56912345678"
            />
          </div>

          {/* Role selector */}
          <div className="p-3 rounded-lg border border-gray-200 bg-gray-50/50">
            <div className="text-xs font-semibold text-gray-600 mb-2">Rol</div>
            <div className="grid grid-cols-2 gap-2">
              {(
                [
                  {
                    value: 'inspector' as const,
                    label: 'Inspector',
                    color: FROGIO_COLORS.info,
                    icon: <IdentificationIcon className="w-4 h-4" />,
                  },
                  {
                    value: 'admin' as const,
                    label: 'Administrador',
                    color: FROGIO_COLORS.emergency,
                    icon: <ShieldCheckIcon className="w-4 h-4" />,
                  },
                ]
              ).map((opt) => {
                const sel = role === opt.value;
                return (
                  <button
                    key={opt.value}
                    type="button"
                    onClick={() => setRole(opt.value)}
                    className="flex items-center justify-center gap-2 px-3 py-2.5 rounded-lg text-sm font-semibold transition-all"
                    style={
                      sel
                        ? {
                            backgroundColor: `${opt.color}1F`,
                            color: opt.color,
                            border: `1.5px solid ${opt.color}`,
                          }
                        : {
                            backgroundColor: '#fff',
                            color: FROGIO_COLORS.textSecondary,
                            border: `1px solid ${FROGIO_COLORS.border}`,
                          }
                    }
                  >
                    {opt.icon}
                    {opt.label}
                  </button>
                );
              })}
            </div>
          </div>

          {/* Password */}
          <div>
            <label className="block text-xs font-semibold text-gray-600 mb-1">
              Contraseña
            </label>
            <div className="relative">
              <input
                type={showPwd ? 'text' : 'password'}
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="Mínimo 8 caracteres"
                className={`w-full pl-3 pr-10 py-2 rounded-lg border text-sm focus:outline-none focus:ring-2 focus:ring-green-500/40 ${
                  errors.password
                    ? 'border-red-300 focus:border-red-500'
                    : 'border-gray-300 focus:border-green-500'
                }`}
              />
              <button
                type="button"
                onClick={() => setShowPwd((v) => !v)}
                className="absolute right-2 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
              >
                {showPwd ? (
                  <EyeSlashIcon className="w-4 h-4" />
                ) : (
                  <EyeIcon className="w-4 h-4" />
                )}
              </button>
            </div>
            {errors.password ? (
              <div className="text-xs text-red-600 mt-1">{errors.password}</div>
            ) : (
              <div className="text-[11px] text-gray-400 mt-1">
                Mínimo 8 caracteres
              </div>
            )}
          </div>
        </div>

        <div className="px-5 py-4 border-t border-gray-100 flex gap-2">
          <button
            onClick={onClose}
            disabled={submitting}
            className="flex-1 px-4 py-2.5 rounded-lg font-semibold text-sm border border-gray-300 text-gray-700 hover:bg-gray-50 disabled:opacity-50"
          >
            Cancelar
          </button>
          <button
            onClick={submit}
            disabled={submitting}
            className="flex-1 px-4 py-2.5 rounded-lg font-semibold text-sm text-white disabled:opacity-50 inline-flex items-center justify-center gap-2"
            style={{
              background: `linear-gradient(135deg, ${FROGIO_COLORS.primaryDark}, ${FROGIO_COLORS.primary})`,
            }}
          >
            {submitting ? (
              <>
                <ArrowPathIcon className="w-4 h-4 animate-spin" />
                Creando...
              </>
            ) : (
              <>
                <PlusIcon className="w-4 h-4" />
                Crear usuario
              </>
            )}
          </button>
        </div>
      </motion.div>
    </motion.div>
  );
}

function Field({
  label,
  error,
  value,
  onChange,
  type = 'text',
  placeholder,
}: {
  label: string;
  error?: string;
  value: string;
  onChange: (v: string) => void;
  type?: string;
  placeholder?: string;
}) {
  return (
    <div>
      <label className="block text-xs font-semibold text-gray-600 mb-1">
        {label}
      </label>
      <input
        type={type}
        value={value}
        onChange={(e) => onChange(e.target.value)}
        placeholder={placeholder}
        className={`w-full px-3 py-2 rounded-lg border text-sm focus:outline-none focus:ring-2 focus:ring-green-500/40 ${
          error
            ? 'border-red-300 focus:border-red-500'
            : 'border-gray-300 focus:border-green-500'
        }`}
      />
      {error && <div className="text-xs text-red-600 mt-1">{error}</div>}
    </div>
  );
}

