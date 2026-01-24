'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import {
  HomeIcon,
  DocumentTextIcon,
  TruckIcon,
  ScaleIcon,
  UserGroupIcon,
  BellIcon,
} from '@heroicons/react/24/outline';

const navigation = [
  { name: 'Dashboard', href: '/dashboard', icon: HomeIcon },
  { name: 'Reportes', href: '/reports', icon: DocumentTextIcon },
  { name: 'Citaciones', href: '/citations', icon: ScaleIcon },
  { name: 'Gestión de Flota', href: '/fleet', icon: TruckIcon },
  { name: 'Usuarios', href: '/users', icon: UserGroupIcon },
  { name: 'Notificaciones', href: '/notifications', icon: BellIcon },
];

export default function Sidebar() {
  const pathname = usePathname();

  return (
    <div className="hidden md:flex md:w-64 md:flex-col md:fixed md:inset-y-0">
      <div className="flex flex-col flex-grow bg-white overflow-y-auto border-r border-border/50">
        {/* Logo */}
        <div className="flex items-center flex-shrink-0 px-6 py-6">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-primary flex items-center justify-center shadow-sm">
              <span className="text-white font-bold text-lg">F</span>
            </div>
            <div>
              <h1 className="text-lg font-bold text-primary tracking-tight">FROGIO</h1>
              <p className="text-[10px] text-muted-foreground font-medium tracking-wide">ADMIN PANEL</p>
            </div>
          </div>
        </div>

        {/* Navigation */}
        <nav className="flex-1 px-3 py-4 space-y-1">
          {navigation.map((item, index) => {
            const isActive = pathname === item.href || pathname.startsWith(item.href + '/');
            return (
              <Link
                key={item.name}
                href={item.href}
                className={`
                  group flex items-center px-3 py-2.5 text-sm font-medium rounded-lg transition-all duration-200
                  ${isActive
                    ? 'bg-primary text-white shadow-sm'
                    : 'text-muted-foreground hover:bg-accent hover:text-accent-foreground'
                  }
                `}
                style={{ animationDelay: `${index * 50}ms` }}
              >
                <item.icon
                  className={`
                    mr-3 flex-shrink-0 h-5 w-5 transition-colors
                    ${isActive ? 'text-white' : 'text-muted-foreground group-hover:text-accent-foreground'}
                  `}
                  aria-hidden="true"
                />
                {item.name}
              </Link>
            );
          })}
        </nav>

        {/* Footer */}
        <div className="p-4 border-t border-border/50">
          <div className="px-3 py-3 rounded-lg bg-accent/50">
            <p className="text-xs text-muted-foreground">
              Sistema de Gestión
            </p>
            <p className="text-xs font-medium text-foreground mt-0.5">
              Municipal Santa Juana
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
