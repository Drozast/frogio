'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';

export default function NewCitationPage() {
  const router = useRouter();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const [formData, setFormData] = useState({
    citationNumber: '',
    courtName: '',
    hearingDate: '',
    hearingTime: '',
    address: '',
    details: '',
    userId: '',
    infractionId: '',
  });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    try {
      const response = await fetch('/api/citations/create', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          ...formData,
          infractionId: formData.infractionId || null,
        }),
      });

      if (!response.ok) {
        const data = await response.json();
        throw new Error(data.error || 'Error al crear la citación');
      }

      router.push('/citations');
      router.refresh();
    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value,
    });
  };

  return (
    <div className="min-h-screen bg-gray-100">
      <header className="bg-white shadow">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
          <Link href="/citations" className="text-sm text-gray-600 hover:text-gray-900">
            ← Volver a Citaciones
          </Link>
          <h1 className="text-2xl font-bold text-gray-900 mt-2">Crear Nueva Citación</h1>
        </div>
      </header>

      <main className="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="bg-white shadow rounded-lg p-6">
          {error && (
            <div className="mb-4 rounded-md bg-red-50 p-4">
              <p className="text-sm text-red-800">{error}</p>
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-6">
            <div>
              <label htmlFor="citationNumber" className="block text-sm font-medium text-gray-700">
                Número de Citación *
              </label>
              <input
                type="text"
                id="citationNumber"
                name="citationNumber"
                required
                placeholder="CIT-2025-001"
                value={formData.citationNumber}
                onChange={handleChange}
                className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-indigo-500"
              />
            </div>

            <div>
              <label htmlFor="courtName" className="block text-sm font-medium text-gray-700">
                Nombre del Tribunal *
              </label>
              <input
                type="text"
                id="courtName"
                name="courtName"
                required
                placeholder="Juzgado de Policía Local"
                value={formData.courtName}
                onChange={handleChange}
                className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-indigo-500"
              />
            </div>

            <div className="grid grid-cols-1 gap-6 sm:grid-cols-2">
              <div>
                <label htmlFor="hearingDate" className="block text-sm font-medium text-gray-700">
                  Fecha de Audiencia *
                </label>
                <input
                  type="date"
                  id="hearingDate"
                  name="hearingDate"
                  required
                  value={formData.hearingDate}
                  onChange={handleChange}
                  className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-indigo-500"
                />
              </div>

              <div>
                <label htmlFor="hearingTime" className="block text-sm font-medium text-gray-700">
                  Hora de Audiencia *
                </label>
                <input
                  type="time"
                  id="hearingTime"
                  name="hearingTime"
                  required
                  value={formData.hearingTime}
                  onChange={handleChange}
                  className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-indigo-500"
                />
              </div>
            </div>

            <div>
              <label htmlFor="address" className="block text-sm font-medium text-gray-700">
                Dirección del Tribunal *
              </label>
              <input
                type="text"
                id="address"
                name="address"
                required
                placeholder="Av. Principal 123"
                value={formData.address}
                onChange={handleChange}
                className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-indigo-500"
              />
            </div>

            <div>
              <label htmlFor="userId" className="block text-sm font-medium text-gray-700">
                ID del Usuario *
              </label>
              <input
                type="text"
                id="userId"
                name="userId"
                required
                placeholder="UUID del usuario"
                value={formData.userId}
                onChange={handleChange}
                className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-indigo-500"
              />
              <p className="mt-1 text-sm text-gray-500">UUID del usuario citado</p>
            </div>

            <div>
              <label htmlFor="infractionId" className="block text-sm font-medium text-gray-700">
                ID de Infracción (opcional)
              </label>
              <input
                type="text"
                id="infractionId"
                name="infractionId"
                placeholder="UUID de la infracción relacionada"
                value={formData.infractionId}
                onChange={handleChange}
                className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-indigo-500"
              />
            </div>

            <div>
              <label htmlFor="details" className="block text-sm font-medium text-gray-700">
                Detalles Adicionales
              </label>
              <textarea
                id="details"
                name="details"
                rows={3}
                value={formData.details}
                onChange={handleChange}
                className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-indigo-500"
              />
            </div>

            <div className="flex gap-3">
              <button
                type="submit"
                disabled={loading}
                className="flex-1 bg-indigo-600 text-white px-4 py-2 rounded-md hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 disabled:opacity-50"
              >
                {loading ? 'Creando...' : 'Crear Citación'}
              </button>
              <Link
                href="/citations"
                className="flex-1 bg-gray-200 text-gray-700 px-4 py-2 rounded-md hover:bg-gray-300 focus:outline-none focus:ring-2 focus:ring-gray-500 focus:ring-offset-2 text-center"
              >
                Cancelar
              </Link>
            </div>
          </form>
        </div>
      </main>
    </div>
  );
}
