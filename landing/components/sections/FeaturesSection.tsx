'use client'

import React from 'react'
import { motion } from 'framer-motion'
import { 
  Ticket, 
  Gift, 
  QrCode, 
  Users, 
  Trophy, 
  Share2, 
  Zap, 
  Shield, 
  Smartphone,
  BarChart3,
  Settings,
  Download
} from 'lucide-react'
import { FeatureCard } from '../ui/FeatureCard'

const FeaturesSection = () => {
  const mainFeatures = [
    {
      icon: Ticket,
      title: 'Gestión de Rifas',
      description: 'Crea y gestiona rifas completas con tipos de lotería nacional o sorteo interno. Controla cada ticket con estados (disponible, reservado, vendido) y información detallada de compradores.',
    },
    {
      icon: Gift,
      title: 'Sorteos Inteligentes',
      description: 'Organiza sorteos gratuitos con participantes, preselecciones automáticas y designación de múltiples ganadores. Perfecto para promociones y eventos especiales.',
    },
    {
      icon: QrCode,
      title: 'Tickets Digitales',
      description: 'Genera tickets con códigos QR únicos, diseño profesional y toda la información necesaria. Exporta como imágenes de alta calidad listas para compartir.',
    },
  ]

  const additionalFeatures = [
    {
      icon: Share2,
      title: 'Compartir Instantáneo',
      description: 'Comparte tickets por WhatsApp, redes sociales o guarda en galería con un solo toque.',
    },
    {
      icon: BarChart3,
      title: 'Análisis Financiero',
      description: 'Resumen completo de ventas, ingresos, porcentajes y estadísticas en tiempo real.',
    },
    {
      icon: Users,
      title: 'Gestión de Participantes',
      description: 'Registra y administra participantes con contactos, estados y historial completo.',
    },
    {
      icon: Trophy,
      title: 'Múltiples Premios',
      description: 'Configura diferentes tipos de premios y categorías para sorteos más atractivos.',
    },
    {
      icon: Shield,
      title: 'Datos Seguros',
      description: 'Almacenamiento local seguro con SQLite, sin dependencia de internet.',
    },
    {
      icon: Zap,
      title: 'Súper Rápida',
      description: 'Arquitectura optimizada con Flutter para rendimiento excepcional.',
    },
  ]

  return (
    <section id="features" className="relative py-20 bg-gradient-to-b from-black to-gray-900">
      {/* Efectos de fondo */}
      <div className="absolute inset-0">
        <div className="absolute inset-0 bg-[radial-gradient(circle_at_50%_50%,rgba(76,175,80,0.1),transparent_50%)]" />
        <div className="absolute top-0 left-0 w-full h-px bg-gradient-to-r from-transparent via-raffle-green to-transparent" />
      </div>

      <div className="relative z-10 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        
        {/* Encabezado */}
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          whileInView={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6 }}
          viewport={{ once: true }}
          className="text-center mb-16"
        >
          <div className="inline-flex items-center gap-2 px-4 py-2 bg-raffle-green/10 rounded-full border border-raffle-green/30 mb-6">
            <Smartphone size={16} className="text-raffle-green" />
            <span className="text-sm font-medium text-raffle-green">
              Funcionalidades Avanzadas
            </span>
          </div>
          
          <h2 className="text-4xl md:text-6xl font-bold text-white mb-6">
            Diseñada para{' '}
            <span className="bg-gradient-to-r from-raffle-green to-raffle-green-light bg-clip-text text-transparent">
              Profesionales
            </span>
          </h2>
          
          <p className="text-xl text-gray-300 max-w-3xl mx-auto leading-relaxed">
            Cada función está cuidadosamente diseñada para optimizar tu experiencia. 
            Desde la creación hasta la gestión completa, RaffleFlutter te da el control total.
          </p>
        </motion.div>

        {/* Características principales */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8 mb-20">
          {mainFeatures.map((feature, index) => (
            <FeatureCard
              key={index}
              title={feature.title}
              description={feature.description}
              icon={feature.icon}
              delay={index * 0.2}
              className="h-full"
            />
          ))}
        </div>

        {/* Sección de demostración visual */}
        <motion.div
          initial={{ opacity: 0, y: 50 }}
          whileInView={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8 }}
          viewport={{ once: true }}
          className="mb-20"
        >
          <div className="relative">
            {/* Fondo con efecto glassmorphism */}
            <div className="absolute inset-0 bg-gradient-to-br from-white/5 to-white/2 rounded-3xl backdrop-blur-sm border border-white/10" />
            
            {/* Contenido */}
            <div className="relative z-10 p-8 md:p-12 text-center">
              <div className="mb-8">
                <div className="inline-flex items-center justify-center w-20 h-20 bg-gradient-to-r from-raffle-green to-raffle-green-light rounded-2xl mb-6">
                  <Settings size={32} className="text-white" />
                </div>
                <h3 className="text-3xl md:text-4xl font-bold text-white mb-4">
                  Arquitectura Clean & Moderna
                </h3>
                <p className="text-lg text-gray-300 max-w-2xl mx-auto">
                  Construida con Flutter y arquitectura Clean Architecture. 
                  Diseño elegante, rendimiento excepcional y experiencia de usuario premium.
                </p>
              </div>

              {/* Indicadores técnicos */}
              <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                {[
                  { label: 'Flutter', value: '100%' },
                  { label: 'Bloc State', value: '100%' },
                  { label: 'SQLite', value: '100%' },
                  { label: 'Clean Arch', value: '100%' },
                ].map((tech, index) => (
                  <div key={index} className="text-center">
                    <div className="text-2xl font-bold text-raffle-green mb-1">
                      {tech.value}
                    </div>
                    <div className="text-sm text-gray-400">
                      {tech.label}
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </motion.div>

        {/* Características adicionales */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {additionalFeatures.map((feature, index) => (
            <FeatureCard
              key={index}
              title={feature.title}
              description={feature.description}
              icon={feature.icon}
              delay={index * 0.1}
              className="h-full"
            />
          ))}
        </div>

        {/* CTA section */}
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          whileInView={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6 }}
          viewport={{ once: true }}
          className="text-center mt-20"
        >
          <div className="relative">
            <div className="absolute inset-0 bg-gradient-to-r from-raffle-green/20 to-raffle-green-light/20 rounded-2xl blur-xl" />
            <div className="relative bg-gradient-to-r from-raffle-green/10 to-raffle-green-light/10 rounded-2xl border border-raffle-green/30 backdrop-blur-sm p-8">
              <h3 className="text-2xl md:text-3xl font-bold text-white mb-4">
                ¿Listo para experimentar el futuro de las rifas?
              </h3>
              <p className="text-gray-300 mb-6 max-w-2xl mx-auto">
                Únete a miles de usuarios que ya están revolucionando la forma de gestionar sus rifas y sorteos.
              </p>
              <motion.button
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
                onClick={() => document.getElementById('download')?.scrollIntoView({ behavior: 'smooth' })}
                className="inline-flex items-center gap-2 px-8 py-4 bg-gradient-to-r from-raffle-green to-raffle-green-light text-white font-semibold rounded-xl shadow-lg hover:shadow-raffle-green/30 transition-all duration-300"
              >
                <Download size={20} />
                Descargar Gratis
              </motion.button>
            </div>
          </div>
        </motion.div>
      </div>
    </section>
  )
}

export default FeaturesSection 