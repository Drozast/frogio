'use client';

import { BellIcon, UserCircleIcon, ArrowRightOnRectangleIcon, ChevronRightIcon } from '@heroicons/react/24/outline';
import MobileMenu from './MobileMenu';
import { useRouter, usePathname } from 'next/navigation';
import { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';

const routeNames: Record<string, string> = {
  dashboard: 'Dashboard',
  'live-map': 'Mapa en Vivo',
  reports: 'Reportes',
  citations: 'Citaciones',
  fleet: 'Gestión de Flota',
  users: 'Usuarios',
  notifications: 'Notificaciones',
  infractions: 'Infracciones',
};

const dropdownVariants = {
  initial: { opacity: 0, y: -8, scale: 0.96 },
  animate: { opacity: 1, y: 0, scale: 1, transition: { duration: 0.2, ease: [0.22, 1, 0.36, 1] as [number, number, number, number] } },
  exit: { opacity: 0, y: -6, scale: 0.96, transition: { duration: 0.15 } },
};

export default function Header() {
  const router = useRouter();
  const pathname = usePathname();
  const [isLoggingOut, setIsLoggingOut] = useState(false);
  const [showUserMenu, setShowUserMenu] = useState(false);
  const [showNotifications, setShowNotifications] = useState(false);

  const handleLogout = async () => {
    setIsLoggingOut(true);
    await fetch('/api/auth/logout', { method: 'POST' });
    router.push('/login');
    router.refresh();
  };

  const pathSegments = pathname.split('/').filter(Boolean);
  const breadcrumbs = pathSegments.map((segment, i) => ({
    name: routeNames[segment] || segment.charAt(0).toUpperCase() + segment.slice(1),
    href: '/' + pathSegments.slice(0, i + 1).join('/'),
    isLast: i === pathSegments.length - 1,
  }));

  return (
    <header className="bg-white/70 backdrop-blur-xl border-b border-border/30 sticky top-0 z-10">
      <div className="mx-auto px-6 lg:px-8">
        <div className="flex justify-between items-center h-16">
          {/* Mobile menu + Breadcrumb */}
          <div className="flex items-center gap-2">
            <MobileMenu />
          <nav className="hidden md:flex items-center gap-1.5 text-sm">
            {breadcrumbs.map((crumb, i) => (
              <motion.div
                key={crumb.href}
                className="flex items-center gap-1.5"
                initial={{ opacity: 0, x: -8 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: i * 0.1, duration: 0.3 }}
              >
                {i > 0 && <ChevronRightIcon className="w-3.5 h-3.5 text-muted-foreground/40" />}
                <span
                  className={`${
                    crumb.isLast
                      ? 'font-semibold text-foreground'
                      : 'text-muted-foreground hover:text-foreground cursor-pointer transition-colors animated-underline'
                  }`}
                  onClick={() => !crumb.isLast && router.push(crumb.href)}
                >
                  {crumb.name}
                </span>
              </motion.div>
            ))}
          </nav>
          </div>

          {/* Actions */}
          <div className="flex items-center gap-2">
            {/* Notifications */}
            <div className="relative">
              <motion.button
                type="button"
                onClick={() => {
                  setShowNotifications(!showNotifications);
                  setShowUserMenu(false);
                }}
                className="relative p-2.5 text-muted-foreground hover:text-foreground hover:bg-accent/60 rounded-xl transition-all focus-ring"
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
              >
                <span className="sr-only">Ver notificaciones</span>
                <BellIcon className="h-5 w-5" aria-hidden="true" />
                <motion.span
                  className="absolute top-2 right-2 w-2 h-2 bg-destructive rounded-full"
                  animate={{ scale: [1, 1.3, 1] }}
                  transition={{ repeat: Infinity, duration: 2, ease: 'easeInOut' }}
                />
              </motion.button>

              <AnimatePresence>
                {showNotifications && (
                  <>
                    <div className="fixed inset-0 z-20" onClick={() => setShowNotifications(false)} />
                    <motion.div
                      variants={dropdownVariants}
                      initial="initial"
                      animate="animate"
                      exit="exit"
                      className="absolute right-0 mt-2 w-80 bg-card/95 backdrop-blur-xl rounded-2xl border border-border/50 shadow-xl z-30 overflow-hidden"
                    >
                      <div className="px-4 py-3 border-b border-border/50">
                        <h3 className="text-sm font-semibold text-foreground">Notificaciones</h3>
                      </div>
                      <div className="px-4 py-8 text-center">
                        <motion.div
                          initial={{ scale: 0.8, opacity: 0 }}
                          animate={{ scale: 1, opacity: 1 }}
                          transition={{ delay: 0.1 }}
                        >
                          <BellIcon className="w-8 h-8 text-muted-foreground/30 mx-auto mb-2" />
                          <p className="text-sm text-muted-foreground">No hay notificaciones nuevas</p>
                        </motion.div>
                      </div>
                    </motion.div>
                  </>
                )}
              </AnimatePresence>
            </div>

            {/* Divider */}
            <div className="w-px h-6 bg-gradient-to-b from-transparent via-border to-transparent mx-1"></div>

            {/* User menu */}
            <div className="relative">
              <motion.button
                onClick={() => {
                  setShowUserMenu(!showUserMenu);
                  setShowNotifications(false);
                }}
                className="flex items-center gap-3 p-1.5 rounded-xl hover:bg-accent/60 transition-all focus-ring"
                whileHover={{ scale: 1.02 }}
                whileTap={{ scale: 0.98 }}
              >
                <div className="hidden sm:block text-right">
                  <p className="text-sm font-medium text-foreground">Administrador</p>
                  <p className="text-xs text-muted-foreground">Santa Juana</p>
                </div>
                <div className="w-9 h-9 rounded-xl bg-gradient-frogio flex items-center justify-center shadow-md">
                  <UserCircleIcon className="h-5 w-5 text-white" />
                </div>
              </motion.button>

              <AnimatePresence>
                {showUserMenu && (
                  <>
                    <div className="fixed inset-0 z-20" onClick={() => setShowUserMenu(false)} />
                    <motion.div
                      variants={dropdownVariants}
                      initial="initial"
                      animate="animate"
                      exit="exit"
                      className="absolute right-0 mt-2 w-56 bg-card/95 backdrop-blur-xl rounded-2xl border border-border/50 shadow-xl z-30 overflow-hidden"
                    >
                      <div className="px-4 py-3 border-b border-border/30">
                        <p className="text-sm font-semibold text-foreground">Administrador</p>
                        <p className="text-xs text-muted-foreground">admin@santajuana.cl</p>
                      </div>
                      <div className="py-1">
                        {['Mi Perfil', 'Configuración'].map((label, i) => (
                          <motion.button
                            key={label}
                            className="w-full text-left px-4 py-2.5 text-sm text-foreground hover:bg-accent/60 transition-colors"
                            initial={{ opacity: 0, x: -8 }}
                            animate={{ opacity: 1, x: 0 }}
                            transition={{ delay: 0.05 * i }}
                          >
                            {label}
                          </motion.button>
                        ))}
                      </div>
                      <div className="border-t border-border/30 py-1">
                        <motion.button
                          onClick={handleLogout}
                          disabled={isLoggingOut}
                          className="w-full text-left px-4 py-2.5 text-sm text-destructive hover:bg-destructive/10 transition-colors flex items-center gap-2"
                          whileHover={{ x: 2 }}
                        >
                          <ArrowRightOnRectangleIcon className="w-4 h-4" />
                          {isLoggingOut ? 'Cerrando sesión...' : 'Cerrar Sesión'}
                        </motion.button>
                      </div>
                    </motion.div>
                  </>
                )}
              </AnimatePresence>
            </div>
          </div>
        </div>
      </div>
    </header>
  );
}
