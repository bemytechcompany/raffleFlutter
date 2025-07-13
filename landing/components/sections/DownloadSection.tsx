'use client'

import React from 'react'
import { motion } from 'framer-motion'
import { Download, Smartphone, Star, Users, TrendingUp, Apple } from 'lucide-react'
import { AnimatedButton } from '../ui/AnimatedButton'

const DownloadSection = () => {
  const stats = [
    {
      icon: Users,
      value: '10K+',
      label: 'Usuarios Activos',
      description: 'Organizadores confían en nosotros'
    },
    {
      icon: TrendingUp,
      value: '50K+',
      label: 'Rifas Creadas',
      description: 'Eventos exitosos realizados'
    },
    {
      icon: Star,
      value: '4.9/5',
      label: 'Calificación',
      description: 'Puntuación promedio'
    }
  ]

  return (
    <section id="download" className="relative py-20 bg-gradient-to-b from-gray-900 to-black">
      {/* Efectos de fondo */}
      <div className="absolute inset-0">
        <div className="absolute inset-0 bg-[radial-gradient(circle_at_30%_20%,rgba(76,175,80,0.15),transparent_50%)]" />
        <div className="absolute inset-0 bg-[radial-gradient(circle_at_70%_80%,rgba(76,175,80,0.1),transparent_50%)]" />
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
            <Download size={16} className="text-raffle-green" />
            <span className="text-sm font-medium text-raffle-green">
              Disponible Ahora
            </span>
          </div>
          
          <h2 className="text-4xl md:text-6xl font-bold text-white mb-6">
            Descarga{' '}
            <span className="bg-gradient-to-r from-raffle-green to-raffle-green-light bg-clip-text text-transparent">
              RaffleFlutter
            </span>
          </h2>
          
          <p className="text-xl text-gray-300 max-w-3xl mx-auto leading-relaxed">
            Disponible para iOS y Android. Comienza a revolucionar la forma en que organizas 
            tus rifas y sorteos con la tecnología más avanzada.
          </p>
        </motion.div>

        {/* Estadísticas */}
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          whileInView={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.2 }}
          viewport={{ once: true }}
          className="grid grid-cols-1 md:grid-cols-3 gap-8 mb-16"
        >
          {stats.map((stat, index) => (
            <div key={index} className="text-center">
              <div className="relative mb-4">
                <div className="w-16 h-16 bg-gradient-to-r from-raffle-green to-raffle-green-light rounded-2xl flex items-center justify-center mx-auto shadow-lg">
                  <stat.icon size={28} className="text-white" />
                </div>
                <div className="absolute inset-0 w-16 h-16 bg-gradient-to-r from-raffle-green to-raffle-green-light rounded-2xl blur opacity-20 animate-pulse mx-auto" />
              </div>
              <div className="text-3xl md:text-4xl font-bold text-raffle-green mb-2">
                {stat.value}
              </div>
              <div className="text-lg font-semibold text-white mb-1">
                {stat.label}
              </div>
              <div className="text-sm text-gray-400">
                {stat.description}
              </div>
            </div>
          ))}
        </motion.div>

        {/* Botones de descarga */}
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          whileInView={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.4 }}
          viewport={{ once: true }}
          className="flex flex-col sm:flex-row gap-6 justify-center items-center mb-16"
        >
          {/* App Store */}
          <motion.a
            href="#"
            whileHover={{ scale: 1.05, y: -5 }}
            whileTap={{ scale: 0.95 }}
            className="group relative overflow-hidden bg-gradient-to-r from-gray-800 to-gray-700 border-2 border-gray-600 rounded-2xl p-4 w-64 hover:from-gray-700 hover:to-gray-600 hover:border-raffle-green/50 transition-all duration-300"
          >
            <div className="absolute inset-0 bg-gradient-to-r from-raffle-green/10 to-raffle-green-light/10 opacity-0 group-hover:opacity-100 transition-opacity duration-300" />
            <div className="relative z-10 flex items-center gap-4">
              <div className="w-12 h-12 bg-gradient-to-r from-raffle-green to-raffle-green-light rounded-xl flex items-center justify-center">
                <Apple size={24} className="text-white" />
              </div>
              <div>
                <div className="text-sm text-gray-400">Descargar en</div>
                <div className="text-xl font-bold text-white">App Store</div>
              </div>
            </div>
          </motion.a>

          {/* Google Play */}
          <motion.a
            href="#"
            whileHover={{ scale: 1.05, y: -5 }}
            whileTap={{ scale: 0.95 }}
            className="group relative overflow-hidden bg-gradient-to-r from-gray-800 to-gray-700 border-2 border-gray-600 rounded-2xl p-4 w-64 hover:from-gray-700 hover:to-gray-600 hover:border-raffle-green/50 transition-all duration-300"
          >
            <div className="absolute inset-0 bg-gradient-to-r from-raffle-green/10 to-raffle-green-light/10 opacity-0 group-hover:opacity-100 transition-opacity duration-300" />
            <div className="relative z-10 flex items-center gap-4">
              <div className="w-12 h-12 bg-gradient-to-r from-raffle-green to-raffle-green-light rounded-xl flex items-center justify-center">
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" className="text-white">
                  <path d="M3 20.5L13.09 10.41L3 0.5V20.5Z" fill="currentColor"/>
                  <path d="M16.58 8.42L13.09 10.41L16.58 12.4L21.5 10.41L16.58 8.42Z" fill="currentColor"/>
                  <path d="M3 20.5L13.09 10.41L16.58 12.4L21.5 10.41L13.09 20.5L3 20.5Z" fill="currentColor"/>
                  <path d="M13.09 10.41L3 0.5L16.58 8.42L21.5 10.41L13.09 10.41Z" fill="currentColor"/>
                </svg>
              </div>
              <div>
                <div className="text-sm text-gray-400">Disponible en</div>
                <div className="text-xl font-bold text-white">Google Play</div>
              </div>
            </div>
          </motion.a>
        </motion.div>

        {/* Sección de características móviles */}
        <motion.div
          initial={{ opacity: 0, y: 50 }}
          whileInView={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8, delay: 0.6 }}
          viewport={{ once: true }}
          className="relative"
        >
          <div className="absolute inset-0 bg-gradient-to-br from-white/5 to-white/2 rounded-3xl backdrop-blur-sm border border-white/10" />
          
          <div className="relative z-10 p-8 md:p-12">
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
              
              {/* Contenido */}
              <div>
                <div className="mb-6">
                  <div className="inline-flex items-center justify-center w-16 h-16 bg-gradient-to-r from-raffle-green to-raffle-green-light rounded-2xl mb-4">
                    <Smartphone size={28} className="text-white" />
                  </div>
                  <h3 className="text-3xl md:text-4xl font-bold text-white mb-4">
                    Optimizada para Móviles
                  </h3>
                  <p className="text-lg text-gray-300 leading-relaxed">
                    Interfaz diseñada específicamente para dispositivos móviles. 
                    Navegación intuitiva, controles táctiles optimizados y experiencia fluida.
                  </p>
                </div>

                <div className="space-y-4">
                  {[
                    'Interfaz adaptativa para todos los tamaños de pantalla',
                    'Gestos táctiles optimizados para máxima usabilidad',
                    'Rendimiento excepcional en dispositivos de gama baja',
                    'Modo offline completo sin dependencia de internet'
                  ].map((feature, index) => (
                    <motion.div
                      key={index}
                      initial={{ opacity: 0, x: -20 }}
                      whileInView={{ opacity: 1, x: 0 }}
                      transition={{ duration: 0.5, delay: 0.8 + index * 0.1 }}
                      viewport={{ once: true }}
                      className="flex items-center gap-3"
                    >
                      <div className="w-6 h-6 bg-gradient-to-r from-raffle-green to-raffle-green-light rounded-full flex items-center justify-center flex-shrink-0">
                        <svg width="12" height="12" viewBox="0 0 12 12" fill="none">
                          <path d="M3.5 6L5.5 8L8.5 4" stroke="white" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                        </svg>
                      </div>
                      <span className="text-gray-300">{feature}</span>
                    </motion.div>
                  ))}
                </div>
              </div>

              {/* Mockup del teléfono */}
              <div className="relative">
                <div className="relative mx-auto w-80 h-160">
                  {/* Teléfono */}
                  <div className="absolute inset-0 bg-gradient-to-br from-gray-800 to-gray-900 rounded-[3rem] border-4 border-gray-700 shadow-2xl">
                    {/* Pantalla */}
                    <div className="absolute inset-4 bg-gradient-to-br from-black to-gray-900 rounded-[2rem] overflow-hidden">
                      {/* Contenido simulado */}
                      <div className="p-6 h-full flex flex-col">
                        <div className="flex items-center justify-between mb-6">
                          <div className="w-8 h-8 bg-gradient-to-r from-raffle-green to-raffle-green-light rounded-lg" />
                          <div className="text-white font-bold text-lg">RaffleFlutter</div>
                          <div className="w-8 h-8 bg-gray-700 rounded-lg" />
                        </div>
                        
                        <div className="space-y-4 flex-1">
                          <div className="h-20 bg-gradient-to-r from-raffle-green/20 to-raffle-green-light/20 rounded-xl border border-raffle-green/30" />
                          <div className="h-16 bg-white/5 rounded-xl" />
                          <div className="h-16 bg-white/5 rounded-xl" />
                          <div className="h-16 bg-white/5 rounded-xl" />
                        </div>
                        
                        <div className="grid grid-cols-2 gap-2 mt-4">
                          <div className="h-8 bg-raffle-green/20 rounded-lg" />
                          <div className="h-8 bg-raffle-green/20 rounded-lg" />
                        </div>
                      </div>
                    </div>
                  </div>
                  
                  {/* Efectos de brillo */}
                  <div className="absolute inset-0 bg-gradient-to-tr from-transparent via-raffle-green/10 to-transparent rounded-[3rem] animate-pulse" />
                </div>
              </div>
            </div>
          </div>
        </motion.div>

        {/* Call to Action final */}
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          whileInView={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 1 }}
          viewport={{ once: true }}
          className="text-center mt-16"
        >
          <h3 className="text-2xl md:text-3xl font-bold text-white mb-4">
            ¿Qué estás esperando?
          </h3>
          <p className="text-gray-300 mb-8 max-w-2xl mx-auto">
            Únete a la revolución digital de las rifas. Es gratis, es rápido, y es el futuro.
          </p>
          <AnimatedButton
            size="lg"
            className="min-w-64"
          >
            <Download size={20} />
            Descargar Ahora
          </AnimatedButton>
        </motion.div>
      </div>
    </section>
  )
}

export default DownloadSection 