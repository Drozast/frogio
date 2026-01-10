'use client';

import { useState, useRef } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import dynamic from 'next/dynamic';
import AppLayout from '@/components/layout/AppLayout';
import {
  ArrowLeftIcon,
  UserIcon,
  HomeIcon,
  TruckIcon,
  BuildingStorefrontIcon,
  QuestionMarkCircleIcon,
  MapPinIcon,
  CameraIcon,
  XMarkIcon,
  ExclamationTriangleIcon,
  DocumentTextIcon,
  ArrowPathIcon,
} from '@heroicons/react/24/outline';

// Dynamic import to avoid SSR issues with Leaflet
const LocationPicker = dynamic(() => import('@/components/LocationPicker'), {
  ssr: false,
  loading: () => (
    <div className="w-full h-64 bg-gray-100 rounded-lg flex items-center justify-center">
      <div className="flex items-center gap-2 text-gray-500">
        <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-indigo-600"></div>
        <span>Cargando mapa...</span>
      </div>
    </div>
  ),
});

type CitationType = 'advertencia' | 'citacion';
type TargetType = 'persona' | 'domicilio' | 'vehiculo' | 'comercio' | 'otro';

const citationTypeOptions = [
  { value: 'advertencia', label: 'Advertencia', description: 'Notificación preventiva sin consecuencias legales inmediatas', icon: ExclamationTriangleIcon },
  { value: 'citacion', label: 'Citación', description: 'Citación formal con comparecencia obligatoria', icon: DocumentTextIcon },
];

const targetTypeOptions = [
  { value: 'persona', label: 'Persona', icon: UserIcon },
  { value: 'domicilio', label: 'Domicilio', icon: HomeIcon },
  { value: 'vehiculo', label: 'Vehículo', icon: TruckIcon },
  { value: 'comercio', label: 'Comercio', icon: BuildingStorefrontIcon },
  { value: 'otro', label: 'Otro', icon: QuestionMarkCircleIcon },
];

export default function NewCitationPage() {
  const router = useRouter();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const fileInputRef = useRef<HTMLInputElement>(null);

  const [formData, setFormData] = useState({
    citationType: 'citacion' as CitationType,
    targetType: 'persona' as TargetType,
    targetName: '',
    targetRut: '',
    targetAddress: '',
    targetPhone: '',
    targetPlate: '',
    locationAddress: '',
    latitude: null as number | null,
    longitude: null as number | null,
    citationNumber: '',
    reason: '',
    notes: '',
    photos: [] as string[],
  });

  const [previewPhotos, setPreviewPhotos] = useState<string[]>([]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');

    if (!formData.citationNumber.trim()) {
      setError('Debe ingresar el número de notificación según la papeleta');
      return;
    }

    setLoading(true);

    try {
      const payload = {
        ...formData,
        latitude: formData.latitude,
        longitude: formData.longitude,
      };

      const response = await fetch('/api/citations', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      });

      if (!response.ok) {
        const data = await response.json();
        throw new Error(data.error || 'Error al crear la citación');
      }

      router.push('/citations');
      router.refresh();
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : 'Error desconocido';
      setError(message);
    } finally {
      setLoading(false);
    }
  };

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
  };

  const handleLocationChange = (lat: number, lng: number, address?: string) => {
    setFormData(prev => ({
      ...prev,
      latitude: lat === 0 ? null : lat,
      longitude: lng === 0 ? null : lng,
      ...(address ? { locationAddress: address } : {}),
    }));
  };

  const handleLocationAddressChange = (address: string) => {
    setFormData(prev => ({
      ...prev,
      locationAddress: address,
    }));
  };

  const handleReuseTargetAddress = () => {
    if (formData.targetAddress) {
      setFormData(prev => ({
        ...prev,
        locationAddress: prev.targetAddress,
      }));
    }
  };

  const handlePhotoSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = e.target.files;
    if (!files) return;

    Array.from(files).forEach(file => {
      const reader = new FileReader();
      reader.onloadend = () => {
        const base64 = reader.result as string;
        setPreviewPhotos(prev => [...prev, base64]);
        setFormData(prev => ({
          ...prev,
          photos: [...prev.photos, base64],
        }));
      };
      reader.readAsDataURL(file);
    });
  };

  const removePhoto = (index: number) => {
    setPreviewPhotos(prev => prev.filter((_, i) => i !== index));
    setFormData(prev => ({
      ...prev,
      photos: prev.photos.filter((_, i) => i !== index),
    }));
  };

  const getTargetFields = () => {
    switch (formData.targetType) {
      case 'persona':
        return (
          <>
            <div>
              <label htmlFor="targetName" className="block text-sm font-medium text-gray-700">
                Nombre Completo *
              </label>
              <input
                type="text"
                id="targetName"
                name="targetName"
                required
                value={formData.targetName}
                onChange={handleChange}
                className="mt-1 block w-full rounded-lg border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
              />
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label htmlFor="targetRut" className="block text-sm font-medium text-gray-700">
                  RUT
                </label>
                <input
                  type="text"
                  id="targetRut"
                  name="targetRut"
                  placeholder="12.345.678-9"
                  value={formData.targetRut}
                  onChange={handleChange}
                  className="mt-1 block w-full rounded-lg border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                />
              </div>
              <div>
                <label htmlFor="targetPhone" className="block text-sm font-medium text-gray-700">
                  Teléfono
                </label>
                <input
                  type="tel"
                  id="targetPhone"
                  name="targetPhone"
                  placeholder="+56 9 1234 5678"
                  value={formData.targetPhone}
                  onChange={handleChange}
                  className="mt-1 block w-full rounded-lg border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                />
              </div>
            </div>
            <div>
              <label htmlFor="targetAddress" className="block text-sm font-medium text-gray-700">
                Dirección del Domicilio
              </label>
              <input
                type="text"
                id="targetAddress"
                name="targetAddress"
                value={formData.targetAddress}
                onChange={handleChange}
                className="mt-1 block w-full rounded-lg border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
              />
            </div>
          </>
        );
      case 'vehiculo':
        return (
          <>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label htmlFor="targetPlate" className="block text-sm font-medium text-gray-700">
                  Patente *
                </label>
                <input
                  type="text"
                  id="targetPlate"
                  name="targetPlate"
                  required
                  placeholder="ABCD-12"
                  value={formData.targetPlate}
                  onChange={handleChange}
                  className="mt-1 block w-full rounded-lg border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 uppercase"
                />
              </div>
              <div>
                <label htmlFor="targetName" className="block text-sm font-medium text-gray-700">
                  Propietario (si se conoce)
                </label>
                <input
                  type="text"
                  id="targetName"
                  name="targetName"
                  value={formData.targetName}
                  onChange={handleChange}
                  className="mt-1 block w-full rounded-lg border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                />
              </div>
            </div>
            <div>
              <label htmlFor="targetRut" className="block text-sm font-medium text-gray-700">
                RUT Propietario
              </label>
              <input
                type="text"
                id="targetRut"
                name="targetRut"
                placeholder="12.345.678-9"
                value={formData.targetRut}
                onChange={handleChange}
                className="mt-1 block w-full rounded-lg border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
              />
            </div>
          </>
        );
      case 'domicilio':
        return (
          <>
            <div>
              <label htmlFor="targetAddress" className="block text-sm font-medium text-gray-700">
                Dirección del Domicilio *
              </label>
              <input
                type="text"
                id="targetAddress"
                name="targetAddress"
                required
                value={formData.targetAddress}
                onChange={handleChange}
                className="mt-1 block w-full rounded-lg border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
              />
            </div>
            <div>
              <label htmlFor="targetName" className="block text-sm font-medium text-gray-700">
                Responsable / Propietario
              </label>
              <input
                type="text"
                id="targetName"
                name="targetName"
                value={formData.targetName}
                onChange={handleChange}
                className="mt-1 block w-full rounded-lg border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
              />
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label htmlFor="targetRut" className="block text-sm font-medium text-gray-700">
                  RUT
                </label>
                <input
                  type="text"
                  id="targetRut"
                  name="targetRut"
                  placeholder="12.345.678-9"
                  value={formData.targetRut}
                  onChange={handleChange}
                  className="mt-1 block w-full rounded-lg border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                />
              </div>
              <div>
                <label htmlFor="targetPhone" className="block text-sm font-medium text-gray-700">
                  Teléfono
                </label>
                <input
                  type="tel"
                  id="targetPhone"
                  name="targetPhone"
                  value={formData.targetPhone}
                  onChange={handleChange}
                  className="mt-1 block w-full rounded-lg border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                />
              </div>
            </div>
          </>
        );
      case 'comercio':
        return (
          <>
            <div>
              <label htmlFor="targetName" className="block text-sm font-medium text-gray-700">
                Nombre del Comercio *
              </label>
              <input
                type="text"
                id="targetName"
                name="targetName"
                required
                value={formData.targetName}
                onChange={handleChange}
                className="mt-1 block w-full rounded-lg border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
              />
            </div>
            <div>
              <label htmlFor="targetAddress" className="block text-sm font-medium text-gray-700">
                Dirección del Comercio *
              </label>
              <input
                type="text"
                id="targetAddress"
                name="targetAddress"
                required
                value={formData.targetAddress}
                onChange={handleChange}
                className="mt-1 block w-full rounded-lg border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
              />
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label htmlFor="targetRut" className="block text-sm font-medium text-gray-700">
                  RUT Comercio
                </label>
                <input
                  type="text"
                  id="targetRut"
                  name="targetRut"
                  placeholder="76.123.456-7"
                  value={formData.targetRut}
                  onChange={handleChange}
                  className="mt-1 block w-full rounded-lg border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                />
              </div>
              <div>
                <label htmlFor="targetPhone" className="block text-sm font-medium text-gray-700">
                  Teléfono
                </label>
                <input
                  type="tel"
                  id="targetPhone"
                  name="targetPhone"
                  value={formData.targetPhone}
                  onChange={handleChange}
                  className="mt-1 block w-full rounded-lg border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                />
              </div>
            </div>
          </>
        );
      default:
        return (
          <>
            <div>
              <label htmlFor="targetName" className="block text-sm font-medium text-gray-700">
                Descripción / Identificación *
              </label>
              <input
                type="text"
                id="targetName"
                name="targetName"
                required
                value={formData.targetName}
                onChange={handleChange}
                className="mt-1 block w-full rounded-lg border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
              />
            </div>
            <div>
              <label htmlFor="targetAddress" className="block text-sm font-medium text-gray-700">
                Dirección (si aplica)
              </label>
              <input
                type="text"
                id="targetAddress"
                name="targetAddress"
                value={formData.targetAddress}
                onChange={handleChange}
                className="mt-1 block w-full rounded-lg border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
              />
            </div>
          </>
        );
    }
  };

  return (
    <AppLayout>
      <div className="max-w-3xl mx-auto space-y-6">
        {/* Header */}
        <div className="flex items-center gap-4">
          <Link
            href="/citations"
            className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
          >
            <ArrowLeftIcon className="h-5 w-5 text-gray-600" />
          </Link>
          <div>
            <h1 className="text-2xl font-bold text-gray-900">Nueva Notificación</h1>
            <p className="text-sm text-gray-500 mt-1">
              Crear una nueva advertencia o citación
            </p>
          </div>
        </div>

        {error && (
          <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg">
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-6">
          {/* Tipo de Notificación */}
          <div className="bg-white rounded-lg shadow p-6">
            <h2 className="text-lg font-semibold text-gray-900 mb-4">Tipo de Notificación</h2>
            <div className="grid grid-cols-2 gap-4">
              {citationTypeOptions.map(option => (
                <button
                  key={option.value}
                  type="button"
                  onClick={() => setFormData(prev => ({ ...prev, citationType: option.value as CitationType }))}
                  className={`p-4 rounded-lg border-2 text-left transition-all ${
                    formData.citationType === option.value
                      ? 'border-indigo-500 bg-indigo-50'
                      : 'border-gray-200 hover:border-gray-300'
                  }`}
                >
                  <option.icon className={`h-6 w-6 mb-2 ${
                    formData.citationType === option.value ? 'text-indigo-600' : 'text-gray-400'
                  }`} />
                  <p className="font-medium text-gray-900">{option.label}</p>
                  <p className="text-xs text-gray-500 mt-1">{option.description}</p>
                </button>
              ))}
            </div>
          </div>

          {/* Número de Notificación */}
          <div className="bg-white rounded-lg shadow p-6">
            <h2 className="text-lg font-semibold text-gray-900 mb-4">Número de Papeleta</h2>
            <div>
              <label htmlFor="citationNumber" className="block text-sm font-medium text-gray-700">
                Número de Notificación (según papeleta física) *
              </label>
              <input
                type="text"
                id="citationNumber"
                name="citationNumber"
                required
                placeholder="Ej: 001234, ADV-2024-001, etc."
                value={formData.citationNumber}
                onChange={handleChange}
                className="mt-1 block w-full rounded-lg border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
              />
              <p className="mt-1 text-xs text-gray-500">
                Ingrese el número exacto que aparece en la papeleta física
              </p>
            </div>
          </div>

          {/* Tipo de Objetivo */}
          <div className="bg-white rounded-lg shadow p-6">
            <h2 className="text-lg font-semibold text-gray-900 mb-4">¿A quién va dirigida?</h2>
            <div className="flex flex-wrap gap-2">
              {targetTypeOptions.map(option => (
                <button
                  key={option.value}
                  type="button"
                  onClick={() => setFormData(prev => ({
                    ...prev,
                    targetType: option.value as TargetType,
                    targetName: '',
                    targetRut: '',
                    targetAddress: '',
                    targetPhone: '',
                    targetPlate: '',
                  }))}
                  className={`flex items-center gap-2 px-4 py-2 rounded-full border transition-all ${
                    formData.targetType === option.value
                      ? 'border-indigo-500 bg-indigo-50 text-indigo-700'
                      : 'border-gray-200 hover:border-gray-300 text-gray-600'
                  }`}
                >
                  <option.icon className="h-4 w-4" />
                  {option.label}
                </button>
              ))}
            </div>
          </div>

          {/* Datos del Objetivo */}
          <div className="bg-white rounded-lg shadow p-6">
            <h2 className="text-lg font-semibold text-gray-900 mb-4">
              Datos del {targetTypeOptions.find(o => o.value === formData.targetType)?.label}
            </h2>
            <div className="space-y-4">
              {getTargetFields()}
            </div>
          </div>

          {/* Ubicación */}
          <div className="bg-white rounded-lg shadow p-6">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-lg font-semibold text-gray-900 flex items-center gap-2">
                <MapPinIcon className="h-5 w-5 text-gray-500" />
                Ubicación del Hecho
              </h2>
              {formData.targetAddress && (
                <button
                  type="button"
                  onClick={handleReuseTargetAddress}
                  className="flex items-center gap-1 text-xs text-indigo-600 hover:text-indigo-800"
                >
                  <ArrowPathIcon className="h-3 w-3" />
                  Usar dirección del destinatario
                </button>
              )}
            </div>

            <LocationPicker
              latitude={formData.latitude}
              longitude={formData.longitude}
              address={formData.locationAddress}
              onLocationChange={handleLocationChange}
              onAddressChange={handleLocationAddressChange}
            />
          </div>

          {/* Motivo */}
          <div className="bg-white rounded-lg shadow p-6">
            <h2 className="text-lg font-semibold text-gray-900 mb-4">Detalles</h2>
            <div className="space-y-4">
              <div>
                <label htmlFor="reason" className="block text-sm font-medium text-gray-700">
                  Motivo de la {formData.citationType === 'advertencia' ? 'Advertencia' : 'Citación'} *
                </label>
                <textarea
                  id="reason"
                  name="reason"
                  required
                  rows={3}
                  value={formData.reason}
                  onChange={handleChange}
                  placeholder="Describa el motivo de la notificación..."
                  className="mt-1 block w-full rounded-lg border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                />
              </div>
              <div>
                <label htmlFor="notes" className="block text-sm font-medium text-gray-700">
                  Observaciones Adicionales
                </label>
                <textarea
                  id="notes"
                  name="notes"
                  rows={2}
                  value={formData.notes}
                  onChange={handleChange}
                  className="mt-1 block w-full rounded-lg border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                />
              </div>
            </div>
          </div>

          {/* Fotos */}
          <div className="bg-white rounded-lg shadow p-6">
            <h2 className="text-lg font-semibold text-gray-900 mb-4 flex items-center gap-2">
              <CameraIcon className="h-5 w-5 text-gray-500" />
              Evidencia Fotográfica
            </h2>
            <div className="space-y-4">
              <input
                type="file"
                ref={fileInputRef}
                onChange={handlePhotoSelect}
                accept="image/*"
                multiple
                className="hidden"
              />
              <button
                type="button"
                onClick={() => fileInputRef.current?.click()}
                className="w-full py-8 border-2 border-dashed border-gray-300 rounded-lg hover:border-gray-400 transition-colors flex flex-col items-center justify-center gap-2"
              >
                <CameraIcon className="h-8 w-8 text-gray-400" />
                <span className="text-sm text-gray-500">Agregar fotos</span>
              </button>
              {previewPhotos.length > 0 && (
                <div className="grid grid-cols-3 gap-4">
                  {previewPhotos.map((photo, index) => (
                    <div key={index} className="relative group">
                      <img
                        src={photo}
                        alt={`Foto ${index + 1}`}
                        className="w-full h-24 object-cover rounded-lg"
                      />
                      <button
                        type="button"
                        onClick={() => removePhoto(index)}
                        className="absolute top-1 right-1 p-1 bg-red-500 text-white rounded-full opacity-0 group-hover:opacity-100 transition-opacity"
                      >
                        <XMarkIcon className="h-4 w-4" />
                      </button>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>

          {/* Actions */}
          <div className="flex items-center justify-end gap-3">
            <Link
              href="/citations"
              className="px-6 py-2.5 text-sm font-medium text-gray-700 bg-gray-100 hover:bg-gray-200 rounded-lg transition-colors"
            >
              Cancelar
            </Link>
            <button
              type="submit"
              disabled={loading}
              className="px-6 py-2.5 text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 rounded-lg transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {loading ? 'Creando...' : `Crear ${formData.citationType === 'advertencia' ? 'Advertencia' : 'Citación'}`}
            </button>
          </div>
        </form>
      </div>
    </AppLayout>
  );
}
