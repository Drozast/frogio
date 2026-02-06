'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { LockClosedIcon, EnvelopeIcon, ExclamationCircleIcon } from '@heroicons/react/24/outline';

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    console.log('Starting login...', { email });

    try {
      console.log('Fetching /api/auth/login...');

      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 10000);

      const response = await fetch('/api/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password }),
        signal: controller.signal,
      });

      clearTimeout(timeoutId);
      console.log('Got response:', response.status);

      if (!response.ok) {
        const data = await response.json();
        console.error('Login failed:', data);
        throw new Error(data.error || 'Error al iniciar sesión');
      }

      console.log('Login successful, redirecting...');
      router.push('/dashboard');
      router.refresh();
    } catch (err: any) {
      console.error('Login error:', err);
      if (err.name === 'AbortError') {
        setError('La petición tardó demasiado. Verifica tu conexión.');
      } else {
        setError(err.message || 'Error al iniciar sesión');
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-background px-4">
      <div className="w-full max-w-sm">
        {/* Logo Municipal */}
        <div className="text-center mb-8">
          <img
            src="/muni-vertical.png"
            alt="Municipalidad de Santa Juana"
            className="h-24 mx-auto mb-4"
          />
          <h1 className="text-2xl font-bold text-primary tracking-tight">
            FROGIO
          </h1>
          <p className="text-sm text-muted-foreground mt-1">
            Sistema de Gestión Municipal
          </p>
        </div>

        {/* Card */}
        <div className="bg-card rounded-2xl border border-border/50 shadow-card p-6">
          <div className="mb-6">
            <h2 className="text-lg font-semibold text-foreground">
              Iniciar Sesión
            </h2>
            <p className="text-sm text-muted-foreground mt-1">
              Ingresa tus credenciales para continuar
            </p>
          </div>

          <form onSubmit={handleSubmit} className="space-y-4">
            {/* Error Message */}
            {error && (
              <div className="flex items-center gap-2 p-3 rounded-lg bg-destructive/10 border border-destructive/20">
                <ExclamationCircleIcon className="h-5 w-5 text-destructive flex-shrink-0" />
                <p className="text-sm text-destructive">{error}</p>
              </div>
            )}

            {/* Email Input */}
            <div>
              <label htmlFor="email" className="block text-sm font-medium text-foreground mb-1.5">
                Email
              </label>
              <div className="relative">
                <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                  <EnvelopeIcon className="h-5 w-5 text-muted-foreground" />
                </div>
                <input
                  id="email"
                  name="email"
                  type="email"
                  required
                  className="input-minimal pl-10"
                  placeholder="correo@ejemplo.com"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                />
              </div>
            </div>

            {/* Password Input */}
            <div>
              <div className="flex items-center justify-between mb-1.5">
                <label htmlFor="password" className="block text-sm font-medium text-foreground">
                  Contraseña
                </label>
                <button
                  type="button"
                  onClick={() => alert('Por favor, contacta al administrador del sistema para restablecer tu contraseña.')}
                  className="text-xs text-primary hover:text-primary/80 hover:underline transition-colors"
                >
                  ¿Olvidaste tu contraseña?
                </button>
              </div>
              <div className="relative">
                <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                  <LockClosedIcon className="h-5 w-5 text-muted-foreground" />
                </div>
                <input
                  id="password"
                  name="password"
                  type="password"
                  required
                  className="input-minimal pl-10"
                  placeholder="••••••••"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                />
              </div>
            </div>

            {/* Submit Button */}
            <button
              type="submit"
              disabled={loading}
              className="w-full flex items-center justify-center gap-2 py-2.5 px-4 bg-primary text-primary-foreground rounded-lg font-medium text-sm shadow-sm hover:opacity-90 active:scale-[0.98] transition-all disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {loading ? (
                <>
                  <svg className="animate-spin h-4 w-4" viewBox="0 0 24 24">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" fill="none" />
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
                  </svg>
                  Iniciando sesión...
                </>
              ) : (
                'Iniciar Sesión'
              )}
            </button>
          </form>
        </div>

        {/* Footer */}
        <p className="text-center text-xs text-muted-foreground mt-6">
          Santa Juana - Gestión Municipal
        </p>
      </div>
    </div>
  );
}
