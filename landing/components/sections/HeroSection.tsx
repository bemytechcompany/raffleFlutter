'use client'

import React, { useEffect, useState } from 'react'
import { motion } from 'framer-motion'
import { ArrowRight, Zap, Sparkles, Download, Star } from 'lucide-react'
import { AnimatedButton } from '../ui/AnimatedButton'

const HeroSection = () => {
  const [mousePosition, setMousePosition] = useState({ x: 0, y: 0 })

  useEffect(() => {
    const handleMouseMove = (e: MouseEvent) => {
      setMousePosition({ x: e.clientX, y: e.clientY })
    }

    window.addEventListener('mousemove', handleMouseMove)
    return () => window.removeEventListener('mousemove', handleMouseMove)
  }, [])

  return (
    <section id="home" className="relative min-h-screen flex items-center justify-center overflow-hidden bg-black">
      {/* Fondo con efectos */}
      <div className="absolute inset-0">
        {/* Grid cyber animado */}
        <div className="absolute inset-0 cyber-grid opacity-20" />
        
        {/* Gradiente radial seguidor del mouse */}
        <div 
          className="absolute w-96 h-96 rounded-full bg-gradient-to-r from-raffle-green/20 to-raffle-green-light/20 blur-3xl transition-all duration-300"
          style={{
            left: mousePosition.x - 192,
            top: mousePosition.y - 192,
          }}
        />
        
        {/* Orbes flotantes */}
        <div className="absolute top-20 left-20 w-32 h-32 bg-raffle-green/10 rounded-full blur-2xl animate-float" />
        <div className="absolute bottom-20 right-20 w-48 h-48 bg-raffle-green-light/10 rounded-full blur-2xl animate-float" style={{ animationDelay: '2s' }} />
        <div className="absolute top-1/2 left-1/4 w-24 h-24 bg-raffle-green/15 rounded-full blur-xl animate-bounce-slow" />
        
        {/* Partículas */}
        {Array.from({ length: 20 }).map((_, i) => (
          <div
            key={i}
            className="absolute w-1 h-1 bg-raffle-green rounded-full animate-pulse"
            style={{
              left: `${Math.random() * 100}%`,
              top: `${Math.random() * 100}%`,
              animationDelay: `${Math.random() * 3}s`,
              animationDuration: `${2 + Math.random() * 2}s`,
            }}
          />
        ))}
      </div>

      {/* Contenido principal */}
      <div className="relative z-10 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
        <div className="max-w-4xl mx-auto">
          
          {/* Badge de lanzamiento */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5 }}
            className="mb-8"
          >
            <div className="inline-flex items-center gap-2 px-4 py-2 bg-gradient-to-r from-raffle-green/20 to-raffle-green-light/20 rounded-full border border-raffle-green/30 backdrop-blur-sm">
              <Sparkles size={16} className="text-raffle-green" />
              <span className="text-sm font-medium text-raffle-green">
                La Revolución de las Rifas ha Llegado
              </span>
              <div className="w-2 h-2 bg-raffle-green rounded-full animate-pulse" />
            </div>
          </motion.div>

          {/* Título principal */}
          <motion.h1
            initial={{ opacity: 0, y: 30 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.7, delay: 0.2 }}
            className="text-5xl md:text-7xl lg:text-8xl font-bold mb-6 leading-tight"
          >
            <span className="bg-gradient-to-r from-white via-raffle-green to-raffle-green-light bg-clip-text text-transparent">
              Raffle
            </span>
            <span className="text-white">Flutter</span>
          </motion.h1>

          {/* Subtítulo */}
          <motion.p
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6, delay: 0.4 }}
            className="text-xl md:text-2xl text-gray-300 mb-8 max-w-3xl mx-auto leading-relaxed"
          >
            La aplicación más avanzada para gestionar{' '}
            <span className="text-raffle-green font-semibold">rifas y sorteos</span> con 
            tecnología de vanguardia, diseño elegante y funcionalidades que revolucionan la experiencia.
          </motion.p>

          {/* Características destacadas */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6, delay: 0.6 }}
            className="flex flex-wrap justify-center gap-4 mb-12"
          >
            {[
              { icon: Zap, text: 'Súper Rápida' },
              { icon: Star, text: 'Intuitiva' },
              { icon: Sparkles, text: 'Tecnología Avanzada' },
            ].map((feature, index) => (
              <div key={index} className="flex items-center gap-2 px-4 py-2 bg-white/5 rounded-full backdrop-blur-sm border border-white/10">
                <feature.icon size={16} className="text-raffle-green" />
                <span className="text-sm font-medium text-white">{feature.text}</span>
              </div>
            ))}
          </motion.div>

          {/* Botones de acción */}
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6, delay: 0.8 }}
            className="flex flex-col sm:flex-row gap-4 justify-center items-center"
          >
            <AnimatedButton
              size="lg"
              onClick={() => document.getElementById('download')?.scrollIntoView({ behavior: 'smooth' })}
              className="min-w-64"
            >
              <Download size={20} />
              Descargar Ahora
              <ArrowRight size={20} />
            </AnimatedButton>
            
            <AnimatedButton
              variant="outline"
              size="lg"
              onClick={() => document.getElementById('features')?.scrollIntoView({ behavior: 'smooth' })}
              className="min-w-64"
            >
              <Sparkles size={20} />
              Ver Características
            </AnimatedButton>
          </motion.div>

          {/* Estadísticas */}
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6, delay: 1 }}
            className="mt-16 grid grid-cols-1 md:grid-cols-3 gap-8"
          >
            {[
              { number: '10K+', label: 'Usuarios Activos' },
              { number: '50K+', label: 'Rifas Creadas' },
              { number: '4.9★', label: 'Calificación' },
            ].map((stat, index) => (
              <div key={index} className="text-center">
                <div className="text-3xl md:text-4xl font-bold text-raffle-green mb-2">
                  {stat.number}
                </div>
                <div className="text-sm text-gray-400 uppercase tracking-wide">
                  {stat.label}
                </div>
              </div>
            ))}
          </motion.div>
        </div>

        {/* Scroll indicator: lo movemos aquí, fuera del contenido principal */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 1.5 }}
          className="mt-20 mb-16 flex flex-col items-center gap-2"
        >
          <span className="text-sm text-gray-400">Desliza para explorar</span>
          <div className="w-6 h-10 border-2 border-raffle-green/50 rounded-full flex justify-center">
            <motion.div
              animate={{ y: [0, 12, 0] }}
              transition={{ duration: 1.5, repeat: Infinity, ease: 'easeInOut' }}
              className="w-1 h-3 bg-raffle-green rounded-full mt-2"
            />
          </div>
        </motion.div>
      </div>
    </section>
  )
}

export default HeroSection 