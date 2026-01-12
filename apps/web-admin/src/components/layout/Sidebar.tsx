'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import {
  HomeIcon,
  DocumentTextIcon,
  ExclamationTriangleIcon,
  TruckIcon,
  ScaleIcon,
  HeartIcon,
  UserGroupIcon,
  BellIcon,
  ChartBarIcon,
  Cog6ToothIcon,
  MapIcon,
} from '@heroicons/react/24/outline';

const navigation = [
  { name: 'Dashboard', href: '/dashboard', icon: HomeIcon },
  { name: 'Reportes', href: '/reports', icon: DocumentTextIcon },
  { name: 'Citaciones', href: '/citations', icon: ScaleIcon },
  { name: 'Gestión de Flota', href: '/fleet', icon: TruckIcon },
  { name: 'Fichas Médicas', href: '/medical-records', icon: HeartIcon },
  { name: 'Usuarios', href: '/users', icon: UserGroupIcon },
  { name: 'Notificaciones', href: '/notifications', icon: BellIcon },
];

export default function Sidebar() {
  const pathname = usePathname();

  return (
    <div className="hidden md:flex md:w-64 md:flex-col md:fixed md:inset-y-0">
      <div className="flex flex-col flex-grow border-r border-gray-200 bg-white overflow-y-auto">
        <div className="flex items-center flex-shrink-0 px-4 py-5 border-b border-gray-200">
          <h1 className="text-xl font-bold text-indigo-600">FROGIO Admin</h1>
        </div>
        <div className="flex-grow flex flex-col">
          <nav className="flex-1 px-2 py-4 space-y-1">
            {navigation.map((item) => {
              const isActive = pathname === item.href || pathname.startsWith(item.href + '/');
              return (
                <Link
                  key={item.name}
                  href={item.href}
                  className={`
                    group flex items-center px-3 py-2 text-sm font-medium rounded-md transition-colors
                    ${isActive
                      ? 'bg-indigo-50 text-indigo-600'
                      : 'text-gray-700 hover:bg-gray-50 hover:text-gray-900'
                    }
                  `}
                >
                  <item.icon
                    className={`
                      mr-3 flex-shrink-0 h-6 w-6
                      ${isActive ? 'text-indigo-600' : 'text-gray-400 group-hover:text-gray-500'}
                    `}
                    aria-hidden="true"
                  />
                  {item.name}
                </Link>
              );
            })}
          </nav>
        </div>
      </div>
    </div>
  );
}
