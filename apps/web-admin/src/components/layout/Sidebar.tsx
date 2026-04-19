'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { motion } from 'framer-motion';
import {
  HomeIcon,
  DocumentTextIcon,
  TruckIcon,
  ScaleIcon,
  UserGroupIcon,
  BellIcon,
  MapIcon,
  CircleStackIcon,
} from '@heroicons/react/24/outline';

interface NavItem {
  name: string;
  href: string;
  icon: typeof HomeIcon;
  highlight?: boolean;
  badge?: string;
}

const navigation: NavItem[] = [
  { name: 'Dashboard', href: '/dashboard', icon: HomeIcon },
  { name: 'Mapa en Vivo', href: '/live-map', icon: MapIcon, highlight: true },
  { name: 'Reportes', href: '/reports', icon: DocumentTextIcon },
  { name: 'Citaciones', href: '/citations', icon: ScaleIcon },
  { name: 'Flota', href: '/fleet', icon: TruckIcon },
  { name: 'Datos', href: '/data', icon: CircleStackIcon },
  { name: 'Usuarios', href: '/users', icon: UserGroupIcon },
  { name: 'Notificaciones', href: '/notifications', icon: BellIcon },
];

const navItemVariants = {
  hidden: { opacity: 0, x: -20 },
  show: (i: number) => ({
    opacity: 1,
    x: 0,
    transition: {
      delay: i * 0.06,
      duration: 0.4,
      ease: [0.22, 1, 0.36, 1] as [number, number, number, number],
    },
  }),
};

export default function Sidebar() {
  const pathname = usePathname();

  return (
    <div className="hidden md:flex md:w-64 md:flex-col md:fixed md:inset-y-0 z-20">
      <div className="flex flex-col flex-grow bg-white/95 backdrop-blur-xl overflow-y-auto border-r border-border/30">
        {/* Logo */}
        <div className="flex items-center flex-shrink-0 px-6 py-6">
          <motion.div
            className="flex items-center gap-3"
            initial={{ opacity: 0, scale: 0.8, y: -10 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            transition={{ duration: 0.5, ease: [0.22, 1, 0.36, 1] }}
          >
            <motion.div
              className="w-11 h-11 rounded-xl bg-gradient-frogio flex items-center justify-center shadow-lg"
              whileHover={{ scale: 1.05, rotate: 3 }}
              transition={{ type: 'spring', stiffness: 400, damping: 17 }}
            >
              <span className="text-white font-bold text-lg">F</span>
            </motion.div>
            <div>
              <h1 className="text-lg font-bold gradient-text tracking-tight">FROGIO</h1>
              <p className="text-[10px] text-muted-foreground font-medium tracking-[0.2em] uppercase">Admin Panel</p>
            </div>
          </motion.div>
        </div>

        {/* Separator */}
        <div className="mx-5 h-px bg-gradient-to-r from-transparent via-border/60 to-transparent" />

        {/* Navigation */}
        <nav className="flex-1 px-3 py-4 space-y-1">
          {navigation.map((item, index) => {
            const isActive = pathname === item.href || pathname.startsWith(item.href + '/');
            const isHighlight = item.highlight && !isActive;
            return (
              <motion.div
                key={item.name}
                custom={index}
                variants={navItemVariants}
                initial="hidden"
                animate="show"
              >
                <Link
                  href={item.href}
                  className={`
                    group relative flex items-center px-3 py-2.5 text-sm font-medium rounded-xl transition-all duration-300
                    ${isActive
                      ? 'bg-primary/10 text-primary font-semibold shadow-sm'
                      : isHighlight
                      ? 'bg-emerald-50/80 text-emerald-700 border border-emerald-200/50 hover:bg-emerald-100/80 hover:shadow-sm'
                      : 'text-muted-foreground hover:bg-accent/80 hover:text-accent-foreground hover:shadow-sm'
                    }
                  `}
                >
                  {/* Active indicator bar */}
                  {isActive && (
                    <motion.div
                      layoutId="activeNav"
                      className="absolute left-0 top-1/2 -translate-y-1/2 w-[3px] h-7 bg-gradient-to-b from-primary to-primary/60 rounded-r-full"
                      transition={{
                        type: 'spring',
                        stiffness: 400,
                        damping: 30,
                      }}
                    />
                  )}
                  <motion.div
                    whileHover={{ scale: 1.15, rotate: isActive ? 0 : -5 }}
                    transition={{ type: 'spring', stiffness: 400, damping: 17 }}
                  >
                    <item.icon
                      className={`
                        mr-3 flex-shrink-0 h-5 w-5 transition-colors duration-300
                        ${isActive ? 'text-primary' : isHighlight ? 'text-emerald-600' : 'text-muted-foreground group-hover:text-accent-foreground'}
                      `}
                      aria-hidden="true"
                    />
                  </motion.div>
                  <span className="relative">
                    {item.name}
                    {isActive && (
                      <motion.div
                        className="absolute -bottom-0.5 left-0 right-0 h-[2px] bg-primary/30 rounded-full"
                        layoutId="activeUnderline"
                        transition={{ type: 'spring', stiffness: 300, damping: 25 }}
                      />
                    )}
                  </span>
                  {isHighlight && (
                    <span className="ml-auto flex h-2 w-2 relative">
                      <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
                      <span className="relative inline-flex rounded-full h-2 w-2 bg-emerald-500"></span>
                    </span>
                  )}
                </Link>
              </motion.div>
            );
          })}
        </nav>

        {/* Footer */}
        <div className="p-4 border-t border-border/30">
          <motion.div
            className="px-4 py-3 rounded-xl bg-gradient-to-br from-primary/5 via-accent/30 to-primary/5 border border-primary/10"
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.6, duration: 0.4 }}
            whileHover={{ scale: 1.02 }}
          >
            <p className="text-[11px] text-muted-foreground font-medium">
              Sistema de Gestión
            </p>
            <p className="text-xs font-semibold text-foreground mt-0.5">
              Municipal Santa Juana
            </p>
          </motion.div>
        </div>
      </div>
    </div>
  );
}
