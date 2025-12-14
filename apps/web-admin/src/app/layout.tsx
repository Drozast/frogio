import type { Metadata } from 'next'
import './globals.css'

export const metadata: Metadata = {
  title: 'FROGIO Admin - Gestión Municipal',
  description: 'Sistema de Gestión de Seguridad Pública Municipal',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="es">
      <body>{children}</body>
    </html>
  )
}
