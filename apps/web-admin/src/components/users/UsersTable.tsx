'use client';

import { useState } from 'react';
import { PencilIcon, TrashIcon, CheckCircleIcon, XCircleIcon, KeyIcon, XMarkIcon } from '@heroicons/react/24/outline';
import { useRouter } from 'next/navigation';

interface User {
  id: string;
  email: string;
  first_name: string;
  last_name: string;
  rut: string;
  phone: string | null;
  role: string;
  is_active: boolean;
  email_verified: boolean;
  created_at: string;
}

interface UsersTableProps {
  users: User[];
}

export default function UsersTable({ users }: UsersTableProps) {
  const router = useRouter();
  const [isDeleting, setIsDeleting] = useState<string | null>(null);
  const [isToggling, setIsToggling] = useState<string | null>(null);
  const [pwdModalUser, setPwdModalUser] = useState<User | null>(null);
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [isSavingPassword, setIsSavingPassword] = useState(false);
  const [passwordError, setPasswordError] = useState('');

  const handleEdit = (userId: string) => {
    router.push(`/users/${userId}/edit`);
  };

  const handleDelete = async (userId: string, userName: string) => {
    if (!confirm(`¿Estás seguro de eliminar al usuario ${userName}?`)) {
      return;
    }

    setIsDeleting(userId);
    try {
      const response = await fetch(`/api/users/${userId}`, {
        method: 'DELETE',
      });

      if (response.ok) {
        router.refresh();
      } else {
        alert('Error al eliminar el usuario');
      }
    } catch (error) {
      console.error('Error deleting user:', error);
      alert('Error al eliminar el usuario');
    } finally {
      setIsDeleting(null);
    }
  };

  const openPasswordModal = (user: User) => {
    setPwdModalUser(user);
    setNewPassword('');
    setConfirmPassword('');
    setPasswordError('');
  };

  const handleSavePassword = async () => {
    if (!pwdModalUser) return;
    setPasswordError('');

    if (!newPassword || newPassword.length < 8) {
      setPasswordError('La contraseña debe tener al menos 8 caracteres');
      return;
    }
    if (newPassword !== confirmPassword) {
      setPasswordError('Las contraseñas no coinciden');
      return;
    }

    try {
      setIsSavingPassword(true);
      const response = await fetch(`/api/users/${pwdModalUser.id}/password`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ password: newPassword }),
      });
      if (!response.ok) {
        const data = await response.json().catch(() => ({ error: 'Error al actualizar contraseña' }));
        throw new Error(data.error || 'Error al actualizar contraseña');
      }
      setPwdModalUser(null);
      router.refresh();
    } catch (err: any) {
      setPasswordError(err.message || 'Error al actualizar contraseña');
    } finally {
      setIsSavingPassword(false);
    }
  };

  const handleToggleActive = async (userId: string, currentStatus: boolean) => {
    setIsToggling(userId);
    try {
      const response = await fetch(`/api/users/${userId}/toggle-status`, {
        method: 'PATCH',
      });

      if (response.ok) {
        router.refresh();
      } else {
        alert('Error al cambiar el estado del usuario');
      }
    } catch (error) {
      console.error('Error toggling user status:', error);
      alert('Error al cambiar el estado del usuario');
    } finally {
      setIsToggling(null);
    }
  };

  if (users.length === 0) {
    return (
      <div className="bg-white shadow rounded-lg">
        <div className="px-6 py-12 text-center">
          <p className="text-gray-500 text-lg">No hay usuarios registrados</p>
          <p className="text-gray-400 text-sm mt-2">Crea el primer usuario usando el botón "Nuevo Usuario"</p>
        </div>
      </div>
    );
  }

  return (
    <div className="bg-white shadow rounded-lg overflow-hidden">
      <div className="overflow-x-auto">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Nombre
              </th>
              <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Email
              </th>
              <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                RUT
              </th>
              <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Teléfono
              </th>
              <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Rol
              </th>
              <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Estado
              </th>
              <th scope="col" className="px-6 py-3 text-center text-xs font-medium text-gray-500 uppercase tracking-wider">
                Email Verificado
              </th>
              <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Registrado
              </th>
              <th scope="col" className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                Acciones
              </th>
            </tr>
          </thead>
          <tbody className="bg-white divide-y divide-gray-200">
            {users.map((user) => (
              <tr key={user.id} className="hover:bg-gray-50">
                <td className="px-6 py-4 whitespace-nowrap">
                  <div className="text-sm font-medium text-gray-900">
                    {user.first_name} {user.last_name}
                  </div>
                </td>
                <td className="px-6 py-4 whitespace-nowrap">
                  <div className="text-sm text-gray-500">{user.email}</div>
                </td>
                <td className="px-6 py-4 whitespace-nowrap">
                  <div className="text-sm text-gray-500">{user.rut}</div>
                </td>
                <td className="px-6 py-4 whitespace-nowrap">
                  <div className="text-sm text-gray-500">{user.phone || '-'}</div>
                </td>
                <td className="px-6 py-4 whitespace-nowrap">
                  <RoleBadge role={user.role} />
                </td>
                <td className="px-6 py-4 whitespace-nowrap">
                  <button
                    onClick={() => handleToggleActive(user.id, user.is_active)}
                    disabled={isToggling === user.id}
                    className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium transition-colors ${
                      user.is_active
                        ? 'bg-green-100 text-green-800 hover:bg-green-200'
                        : 'bg-gray-100 text-gray-800 hover:bg-gray-200'
                    } ${isToggling === user.id ? 'opacity-50 cursor-not-allowed' : 'cursor-pointer'}`}
                  >
                    {user.is_active ? 'Activo' : 'Inactivo'}
                  </button>
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-center">
                  {user.email_verified ? (
                    <CheckCircleIcon className="h-5 w-5 text-green-500 inline" />
                  ) : (
                    <XCircleIcon className="h-5 w-5 text-gray-400 inline" />
                  )}
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                  {new Date(user.created_at).toLocaleDateString('es-CL')}
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                  <div className="flex items-center justify-end gap-2">
                    <button
                      onClick={() => openPasswordModal(user)}
                      className="text-amber-600 hover:text-amber-800 p-1 rounded hover:bg-amber-50 transition-colors"
                      title="Cambiar contraseña"
                    >
                      <KeyIcon className="h-5 w-5" />
                    </button>
                    <button
                      onClick={() => handleEdit(user.id)}
                      className="text-indigo-600 hover:text-indigo-900 p-1 rounded hover:bg-indigo-50 transition-colors"
                      title="Editar usuario"
                    >
                      <PencilIcon className="h-5 w-5" />
                    </button>
                    <button
                      onClick={() => handleDelete(user.id, `${user.first_name} ${user.last_name}`)}
                      disabled={isDeleting === user.id}
                      className="text-red-600 hover:text-red-900 p-1 rounded hover:bg-red-50 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                      title="Eliminar usuario"
                    >
                      <TrashIcon className="h-5 w-5" />
                    </button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Password Modal */}
      {pwdModalUser && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
          <div className="w-full max-w-md bg-white rounded-lg shadow-xl">
            <div className="flex items-center justify-between px-5 py-4 border-b">
              <h3 className="text-base font-semibold text-gray-900">Cambiar contraseña</h3>
              <button
                className="p-1 rounded hover:bg-gray-100"
                onClick={() => setPwdModalUser(null)}
              >
                <XMarkIcon className="h-5 w-5 text-gray-500" />
              </button>
            </div>
            <div className="px-5 py-4 space-y-3">
              <p className="text-sm text-gray-600">Usuario: <span className="font-medium">{pwdModalUser.first_name} {pwdModalUser.last_name}</span> ({pwdModalUser.email})</p>
              {passwordError && (
                <div className="text-sm text-red-600 bg-red-50 border border-red-200 rounded p-2">{passwordError}</div>
              )}
              <div>
                <label className="block text-sm font-medium text-gray-700">Nueva contraseña</label>
                <input
                  type="password"
                  value={newPassword}
                  onChange={(e) => setNewPassword(e.target.value)}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                  placeholder="Mínimo 8 caracteres"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700">Confirmar contraseña</label>
                <input
                  type="password"
                  value={confirmPassword}
                  onChange={(e) => setConfirmPassword(e.target.value)}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                />
              </div>
            </div>
            <div className="px-5 py-4 border-t flex items-center justify-end gap-2">
              <button
                className="px-4 py-2 text-sm font-medium text-gray-700 bg-gray-100 hover:bg-gray-200 rounded-lg transition-colors"
                onClick={() => setPwdModalUser(null)}
                disabled={isSavingPassword}
              >
                Cancelar
              </button>
              <button
                className="px-4 py-2 text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 rounded-lg transition-colors disabled:opacity-50"
                onClick={handleSavePassword}
                disabled={isSavingPassword}
              >
                {isSavingPassword ? 'Guardando...' : 'Guardar'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

function RoleBadge({ role }: { role: string }) {
  const colors: Record<string, string> = {
    citizen: 'bg-blue-100 text-blue-800',
    inspector: 'bg-purple-100 text-purple-800',
    admin: 'bg-red-100 text-red-800',
  };

  const labels: Record<string, string> = {
    citizen: 'Ciudadano',
    inspector: 'Inspector',
    admin: 'Administrador',
  };

  return (
    <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${colors[role] || 'bg-gray-100 text-gray-800'}`}>
      {labels[role] || role}
    </span>
  );
}
