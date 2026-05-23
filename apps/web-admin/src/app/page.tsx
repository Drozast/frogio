import { cookies } from 'next/headers';
import { redirect } from 'next/navigation';
import { DEFAULT_TENANT } from '@/config/tenants';

export default function Home() {
  const cookieStore = cookies();
  const accessToken = cookieStore.get('accessToken')?.value;

  // If authenticated, redirect to default tenant dashboard
  if (accessToken) {
    redirect(`/${DEFAULT_TENANT}/dashboard`);
  }

  // If not authenticated, redirect to default tenant login
  redirect(`/${DEFAULT_TENANT}/login`);
}
