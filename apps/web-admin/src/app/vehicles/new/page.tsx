'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';

export default function NewVehiclePage() {
  const router = useRouter();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const [formData, setFormData] = useState({
    plate: '',
    brand: '',
    model: '',
    year: '',
    color: '',
    vehicleType: '',
    ownerFirstName: '',
    ownerLastName: '',
    ownerRut: '',
    ownerPhone: '',
    ownerEmail: '',
    ownerAddress: '',
  });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    try {
      const response = await fetch('/api/vehicles/create', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          ...formData,
          year: parseInt(formData.year),
        }),
      });

      if (!response.ok) {
        const data = await response.json();
        throw new Error(data.error || 'Error al registrar el vehículo');
      }

      router.push('/vehicles');
      router.refresh();
    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value,
    });
  };

  return (
    <div className="min-h-screen bg-gray-100">
      <header className="bg-white shadow">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
          <Link href="/vehicles" className="text-sm text-gray-600 hover:text-gray-900">
            ← Volver a Vehículos
          </Link>
          <h1 className="text-2xl font-bold text-gray-900 mt-2">Registrar Nuevo Vehículo</h1>
        </div>
      </header>

      <main className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="bg-white shadow rounded-lg p-6">
          {error && (
            <div className="mb-4 rounded-md bg-red-50 p-4">
              <p className="text-sm text-red-800">{error}</p>
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-8">
            {/* Datos del Vehículo */}
            <div>
              <h3 className="text-lg font-medium text-gray-900 mb-4">Datos del Vehículo</h3>
              <div className="grid grid-cols-1 gap-6 sm:grid-cols-2">
                <div>
                  <label htmlFor="plate" className="block text-sm font-medium text-gray-700">
                    Patente *
                  </label>
                  <input
                    type="text"
                    id="plate"
                    name="plate"
                    required
                    placeholder="ABCD12"
                    value={formData.plate}
                    onChange={handleChange}
                    className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-indigo-500 uppercase"
                  />
                </div>

                <div>
                  <label htmlFor="vehicleType" className="block text-sm font-medium text-gray-700">
                    Tipo de Vehículo *
                  </label>
                  <select
                    id="vehicleType"
                    name="vehicleType"
                    required
                    value={formData.vehicleType}
                    onChange={handleChange}
                    className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-indigo-500"
                  >
                    <option value="">Seleccione un tipo</option>
                    <option value="automovil">Automóvil</option>
                    <option value="camioneta">Camioneta</option>
                    <option value="motocicleta">Motocicleta</option>
                    <option value="camion">Camión</option>
                    <option value="bus">Bus</option>
                    <option value="otro">Otro</option>
                  </select>
                </div>

                <div>
                  <label htmlFor="brand" className="block text-sm font-medium text-gray-700">
                    Marca *
                  </label>
                  <input
                    type="text"
                    id="brand"
                    name="brand"
                    required
                    placeholder="Toyota"
                    value={formData.brand}
                    onChange={handleChange}
                    className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-indigo-500"
                  />
                </div>

                <div>
                  <label htmlFor="model" className="block text-sm font-medium text-gray-700">
                    Modelo *
                  </label>
                  <input
                    type="text"
                    id="model"
                    name="model"
                    required
                    placeholder="Corolla"
                    value={formData.model}
                    onChange={handleChange}
                    className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-indigo-500"
                  />
                </div>

                <div>
                  <label htmlFor="year" className="block text-sm font-medium text-gray-700">
                    Año *
                  </label>
                  <input
                    type="number"
                    id="year"
                    name="year"
                    required
                    min="1900"
                    max="2030"
                    placeholder="2020"
                    value={formData.year}
                    onChange={handleChange}
                    className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-indigo-500"
                  />
                </div>

                <div>
                  <label htmlFor="color" className="block text-sm font-medium text-gray-700">
                    Color *
                  </label>
                  <input
                    type="text"
                    id="color"
                    name="color"
                    required
                    placeholder="Blanco"
                    value={formData.color}
                    onChange={handleChange}
                    className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-indigo-500"
                  />
                </div>
              </div>
            </div>

            {/* Datos del Propietario */}
            <div className="border-t pt-6">
              <h3 className="text-lg font-medium text-gray-900 mb-4">Datos del Propietario</h3>
              <div className="grid grid-cols-1 gap-6 sm:grid-cols-2">
                <div>
                  <label htmlFor="ownerFirstName" className="block text-sm font-medium text-gray-700">
                    Nombres *
                  </label>
                  <input
                    type="text"
                    id="ownerFirstName"
                    name="ownerFirstName"
                    required
                    value={formData.ownerFirstName}
                    onChange={handleChange}
                    className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-indigo-500"
                  />
                </div>

                <div>
                  <label htmlFor="ownerLastName" className="block text-sm font-medium text-gray-700">
                    Apellidos *
                  </label>
                  <input
                    type="text"
                    id="ownerLastName"
                    name="ownerLastName"
                    required
                    value={formData.ownerLastName}
                    onChange={handleChange}
                    className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-indigo-500"
                  />
                </div>

                <div>
                  <label htmlFor="ownerRut" className="block text-sm font-medium text-gray-700">
                    RUT *
                  </label>
                  <input
                    type="text"
                    id="ownerRut"
                    name="ownerRut"
                    required
                    placeholder="12345678-9"
                    value={formData.ownerRut}
                    onChange={handleChange}
                    className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-indigo-500"
                  />
                </div>

                <div>
                  <label htmlFor="ownerPhone" className="block text-sm font-medium text-gray-700">
                    Teléfono *
                  </label>
                  <input
                    type="tel"
                    id="ownerPhone"
                    name="ownerPhone"
                    required
                    placeholder="+56912345678"
                    value={formData.ownerPhone}
                    onChange={handleChange}
                    className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-indigo-500"
                  />
                </div>

                <div>
                  <label htmlFor="ownerEmail" className="block text-sm font-medium text-gray-700">
                    Email *
                  </label>
                  <input
                    type="email"
                    id="ownerEmail"
                    name="ownerEmail"
                    required
                    placeholder="correo@ejemplo.cl"
                    value={formData.ownerEmail}
                    onChange={handleChange}
                    className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-indigo-500"
                  />
                </div>

                <div>
                  <label htmlFor="ownerAddress" className="block text-sm font-medium text-gray-700">
                    Dirección *
                  </label>
                  <input
                    type="text"
                    id="ownerAddress"
                    name="ownerAddress"
                    required
                    value={formData.ownerAddress}
                    onChange={handleChange}
                    className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-indigo-500"
                  />
                </div>
              </div>
            </div>

            <div className="flex gap-3 pt-4">
              <button
                type="submit"
                disabled={loading}
                className="flex-1 bg-indigo-600 text-white px-4 py-2 rounded-md hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 disabled:opacity-50"
              >
                {loading ? 'Registrando...' : 'Registrar Vehículo'}
              </button>
              <Link
                href="/vehicles"
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
