import { cookies } from 'next/headers';
import type { Metadata } from 'next';
import './globals.css';
import { TenantProvider } from '@/lib/tenant-context';
import { getTenantConfig, DEFAULT_TENANT } from '@/config/tenants';

export async function generateMetadata(): Promise<Metadata> {
  const cookieStore = await cookies();
  const tenantId = cookieStore.get('tenantId')?.value || DEFAULT_TENANT;
  const tenant = getTenantConfig(tenantId);

  return {
    title: `${tenant.fullName} - FROGIO`,
    description: `Sistema de Gestión de Seguridad Pública — ${tenant.fullName}`,
    icons: {
      icon: '/favicon.ico',
      apple: '/apple-touch-icon.png',
    },
  };
}

export default async function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const cookieStore = await cookies();
  const tenantId = cookieStore.get('tenantId')?.value || DEFAULT_TENANT;

  return (
    <html lang="es">
      <head>
        <link
          rel="stylesheet"
          href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css"
          integrity="sha256-p4NxAoJBhIIN+hmNHrzRCf9tD/miZyoHS5obTRR9BMY="
          crossOrigin=""
        />
      </head>
      <body>
        <TenantProvider tenant={tenantId}>
          {children}
        </TenantProvider>
      </body>
    </html>
  );
}
