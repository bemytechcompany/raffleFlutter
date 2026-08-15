'use client'

import React from 'react'
import { motion } from 'framer-motion'

interface AnimatedButtonProps {
  children: React.ReactNode
  onClick?: () => void
  variant?: 'primary' | 'secondary' | 'outline'
  size?: 'sm' | 'md' | 'lg'
  className?: string
  disabled?: boolean
  href?: string
  target?: string
}

export const AnimatedButton: React.FC<AnimatedButtonProps> = ({
  children,
  onClick,
  variant = 'primary',
  size = 'md',
  className = '',
  disabled = false,
  href,
  target
}) => {
  const baseClasses = `
    relative overflow-hidden font-semibold transition-all duration-300 
    transform hover:scale-105 active:scale-95 cursor-pointer
    border-2 rounded-lg flex items-center justify-center gap-2
    font-cyber tracking-wide uppercase
  `

  const variants = {
    primary: `
      bg-gradient-to-r from-raffle-green to-raffle-green-light
      border-raffle-green text-white hover:from-raffle-green-light hover:to-raffle-green
      shadow-lg hover:shadow-raffle-green/50 hover:shadow-xl
      before:absolute before:inset-0 before:bg-gradient-to-r before:from-transparent 
      before:via-white/20 before:to-transparent before:translate-x-[-100%] 
      hover:before:translate-x-[100%] before:transition-transform before:duration-700
    `,
    secondary: `
      bg-gradient-to-r from-gray-800 to-gray-700
      border-gray-600 text-white hover:from-gray-700 hover:to-gray-600
      shadow-lg hover:shadow-gray-500/30 hover:shadow-xl
    `,
    outline: `
      bg-transparent border-raffle-green text-raffle-green
      hover:bg-raffle-green hover:text-white
      shadow-lg hover:shadow-raffle-green/30 hover:shadow-xl
    `
  }

  const sizes = {
    sm: 'px-4 py-2 text-sm',
    md: 'px-6 py-3 text-base',
    lg: 'px-8 py-4 text-lg'
  }

  const combinedClasses = `
    ${baseClasses}
    ${variants[variant]}
    ${sizes[size]}
    ${disabled ? 'opacity-50 cursor-not-allowed' : ''}
    ${className}
  `

  const Component = href ? 'a' : 'button'

  return (
    <motion.div
      whileHover={{ scale: 1.05 }}
      whileTap={{ scale: 0.95 }}
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.3 }}
    >
      <Component
        className={combinedClasses}
        onClick={onClick}
        disabled={disabled}
        href={href}
        target={target}
        rel={target === '_blank' ? 'noopener noreferrer' : undefined}
      >
        {/* Efecto de brillo */}
        <div className="absolute inset-0 bg-gradient-to-r from-transparent via-white/10 to-transparent translate-x-[-100%] hover:translate-x-[100%] transition-transform duration-700" />
        
        {/* Contenido del botón */}
        <span className="relative z-10 flex items-center gap-2">
          {children}
        </span>
      </Component>
    </motion.div>
  )
} 