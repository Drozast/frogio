'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';

export default function NewMedicalRecordPage() {
  const router = useRouter();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const [formData, setFormData] = useState({
    householdHeadFirstName: '',
    householdHeadLastName: '',
    householdHeadRut: '',
    address: '',
    phone: '',
    email: '',
    bloodType: '',
    allergies: '',
    chronicConditions: '',
    currentMedications: '',
    emergencyContact: '',
  });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    try {
      const response = await fetch('/api/medical-records/create', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(formData),
      });

      if (!response.ok) {
        const data = await response.json();
        throw new Error(data.error || 'Error al crear la ficha médica');
      }

      router.push('/medical-records');
      router.refresh();
    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value,
    });
  };

  return (
    <div className="min-h-screen bg-gray-100">
      <header className="bg-white shadow">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
          <Link href="/medical-records" className="text-sm text-gray-600 hover:text-gray-900">
            ← Volver a Fichas Médicas
          </Link>
          <h1 className="text-2xl font-bold text-gray-900 mt-2">Crear Nueva Ficha Médica</h1>
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
            {/* Datos del Jefe de Hogar */}
            <div>
              <h3 className="text-lg font-medium text-gray-900 mb-4">Datos del Jefe de Hogar</h3>
              <div className="grid grid-cols-1 gap-6 sm:grid-cols-2">
                <div>
                  <label htmlFor="householdHeadFirstName" className="block text-sm font-medium text-gray-700">
                    Nombres *
                  </label>
                  <input
                    type="text"
                    id="householdHeadFirstName"
                    name="householdHeadFirstName"
                    required
                    value={formData.householdHeadFirstName}
                    onChange={handleChange}
                    className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-indigo-500"
                  />
                </div>

                <div>
                  <label htmlFor="householdHeadLastName" className="block text-sm font-medium text-gray-700">
                    Apellidos *
                  </label>
                  <input
                    type="text"
                    id="householdHeadLastName"
                    name="householdHeadLastName"
                    required
                    value={formData.householdHeadLastName}
                    onChange={handleChange}
                    className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-indigo-500"
                  />
                </div>

                <div>
                  <label htmlFor="householdHeadRut" className="block text-sm font-medium text-gray-700">
                    RUT *
                  </label>
                  <input
                    type="text"
                    id="householdHeadRut"
                    name="householdHeadRut"
                    required
                    placeholder="12345678-9"
                    value={formData.householdHeadRut}
                    onChange={handleChange}
                    className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-indigo-500"
                  />
                </div>

                <div>
                  <label htmlFor="bloodType" className="block text-sm font-medium text-gray-700">
                    Grupo Sanguíneo
                  </label>
                  <select
                    id="bloodType"
                    name="bloodType"
                    value={formData.bloodType}
                    onChange={handleChange}
                    className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-indigo-500"
                  >
                    <option value="">Seleccione</option>
                    <option value="A+">A+</option>
                    <option value="A-">A-</option>
                    <option value="B+">B+</option>
                    <option value="B-">B-</option>
                    <option value="AB+">AB+</option>
                    <option value="AB-">AB-</option>
                    <option value="O+">O+</option>
                    <option value="O-">O-</option>
                  </select>
                </div>
              </div>
            </div>

            {/* Datos de Contacto */}
            <div className="border-t pt-6">
              <h3 className="text-lg font-medium text-gray-900 mb-4">Datos de Contacto</h3>
              <div className="grid grid-cols-1 gap-6">
                <div>
                  <label htmlFor="address" className="block text-sm font-medium text-gray-700">
                    Dirección *
                  </label>
                  <input
                    type="text"
                    id="address"
                    name="address"
                    required
                    value={formData.address}
                    onChange={handleChange}
                    className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-indigo-500"
                  />
                </div>

                <div className="grid grid-cols-1 gap-6 sm:grid-cols-2">
                  <div>
                    <label htmlFor="phone" className="block text-sm font-medium text-gray-700">
                      Teléfono *
                    </label>
                    <input
                      type="tel"
                      id="phone"
                      name="phone"
                      required
                      placeholder="+56912345678"
                      value={formData.phone}
                      onChange={handleChange}
                      className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-indigo-500"
                    />
                  </div>

                  <div>
                    <label htmlFor="email" className="block text-sm font-medium text-gray-700">
                      Email
                    </label>
                    <input
                      type="email"
                      id="email"
                      name="email"
                      placeholder="correo@ejemplo.cl"
                      value={formData.email}
                      onChange={handleChange}
                      className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-indigo-500"
                    />
                  </div>
                </div>

                <div>
                  <label htmlFor="emergencyContact" className="block text-sm font-medium text-gray-700">
                    Contacto de Emergencia
                  </label>
                  <input
                    type="text"
                    id="emergencyContact"
                    name="emergencyContact"
                    placeholder="Nombre y teléfono"
                    value={formData.emergencyContact}
                    onChange={handleChange}
                    className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-indigo-500"
                  />
                </div>
              </div>
            </div>

            {/* Información Médica */}
            <div className="border-t pt-6">
              <h3 className="text-lg font-medium text-gray-900 mb-4">Información Médica</h3>
              <div className="space-y-6">
                <div>
                  <label htmlFor="allergies" className="block text-sm font-medium text-gray-700">
                    Alergias
                  </label>
                  <textarea
                    id="allergies"
                    name="allergies"
                    rows={2}
                    placeholder="Listar alergias conocidas"
                    value={formData.allergies}
                    onChange={handleChange}
                    className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-indigo-500"
                  />
                </div>

                <div>
                  <label htmlFor="chronicConditions" className="block text-sm font-medium text-gray-700">
                    Condiciones Crónicas
                  </label>
                  <textarea
                    id="chronicConditions"
                    name="chronicConditions"
                    rows={2}
                    placeholder="Diabetes, hipertensión, etc."
                    value={formData.chronicConditions}
                    onChange={handleChange}
                    className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-indigo-500"
                  />
                </div>

                <div>
                  <label htmlFor="currentMedications" className="block text-sm font-medium text-gray-700">
                    Medicamentos Actuales
                  </label>
                  <textarea
                    id="currentMedications"
                    name="currentMedications"
                    rows={2}
                    placeholder="Listar medicamentos que toma regularmente"
                    value={formData.currentMedications}
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
                {loading ? 'Creando...' : 'Crear Ficha Médica'}
              </button>
              <Link
                href="/medical-records"
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
