'use client'

import React from 'react'
import { motion } from 'framer-motion'
import { 
  Zap, 
  Shield, 
  Users, 
  Smartphone, 
  Download, 
  Share2, 
  Star,
  Heart,
  TrendingUp,
  Clock
} from 'lucide-react'

interface FeatureOrbProps {
  icon: React.ElementType
  title: string
  description: string
  color: string
  position: { x: number; y: number }
  delay: number
}

const FeatureOrb: React.FC<FeatureOrbProps> = ({ 
  icon: Icon, 
  title, 
  description, 
  color, 
  position, 
  delay 
}) => {
  return (
    <motion.div
      initial={{ opacity: 0, scale: 0, x: 0, y: 0 }}
      animate={{ 
        opacity: 1, 
        scale: 1, 
        x: position.x, 
        y: position.y,
        rotate: [0, 360]
      }}
      transition={{ 
        duration: 0.8, 
        delay,
        rotate: {
          duration: 20,
          repeat: Infinity,
          ease: "linear"
        }
      }}
      className="absolute group cursor-pointer"
      style={{ left: '50%', top: '50%' }}
    >
      <div className="relative">
        {/* Orb principal */}
        <div className={`w-12 h-12 ${color} rounded-full shadow-lg backdrop-blur-sm border border-white/15 flex items-center justify-center transform -translate-x-1/2 -translate-y-1/2 group-hover:scale-110 transition-all duration-300`}>
          <Icon size={18} className="text-white" />
          
          {/* Efecto de brillo */}
          <div className="absolute inset-0 rounded-full bg-gradient-to-r from-white/15 to-transparent animate-pulse opacity-40" />
          
          {/* Ondas concéntricas */}
          <div className="absolute inset-0 rounded-full border border-white/15 scale-125 animate-ping opacity-15" />
          <div className="absolute inset-0 rounded-full border border-white/10 scale-150 animate-ping opacity-10" style={{ animationDelay: '0.5s' }} />
        </div>

        {/* Tooltip */}
        <div className="absolute bottom-full left-1/2 transform -translate-x-1/2 mb-2 opacity-0 group-hover:opacity-100 transition-opacity duration-300 pointer-events-none">
          <div className="bg-black/90 backdrop-blur-sm rounded-lg px-2 py-1.5 text-center border border-white/15">
            <p className="text-white font-medium text-xs whitespace-nowrap">{title}</p>
            <p className="text-gray-300 text-xs mt-0.5 max-w-24">{description}</p>
          </div>
        </div>

        {/* Partículas orbilantes */}
        {[...Array(2)].map((_, i) => (
          <motion.div
            key={i}
            className="absolute w-1.5 h-1.5 bg-white/40 rounded-full"
            style={{
              left: '50%',
              top: '50%',
            }}
            animate={{
              x: Math.cos((i * 180 * Math.PI) / 180) * 30,
              y: Math.sin((i * 180 * Math.PI) / 180) * 30,
              rotate: 360,
            }}
            transition={{
              duration: 6 + i,
              repeat: Infinity,
              ease: "linear",
            }}
          />
        ))}
      </div>
    </motion.div>
  )
}

const FeatureOrbs = () => {
  const features = [
          {
        icon: Zap,
        title: "Súper Rápido",
        description: "Rendimiento optimizado",
        color: "bg-yellow-500/15",
        position: { x: -180, y: -80 },
        delay: 0.2
      },
      {
        icon: Shield,
        title: "Seguro",
        description: "Datos protegidos",
        color: "bg-green-500/15",
        position: { x: 180, y: -80 },
        delay: 0.4
      },
      {
        icon: Users,
        title: "Colaborativo",
        description: "Trabajo en equipo",
        color: "bg-blue-500/15",
        position: { x: -220, y: 40 },
        delay: 0.6
      },
      {
        icon: Smartphone,
        title: "Móvil First",
        description: "Diseño responsivo",
        color: "bg-purple-500/15",
        position: { x: 220, y: 40 },
        delay: 0.8
      },
      {
        icon: Download,
        title: "Offline",
        description: "Funciona sin internet",
        color: "bg-indigo-500/15",
        position: { x: -120, y: 120 },
        delay: 1.0
      },
      {
        icon: Share2,
        title: "Compartir",
        description: "Fácil distribución",
        color: "bg-pink-500/15",
        position: { x: 120, y: 120 },
        delay: 1.2
      },
      {
        icon: Star,
        title: "Premium",
        description: "Características avanzadas",
        color: "bg-orange-500/15",
        position: { x: 0, y: -160 },
        delay: 1.4
      },
      {
        icon: Heart,
        title: "Intuitivo",
        description: "Fácil de usar",
        color: "bg-red-500/15",
        position: { x: 0, y: 160 },
        delay: 1.6
      }
  ]

  return (
    <div className="absolute inset-0 pointer-events-none overflow-hidden">
      {features.map((feature, index) => (
        <FeatureOrb
          key={index}
          icon={feature.icon}
          title={feature.title}
          description={feature.description}
          color={feature.color}
          position={feature.position}
          delay={feature.delay}
        />
      ))}
      
      {/* Líneas de conexión animadas */}
      <svg className="absolute inset-0 w-full h-full opacity-20">
        <defs>
          <linearGradient id="lineGradient" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" stopColor="#4CAF50" stopOpacity="0.8" />
            <stop offset="100%" stopColor="#68D391" stopOpacity="0.2" />
          </linearGradient>
        </defs>
        
        {/* Líneas conectoras */}
        {features.map((_, index) => (
          <motion.line
            key={index}
            x1="50%"
            y1="50%"
            x2={`${50 + (features[index].position.x / 10)}%`}
            y2={`${50 + (features[index].position.y / 10)}%`}
            stroke="url(#lineGradient)"
            strokeWidth="1"
            strokeDasharray="5,5"
            initial={{ pathLength: 0, opacity: 0 }}
            animate={{ pathLength: 1, opacity: 0.5 }}
            transition={{ 
              duration: 2, 
              delay: features[index].delay + 0.5,
              ease: "easeInOut"
            }}
          />
        ))}
      </svg>
    </div>
  )
}

export default FeatureOrbs 