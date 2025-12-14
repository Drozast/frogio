import { cookies } from 'next/headers';

export interface User {
  userId: string;
  email: string;
  role: string;
  tenantId: string;
}

export function setAuthCookies(accessToken: string, refreshToken: string) {
  const cookieStore = cookies();

  cookieStore.set('accessToken', accessToken, {
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'lax',
    maxAge: 60 * 15, // 15 minutes
  });

  cookieStore.set('refreshToken', refreshToken, {
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'lax',
    maxAge: 60 * 60 * 24 * 7, // 7 days
  });
}

export function getAccessToken() {
  const cookieStore = cookies();
  return cookieStore.get('accessToken')?.value;
}

export function clearAuthCookies() {
  const cookieStore = cookies();
  cookieStore.delete('accessToken');
  cookieStore.delete('refreshToken');
}

export function isAuthenticated(): boolean {
  return !!getAccessToken();
}
