import type { Metadata } from 'next'
import { Inter } from 'next/font/google'
import './globals.css'

const inter = Inter({ subsets: ['latin'] })

export const metadata: Metadata = {
  title: 'RaffleFlutter - La App de Rifas del Futuro',
  description: 'Gestiona rifas y sorteos de manera profesional con RaffleFlutter. Tecnología avanzada, diseño elegante y funcionalidades completas para organizar tus eventos.',
  keywords: 'rifas, sorteos, aplicación móvil, gestión de eventos, tickets digitales, QR codes',
  authors: [{ name: 'RaffleFlutter Team' }],
  creator: 'RaffleFlutter',
  publisher: 'RaffleFlutter',
  formatDetection: {
    email: false,
    address: false,
    telephone: false,
  },
  metadataBase: new URL('https://raffleflutter.com'),
  alternates: {
    canonical: '/',
  },
  openGraph: {
    title: 'RaffleFlutter - La App de Rifas del Futuro',
    description: 'Gestiona rifas y sorteos de manera profesional con RaffleFlutter. Tecnología avanzada, diseño elegante y funcionalidades completas.',
    url: 'https://raffleflutter.com',
    siteName: 'RaffleFlutter',
    images: [
      {
        url: '/og-image.jpg',
        width: 1200,
        height: 630,
        alt: 'RaffleFlutter - La App de Rifas del Futuro',
      },
    ],
    locale: 'es_ES',
    type: 'website',
  },
  twitter: {
    card: 'summary_large_image',
    title: 'RaffleFlutter - La App de Rifas del Futuro',
    description: 'Gestiona rifas y sorteos de manera profesional con RaffleFlutter.',
    images: ['/og-image.jpg'],
  },
  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
      'max-video-preview': -1,
      'max-image-preview': 'large',
      'max-snippet': -1,
    },
  },
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="es" className="scroll-smooth">
      <head>
        <link rel="icon" href="/favicon.ico" />
        <link rel="apple-touch-icon" href="/apple-touch-icon.png" />
        <link rel="manifest" href="/manifest.json" />
        <meta name="theme-color" content="#4CAF50" />
        <meta name="msapplication-TileColor" content="#4CAF50" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
      </head>
      <body className={`${inter.className} bg-black text-white antialiased`}>
        <div className="min-h-screen bg-gradient-to-br from-black via-gray-900 to-black">
          {children}
        </div>
      </body>
    </html>
  )
} 