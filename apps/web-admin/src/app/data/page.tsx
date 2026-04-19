import { cookies } from 'next/headers';
import { redirect } from 'next/navigation';
import AppLayout from '@/components/layout/AppLayout';
import DataExplorerClient from '@/components/data/DataExplorerClient';

interface JwtPayload {
  email?: string;
  userId?: string;
  firstName?: string;
  lastName?: string;
  name?: string;
  [key: string]: unknown;
}

function decodeJwt(token: string): JwtPayload | null {
  try {
    const parts = token.split('.');
    if (parts.length < 2) return null;
    const payload = parts[1].replace(/-/g, '+').replace(/_/g, '/');
    const padded = payload + '='.repeat((4 - (payload.length % 4)) % 4);
    const decoded = Buffer.from(padded, 'base64').toString('utf8');
    return JSON.parse(decoded) as JwtPayload;
  } catch {
    return null;
  }
}

export default function DataExplorerPage() {
  const cookieStore = cookies();
  const accessToken = cookieStore.get('accessToken')?.value;

  if (!accessToken) {
    redirect('/login');
  }

  const payload = decodeJwt(accessToken);
  const email = payload?.email ?? 'admin';
  const fullName =
    payload?.name ||
    [payload?.firstName, payload?.lastName].filter(Boolean).join(' ') ||
    undefined;

  return (
    <AppLayout>
      <DataExplorerClient userEmail={email} userName={fullName} />
    </AppLayout>
  );
}
