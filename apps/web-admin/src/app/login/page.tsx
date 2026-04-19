'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { motion, AnimatePresence } from 'framer-motion';
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

    try {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 10000);

      const response = await fetch('/api/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password }),
        signal: controller.signal,
      });

      clearTimeout(timeoutId);

      if (!response.ok) {
        const data = await response.json();
        throw new Error(data.error || 'Error al iniciar sesión');
      }

      router.push('/dashboard');
      router.refresh();
    } catch (err: any) {
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
    <div className="min-h-screen flex">
      {/* Left side - Gradient */}
      <div className="hidden lg:flex lg:w-[55%] relative bg-gradient-frogio-animated overflow-hidden">
        {/* Floating particles */}
        {[...Array(6)].map((_, i) => (
          <motion.div
            key={i}
            className="absolute rounded-full"
            style={{
              width: [72, 96, 48, 120, 56, 80][i],
              height: [72, 96, 48, 120, 56, 80][i],
              top: `${[10, 60, 30, 80, 50, 15][i]}%`,
              left: `${[10, 70, 50, 20, 80, 40][i]}%`,
              background: `rgba(255, 255, 255, ${[0.06, 0.04, 0.08, 0.03, 0.05, 0.07][i]})`,
            }}
            animate={{
              y: [0, -20, 0],
              x: [0, 10, 0],
              scale: [1, 1.05, 1],
            }}
            transition={{
              duration: [15, 20, 12, 18, 14, 16][i],
              repeat: Infinity,
              ease: 'easeInOut',
              delay: i * 1.5,
            }}
          />
        ))}

        {/* Content */}
        <div className="relative z-10 flex flex-col items-center justify-center w-full px-12">
          <motion.div
            initial={{ scale: 0.7, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            transition={{ type: 'spring', stiffness: 150, damping: 20, delay: 0.2 }}
            className="text-center"
          >
            <motion.div
              className="w-28 h-28 rounded-3xl bg-white/15 backdrop-blur-md flex items-center justify-center mx-auto mb-8 shadow-2xl border border-white/20"
              animate={{ rotate: [0, 2, -2, 0] }}
              transition={{ duration: 8, repeat: Infinity, ease: 'easeInOut' }}
            >
              <span className="text-white font-bold text-5xl">F</span>
            </motion.div>
            <motion.h1
              className="text-5xl font-bold text-white tracking-tight mb-4"
              initial={{ y: 20, opacity: 0 }}
              animate={{ y: 0, opacity: 1 }}
              transition={{ delay: 0.4, duration: 0.6 }}
            >
              FROGIO
            </motion.h1>
            <motion.div
              className="w-16 h-1 bg-white/40 rounded-full mx-auto mb-6"
              initial={{ scaleX: 0 }}
              animate={{ scaleX: 1 }}
              transition={{ delay: 0.6, duration: 0.5 }}
            />
            <motion.p
              className="text-white/80 text-lg font-medium max-w-sm"
              initial={{ y: 10, opacity: 0 }}
              animate={{ y: 0, opacity: 1 }}
              transition={{ delay: 0.7, duration: 0.5 }}
            >
              Sistema de Gestión Municipal Integral
            </motion.p>
          </motion.div>

          <motion.div
            className="absolute bottom-8 text-white/40 text-sm"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 1.2 }}
          >
            Municipalidad de Santa Juana
          </motion.div>
        </div>
      </div>

      {/* Right side - Form */}
      <div className="flex-1 flex items-center justify-center bg-background px-4 sm:px-8">
        <div className="w-full max-w-md">
          {/* Mobile logo */}
          <motion.div
            className="text-center mb-8 lg:hidden"
            initial={{ opacity: 0, y: -20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5 }}
          >
            <div className="w-16 h-16 rounded-2xl bg-gradient-frogio flex items-center justify-center mx-auto mb-4 shadow-lg">
              <span className="text-white font-bold text-2xl">F</span>
            </div>
            <h1 className="text-2xl font-bold gradient-text tracking-tight">
              FROGIO
            </h1>
            <p className="text-sm text-muted-foreground mt-1">
              Sistema de Gestión Municipal
            </p>
          </motion.div>

          {/* Form Card */}
          <motion.div
            className="bg-card rounded-2xl border border-border/50 shadow-xl p-8"
            initial={{ opacity: 0, y: 24, scale: 0.98 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            transition={{ duration: 0.5, delay: 0.1, ease: [0.22, 1, 0.36, 1] }}
          >
            <div className="mb-8">
              <motion.h2
                className="text-2xl font-bold text-foreground"
                initial={{ opacity: 0, x: -10 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: 0.2 }}
              >
                Bienvenido
              </motion.h2>
              <motion.p
                className="text-sm text-muted-foreground mt-2"
                initial={{ opacity: 0, x: -10 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: 0.3 }}
              >
                Ingresa tus credenciales para acceder al panel
              </motion.p>
            </div>

            <form onSubmit={handleSubmit} className="space-y-5">
              <AnimatePresence>
                {error && (
                  <motion.div
                    initial={{ opacity: 0, y: -10, height: 0 }}
                    animate={{ opacity: 1, y: 0, height: 'auto' }}
                    exit={{ opacity: 0, y: -10, height: 0 }}
                    className="flex items-center gap-2 p-3 rounded-xl bg-destructive/10 border border-destructive/20"
                  >
                    <ExclamationCircleIcon className="h-5 w-5 text-destructive flex-shrink-0" />
                    <p className="text-sm text-destructive">{error}</p>
                  </motion.div>
                )}
              </AnimatePresence>

              <motion.div
                initial={{ opacity: 0, y: 15 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.25 }}
              >
                <label htmlFor="email" className="block text-sm font-medium text-foreground mb-2">
                  Email
                </label>
                <div className="relative group">
                  <div className="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none">
                    <EnvelopeIcon className="h-5 w-5 text-muted-foreground group-focus-within:text-primary transition-colors duration-300" />
                  </div>
                  <input
                    id="email"
                    name="email"
                    type="email"
                    required
                    className="input-minimal pl-11 h-12 rounded-xl focus-ring"
                    placeholder="correo@ejemplo.com"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                  />
                </div>
              </motion.div>

              <motion.div
                initial={{ opacity: 0, y: 15 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.35 }}
              >
                <div className="flex items-center justify-between mb-2">
                  <label htmlFor="password" className="block text-sm font-medium text-foreground">
                    Contraseña
                  </label>
                  <button
                    type="button"
                    onClick={() => alert('Por favor, contacta al administrador del sistema para restablecer tu contraseña.')}
                    className="text-xs text-primary hover:text-primary/80 transition-colors animated-underline"
                  >
                    ¿Olvidaste tu contraseña?
                  </button>
                </div>
                <div className="relative group">
                  <div className="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none">
                    <LockClosedIcon className="h-5 w-5 text-muted-foreground group-focus-within:text-primary transition-colors duration-300" />
                  </div>
                  <input
                    id="password"
                    name="password"
                    type="password"
                    required
                    className="input-minimal pl-11 h-12 rounded-xl focus-ring"
                    placeholder="••••••••"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                  />
                </div>
              </motion.div>

              <motion.div
                initial={{ opacity: 0, y: 15 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.45 }}
              >
                <motion.button
                  type="submit"
                  disabled={loading}
                  className="w-full flex items-center justify-center gap-2 h-12 px-4 bg-gradient-frogio text-white rounded-xl font-medium text-sm shadow-lg hover:shadow-xl active:scale-[0.98] transition-all disabled:opacity-50 disabled:cursor-not-allowed"
                  whileHover={{ scale: loading ? 1 : 1.01 }}
                  whileTap={{ scale: loading ? 1 : 0.98 }}
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
                </motion.button>
              </motion.div>
            </form>
          </motion.div>

          <motion.p
            className="text-center text-xs text-muted-foreground mt-8"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 0.8 }}
          >
            Santa Juana - Gestión Municipal Integral
          </motion.p>
        </div>
      </div>
    </div>
  );
}
