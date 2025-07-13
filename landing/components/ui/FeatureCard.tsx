'use client'

import React from 'react'
import { motion } from 'framer-motion'
import { LucideIcon } from 'lucide-react'

interface FeatureCardProps {
  title: string
  description: string
  icon: LucideIcon
  delay?: number
  className?: string
}

export const FeatureCard: React.FC<FeatureCardProps> = ({
  title,
  description,
  icon: Icon,
  delay = 0,
  className = ''
}) => {
  return (
    <motion.div
      initial={{ opacity: 0, y: 50 }}
      whileInView={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.5, delay }}
      viewport={{ once: true }}
      whileHover={{ y: -10, scale: 1.02 }}
      className={`
        relative group cursor-pointer
        ${className}
      `}
    >
      {/* Fondo con efecto glassmorphism */}
      <div className="absolute inset-0 bg-gradient-to-br from-white/10 to-white/5 rounded-2xl backdrop-blur-sm border border-white/20 transition-all duration-300 group-hover:border-raffle-green/50" />
      
      {/* Efecto de brillo en hover */}
      <div className="absolute inset-0 bg-gradient-to-br from-raffle-green/10 to-transparent rounded-2xl opacity-0 group-hover:opacity-100 transition-opacity duration-300" />
      
      {/* Contenido */}
      <div className="relative z-10 p-8">
        {/* Icono */}
        <div className="mb-6">
          <div className="relative">
            <div className="w-16 h-16 bg-gradient-to-r from-raffle-green to-raffle-green-light rounded-2xl flex items-center justify-center shadow-lg group-hover:shadow-raffle-green/30 transition-shadow duration-300">
              <Icon size={28} className="text-white" />
            </div>
            
            {/* Efecto de pulso */}
            <div className="absolute inset-0 w-16 h-16 bg-gradient-to-r from-raffle-green to-raffle-green-light rounded-2xl blur opacity-20 animate-pulse" />
          </div>
        </div>

        {/* Título */}
        <h3 className="text-2xl font-bold text-white mb-4 group-hover:text-raffle-green transition-colors duration-300">
          {title}
        </h3>

        {/* Descripción */}
        <p className="text-gray-300 leading-relaxed group-hover:text-gray-200 transition-colors duration-300">
          {description}
        </p>

        {/* Línea decorativa */}
        <div className="mt-6 w-0 h-0.5 bg-gradient-to-r from-raffle-green to-raffle-green-light transition-all duration-300 group-hover:w-full" />
      </div>

      {/* Efectos adicionales */}
      <div className="absolute -top-px left-20 right-20 h-px bg-gradient-to-r from-transparent via-raffle-green to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-300" />
      <div className="absolute -bottom-px left-20 right-20 h-px bg-gradient-to-r from-transparent via-raffle-green to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-300" />
    </motion.div>
  )
} 