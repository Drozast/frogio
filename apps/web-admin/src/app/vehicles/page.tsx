import { redirect } from 'next/navigation';

// Redirect old vehicles page to unified fleet management
export default function VehiclesPage() {
  redirect('/fleet?tab=vehicles');
}
