'use client';

import { BellIcon, UserCircleIcon, ArrowRightOnRectangleIcon } from '@heroicons/react/24/outline';
import { useRouter } from 'next/navigation';
import { useState } from 'react';

export default function Header() {
  const router = useRouter();
  const [isLoggingOut, setIsLoggingOut] = useState(false);

  const handleLogout = async () => {
    setIsLoggingOut(true);
    await fetch('/api/auth/logout', { method: 'POST' });
    router.push('/login');
    router.refresh();
  };

  return (
    <header className="bg-white/80 backdrop-blur-sm border-b border-border/50 sticky top-0 z-10">
      <div className="mx-auto px-6 lg:px-8">
        <div className="flex justify-between items-center h-16">
          {/* Title */}
          <div className="flex items-center">
            <h2 className="text-lg font-semibold text-foreground">
              Sistema de Gestión Municipal
            </h2>
          </div>

          {/* Actions */}
          <div className="flex items-center gap-2">
            {/* Notifications */}
            <button
              type="button"
              className="relative p-2.5 text-muted-foreground hover:text-foreground hover:bg-accent rounded-lg transition-colors focus:outline-none focus:ring-2 focus:ring-primary/20"
            >
              <span className="sr-only">Ver notificaciones</span>
              <BellIcon className="h-5 w-5" aria-hidden="true" />
              {/* Notification badge */}
              <span className="absolute top-2 right-2 w-2 h-2 bg-destructive rounded-full"></span>
            </button>

            {/* Divider */}
            <div className="w-px h-6 bg-border mx-2"></div>

            {/* User menu */}
            <div className="flex items-center gap-3">
              <div className="hidden sm:block text-right">
                <p className="text-sm font-medium text-foreground">Administrador</p>
                <p className="text-xs text-muted-foreground">Santa Juana</p>
              </div>
              <div className="w-9 h-9 rounded-lg bg-primary/10 flex items-center justify-center">
                <UserCircleIcon className="h-6 w-6 text-primary" />
              </div>
            </div>

            {/* Logout */}
            <button
              type="button"
              onClick={handleLogout}
              disabled={isLoggingOut}
              className="ml-2 flex items-center gap-2 px-3 py-2 text-sm font-medium text-muted-foreground hover:text-destructive hover:bg-destructive/10 rounded-lg transition-colors disabled:opacity-50"
            >
              <ArrowRightOnRectangleIcon className="h-5 w-5" />
              <span className="hidden sm:inline">Salir</span>
            </button>
          </div>
        </div>
      </div>
    </header>
  );
}
