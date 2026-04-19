'use client';

import { useState } from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { motion, AnimatePresence } from 'framer-motion';
import {
  HomeIcon,
  DocumentTextIcon,
  TruckIcon,
  ScaleIcon,
  UserGroupIcon,
  BellIcon,
  MapIcon,
  Bars3Icon,
  XMarkIcon,
  CircleStackIcon,
} from '@heroicons/react/24/outline';

const navigation = [
  { name: 'Dashboard', href: '/dashboard', icon: HomeIcon },
  { name: 'Mapa en Vivo', href: '/live-map', icon: MapIcon },
  { name: 'Reportes', href: '/reports', icon: DocumentTextIcon },
  { name: 'Citaciones', href: '/citations', icon: ScaleIcon },
  { name: 'Gestión de Flota', href: '/fleet', icon: TruckIcon },
  { name: 'Datos', href: '/data', icon: CircleStackIcon },
  { name: 'Usuarios', href: '/users', icon: UserGroupIcon },
  { name: 'Notificaciones', href: '/notifications', icon: BellIcon },
];

export default function MobileMenu() {
  const [isOpen, setIsOpen] = useState(false);
  const pathname = usePathname();

  return (
    <div className="md:hidden">
      {/* Hamburger button */}
      <motion.button
        onClick={() => setIsOpen(true)}
        className="p-2 text-muted-foreground hover:text-foreground hover:bg-accent/60 rounded-xl transition-colors"
        whileTap={{ scale: 0.9 }}
        aria-label="Abrir menu de navegacion"
      >
        <Bars3Icon className="h-6 w-6" />
      </motion.button>

      {/* Overlay + Drawer */}
      <AnimatePresence>
        {isOpen && (
          <>
            {/* Backdrop */}
            <motion.div
              className="fixed inset-0 bg-black/40 backdrop-blur-sm z-40"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={() => setIsOpen(false)}
            />

            {/* Drawer */}
            <motion.div
              className="fixed inset-y-0 left-0 w-72 bg-white/95 backdrop-blur-xl shadow-2xl z-50 flex flex-col"
              initial={{ x: '-100%' }}
              animate={{ x: 0 }}
              exit={{ x: '-100%' }}
              transition={{ type: 'spring', stiffness: 300, damping: 30 }}
              role="dialog"
              aria-modal="true"
              aria-label="Menu de navegacion"
            >
              {/* Header */}
              <div className="flex items-center justify-between px-5 py-5 border-b border-border/30">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-xl bg-gradient-frogio flex items-center justify-center shadow-md">
                    <span className="text-white font-bold text-lg">F</span>
                  </div>
                  <div>
                    <h1 className="text-lg font-bold text-primary tracking-tight">FROGIO</h1>
                    <p className="text-[10px] text-muted-foreground font-medium tracking-[0.2em] uppercase">Admin Panel</p>
                  </div>
                </div>
                <motion.button
                  onClick={() => setIsOpen(false)}
                  className="p-2 text-muted-foreground hover:text-foreground hover:bg-accent/60 rounded-xl"
                  whileTap={{ scale: 0.9 }}
                  aria-label="Cerrar menu"
                >
                  <XMarkIcon className="h-5 w-5" />
                </motion.button>
              </div>

              {/* Navigation */}
              <nav className="flex-1 px-3 py-4 space-y-1 overflow-y-auto" aria-label="Navegacion principal">
                {navigation.map((item, index) => {
                  const isActive = pathname === item.href || pathname.startsWith(item.href + '/');
                  return (
                    <motion.div
                      key={item.name}
                      initial={{ opacity: 0, x: -20 }}
                      animate={{ opacity: 1, x: 0 }}
                      transition={{ delay: index * 0.05 }}
                    >
                      <Link
                        href={item.href}
                        onClick={() => setIsOpen(false)}
                        className={`
                          group relative flex items-center px-3 py-3 text-sm font-medium rounded-xl transition-all duration-200
                          ${isActive
                            ? 'bg-primary/10 text-primary font-semibold'
                            : 'text-muted-foreground hover:bg-accent/80 hover:text-accent-foreground'
                          }
                        `}
                        aria-current={isActive ? 'page' : undefined}
                      >
                        {isActive && (
                          <div className="absolute left-0 top-1/2 -translate-y-1/2 w-[3px] h-7 bg-primary rounded-r-full" />
                        )}
                        <item.icon
                          className={`mr-3 flex-shrink-0 h-5 w-5 ${isActive ? 'text-primary' : 'text-muted-foreground'}`}
                          aria-hidden="true"
                        />
                        <span>{item.name}</span>
                      </Link>
                    </motion.div>
                  );
                })}
              </nav>

              {/* Footer */}
              <div className="p-4 border-t border-border/30">
                <div className="px-4 py-3 rounded-xl bg-gradient-to-br from-primary/5 via-accent/30 to-primary/5 border border-primary/10">
                  <p className="text-[11px] text-muted-foreground font-medium">Sistema de Gestion</p>
                  <p className="text-xs font-semibold text-foreground mt-0.5">Municipal Santa Juana</p>
                </div>
              </div>
            </motion.div>
          </>
        )}
      </AnimatePresence>
    </div>
  );
}
