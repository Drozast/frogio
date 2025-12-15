import { cookies } from 'next/headers';
import { redirect } from 'next/navigation';

export default function Home() {
  const cookieStore = cookies();
  const accessToken = cookieStore.get('accessToken')?.value;

  // Si está autenticado, redirigir al dashboard
  if (accessToken) {
    redirect('/dashboard');
  }

  // Si no está autenticado, redirigir al login
  redirect('/login');
}
