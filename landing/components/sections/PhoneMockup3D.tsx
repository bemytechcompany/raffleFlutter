'use client'

import React, { useState, useEffect, useRef } from 'react'
import { motion, AnimatePresence, useScroll, useTransform } from 'framer-motion'
import { ChevronLeft, ChevronRight, Play, Pause, Maximize2, RotateCcw, Eye, EyeOff } from 'lucide-react'
import FeatureOrbs from './FeatureOrbs'

const PhoneMockup3D = () => {
  const [currentIndex, setCurrentIndex] = useState(0)
  const [isAutoPlaying, setIsAutoPlaying] = useState(true)
  const [isHovered, setIsHovered] = useState(false)
  const [isRotating, setIsRotating] = useState(false)
  const [showFeatureOrbs, setShowFeatureOrbs] = useState(true)
  const [mousePosition, setMousePosition] = useState({ x: 0, y: 0 })
  const containerRef = useRef<HTMLDivElement>(null)
  const { scrollYProgress } = useScroll()
  const rotateX = useTransform(scrollYProgress, [0, 1], [0, 360])

  // Array de imágenes (1.jpg hasta 15.jpg) con descripciones mejoradas
  const screenshots = Array.from({ length: 15 }, (_, i) => ({
    id: i + 1,
    src: `/${i + 1}.jpg`,
    alt: `Captura de pantalla ${i + 1}`,
    title: getScreenTitle(i + 1),
    description: getScreenDescription(i + 1)
  }))

  // Función para obtener títulos de pantalla
  function getScreenTitle(index: number): string {
    const titles = [
      'Pantalla de Inicio',
      'Detalles de Ticket',
      'Vista Previa',
      'Resumen Financiero',
      'Grilla de Tickets',
      'Lista de Compradores',
      'Exportar Datos',
      'Compartir Rifa',
      'Personalización',
      'Configuración Premium',
      'Imagen de Fondo',
      'Página de Sorteos',
      'Agregar Participante',
      'Sorteo Activo',
      'Ganador Seleccionado'
    ]
    return titles[index - 1] || `Pantalla ${index}`
  }

  // Función para obtener descripciones de pantalla
  function getScreenDescription(index: number): string {
    const descriptions = [
      'Interfaz principal con logo y navegación',
      'Gestión completa de tickets individuales',
      'Vista previa antes de confirmar cambios',
      'Análisis detallado de ventas y ganancias',
      'Visualización interactiva de todos los tickets',
      'Información completa de compradores',
      'Exportación de datos en múltiples formatos',
      'Opciones avanzadas de personalización',
      'Configuración de apariencia y colores',
      'Funciones premium desbloqueadas',
      'Personalización con imágenes de fondo',
      'Gestión de sorteos y participantes',
      'Agregar nuevos participantes fácilmente',
      'Sorteo en tiempo real con animaciones',
      'Celebración del ganador seleccionado'
    ]
    return descriptions[index - 1] || `Funcionalidad ${index}`
  }

  // Auto-play functionality
  useEffect(() => {
    if (!isAutoPlaying || isHovered) return

    const interval = setInterval(() => {
      setCurrentIndex((prev) => (prev + 1) % screenshots.length)
    }, 4000)

    return () => clearInterval(interval)
  }, [isAutoPlaying, isHovered, screenshots.length])

  // Mouse tracking for 3D effects
  useEffect(() => {
    const handleMouseMove = (e: MouseEvent) => {
      if (containerRef.current) {
        const rect = containerRef.current.getBoundingClientRect()
        const x = ((e.clientX - rect.left) / rect.width - 0.5) * 2
        const y = ((e.clientY - rect.top) / rect.height - 0.5) * 2
        setMousePosition({ x, y })
      }
    }

    const container = containerRef.current
    if (container) {
      container.addEventListener('mousemove', handleMouseMove)
      return () => container.removeEventListener('mousemove', handleMouseMove)
    }
  }, [])

  // Auto-rotation effect
  useEffect(() => {
    if (!isRotating) return

    const interval = setInterval(() => {
      setCurrentIndex((prev) => (prev + 1) % screenshots.length)
    }, 2000)

    return () => clearInterval(interval)
  }, [isRotating, screenshots.length])

  const nextSlide = () => {
    setCurrentIndex((prev) => (prev + 1) % screenshots.length)
  }

  const prevSlide = () => {
    setCurrentIndex((prev) => (prev - 1 + screenshots.length) % screenshots.length)
  }

  const goToSlide = (index: number) => {
    setCurrentIndex(index)
  }

  const toggleRotation = () => {
    setIsRotating(!isRotating)
  }

  const toggleFeatureOrbs = () => {
    setShowFeatureOrbs(!showFeatureOrbs)
  }

  // Calculamos los índices para las imágenes visibles
  const getVisibleIndices = () => {
    const indices = []
    for (let i = -2; i <= 2; i++) {
      indices.push((currentIndex + i + screenshots.length) % screenshots.length)
    }
    return indices
  }

  return (
    <div 
      ref={containerRef}
      className="relative w-full max-w-6xl mx-auto h-[1000px] perspective-1000 overflow-hidden"
      style={{
        transform: `rotateX(${mousePosition.y * 2}deg) rotateY(${mousePosition.x * 2}deg)`,
        transition: 'transform 0.15s ease-out'
      }}
    >
      {/* Fondo con efectos mejorados */}
      <div className="absolute inset-0 bg-gradient-to-br from-raffle-green/5 to-raffle-green-light/5 rounded-3xl" />
      <div className="absolute inset-0 bg-[radial-gradient(circle_at_center,rgba(76,175,80,0.1),transparent_70%)]" />
      
      {/* Efectos de luces dinámicas */}
      <div className="absolute inset-0">
        <div 
          className="absolute w-48 h-48 bg-raffle-green/15 rounded-full blur-3xl animate-pulse"
          style={{
            left: `${50 + mousePosition.x * 8}%`,
            top: `${50 + mousePosition.y * 8}%`,
            transform: 'translate(-50%, -50%)'
          }}
        />
        <div 
          className="absolute w-24 h-24 bg-raffle-green-light/20 rounded-full blur-2xl animate-pulse"
          style={{
            left: `${30 - mousePosition.x * 4}%`,
            top: `${70 - mousePosition.y * 4}%`,
            transform: 'translate(-50%, -50%)',
            animationDelay: '1s'
          }}
        />
      </div>

      {/* Layout organizado en 3 secciones */}
      <div className="relative w-full h-full flex flex-col">
        {/* Sección 1: Información de la captura actual - Arriba derecha */}
        <div className="absolute top-10 right-6 z-20">
          <motion.div
            key={currentIndex}
            initial={{ opacity: 0, y: 15 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.3 }}
            className="text-center max-w-sm"
          >
            <div className="bg-black/40 backdrop-blur-sm rounded-xl px-5 py-3 border border-white/10 shadow-xl">
              <div className="flex items-center justify-center gap-2 mb-1">
                <div className="w-1.5 h-1.5 bg-raffle-green rounded-full animate-pulse" />
                <p className="text-white font-bold text-base">
                  {screenshots[currentIndex].title}
                </p>
                <div className="w-1.5 h-1.5 bg-raffle-green rounded-full animate-pulse" />
              </div>
              <p className="text-raffle-green text-xs mb-2 leading-relaxed">
                {screenshots[currentIndex].description}
              </p>
              <div className="flex items-center justify-center gap-1.5 text-xs text-gray-400">
                <span>{currentIndex + 1}/{screenshots.length}</span>
                <span>•</span>
                <span>{isAutoPlaying ? 'Auto' : 'Manual'}</span>
                {isRotating && (
                  <>
                    <span>•</span>
                    <span className="text-raffle-green">Rotando</span>
                  </>
                )}
                {showFeatureOrbs && (
                  <>
                    <span>•</span>
                    <span className="text-raffle-green">Características</span>
                  </>
                )}
              </div>
            </div>
          </motion.div>
        </div>

        {/* Sección 2: Contenedor del teléfono - Centro */}
        <div 
          className="flex-1 flex items-center justify-center px-4 "
          onMouseEnter={() => setIsHovered(true)}
          onMouseLeave={() => setIsHovered(false)}
        >
          {/* Esferas flotantes de características */}
          {showFeatureOrbs && <FeatureOrbs />}
          
          {/* Carousel 3D mejorado */}
          <div 
            className="relative w-80 h-80 preserve-3d z-10"
            style={{
              transform: `rotateY(${isRotating ? rotateX : 0}deg)`,
              transition: 'transform 0.5s ease-out'
            }}
          >
          {getVisibleIndices().map((imageIndex, position) => {
            const isCenter = position === 2
            const distance = position - 2
            
            return (
              <motion.div
                key={`${imageIndex}-${position}`}
                className="absolute inset-0 preserve-3d cursor-pointer group"
                style={{
                  transform: `translateZ(${distance * -180}px) translateX(${distance * 130}px) rotateY(${distance * -25}deg)`,
                  zIndex: isCenter ? 100 : 50 - Math.abs(distance)
                }}
                animate={{
                  scale: isCenter ? 1 : 0.75,
                  opacity: isCenter ? 1 : 0.4
                }}
                transition={{
                  type: "spring",
                  stiffness: 350,
                  damping: 30
                }}
                onClick={() => !isCenter && goToSlide(imageIndex)}
                whileHover={{ scale: isCenter ? 1.02 : 0.8 }}
              >
                {/* Mockup del teléfono mejorado */}
                <div className="relative w-72 h-[580px] mx-auto">
                  {/* Sombra dinámica del teléfono */}
                  <div 
                    className="absolute inset-0 bg-black/30 rounded-[2.5rem] blur-2xl transform translate-y-6 scale-105"
                    style={{
                      transform: `translateY(${6 + mousePosition.y * 3}px) scale(${1.05 + Math.abs(mousePosition.x) * 0.02})`
                    }}
                  />
                  
                  {/* Teléfono con efectos avanzados */}
                  <div className="relative w-full h-full bg-gradient-to-br from-gray-900 via-gray-800 to-black rounded-[2.5rem] border-3 border-gray-700 shadow-2xl overflow-hidden group">
                    {/* Borde brillante */}
                    <div className="absolute inset-0 rounded-[2.5rem] bg-gradient-to-r from-raffle-green/20 via-transparent to-raffle-green-light/20 p-1 opacity-0 group-hover:opacity-100 transition-opacity duration-500">
                      <div className="w-full h-full bg-gradient-to-br from-gray-900 to-black rounded-[2rem]" />
                    </div>

                    {/* Notch mejorado */}
                    <div className="absolute top-3 left-1/2 transform -translate-x-1/2 w-28 h-5 bg-black rounded-full z-20 shadow-inner border border-gray-700" />
                    
                    {/* Botones laterales */}
                    <div className="absolute left-0 top-16 w-1 h-10 bg-gray-600 rounded-r-full" />
                    <div className="absolute left-0 top-28 w-1 h-6 bg-gray-600 rounded-r-full" />
                    <div className="absolute left-0 top-36 w-1 h-6 bg-gray-600 rounded-r-full" />
                    <div className="absolute right-0 top-16 w-1 h-12 bg-gray-600 rounded-l-full" />
                    
                    {/* Pantalla con efectos - más padding para evitar cortes */}
                    <div className="absolute inset-4 bg-black rounded-[2rem] overflow-hidden">
                      <motion.img
                        src={screenshots[imageIndex].src}
                        alt={screenshots[imageIndex].alt}
                        className="w-full h-full object-contain bg-black"
                        initial={{ scale: 1.02, opacity: 0, rotateY: 45 }}
                        animate={{ scale: 1, opacity: 1, rotateY: 0 }}
                        exit={{ scale: 0.98, opacity: 0, rotateY: -45 }}
                        transition={{ duration: 0.5, ease: "easeInOut" }}
                      />
                      
                      {/* Overlay con reflejo */}
                      <div className="absolute inset-0 bg-gradient-to-br from-white/3 via-transparent to-transparent pointer-events-none" />
                      <div className="absolute inset-0 bg-gradient-to-t from-black/10 via-transparent to-black/5 pointer-events-none" />
                      
                      {/* Efecto de pantalla sutil */}
                      <div className="absolute inset-0 bg-gradient-to-r from-transparent via-white/3 to-transparent transform -skew-x-12 animate-pulse opacity-20" />
                    </div>

                    {/* Efectos de brillo mejorados */}
                    <div className="absolute inset-0 bg-gradient-to-tr from-transparent via-white/10 to-transparent rounded-[3rem] animate-pulse" />
                    <div className="absolute top-0 left-0 w-full h-1/3 bg-gradient-to-b from-white/5 to-transparent rounded-t-[3rem]" />
                    
                    {/* Efecto holográfico avanzado */}
                    <div className="absolute inset-0 bg-gradient-to-br from-raffle-green/20 via-transparent to-raffle-green-light/20 rounded-[3rem] opacity-0 group-hover:opacity-100 transition-opacity duration-700" />
                    
                    {/* Líneas de datos */}
                    <div className="absolute inset-0 pointer-events-none">
                      {[...Array(3)].map((_, i) => (
                        <div
                          key={i}
                          className="absolute w-full h-px bg-gradient-to-r from-transparent via-raffle-green/30 to-transparent"
                          style={{
                            top: `${30 + i * 20}%`,
                            animation: `slideRight 2s ease-in-out infinite ${i * 0.5}s`
                          }}
                        />
                      ))}
                    </div>
                  </div>

                  {/* Partículas flotantes sutiles */}
                  {isCenter && (
                    <div className="absolute inset-0 pointer-events-none">
                      {[...Array(8)].map((_, i) => (
                        <motion.div
                          key={i}
                          className="absolute w-2 h-2 bg-gradient-to-r from-raffle-green to-raffle-green-light rounded-full"
                          style={{
                            left: `${20 + Math.random() * 60}%`,
                            top: `${20 + Math.random() * 60}%`,
                          }}
                          animate={{
                            y: [0, -20, 0],
                            x: [0, Math.random() * 15 - 7.5, 0],
                            opacity: [0.3, 0.8, 0.3],
                            scale: [0.5, 1, 0.5],
                          }}
                          transition={{
                            duration: 4 + Math.random() * 2,
                            repeat: Infinity,
                            delay: Math.random() * 2,
                            ease: "easeInOut"
                          }}
                        />
                      ))}
                    </div>
                  )}
                  
                  {/* Ondas de energía sutiles */}
                  {isCenter && (
                    <div className="absolute inset-0 pointer-events-none">
                      {[...Array(2)].map((_, i) => (
                        <motion.div
                          key={i}
                          className="absolute inset-0 border border-raffle-green/20 rounded-[2.5rem]"
                          animate={{
                            scale: [1, 1.3, 1],
                            opacity: [0.3, 0, 0.3],
                          }}
                          transition={{
                            duration: 3,
                            repeat: Infinity,
                            delay: i * 1.5,
                            ease: "easeInOut"
                          }}
                        />
                      ))}
                    </div>
                  )}
                </div>
              </motion.div>
            )
          })}
        </div>
        </div>

        {/* Sección 3: Controles - Abajo con margen reducido */}
        <div className="relative pb-6 pt-4">
          <div className="flex flex-col items-center gap-3">
            {/* Indicadores mejorados */}
            <div className="flex gap-1.5 bg-black/30 backdrop-blur-sm rounded-full px-3 py-2 border border-white/10">
              {screenshots.map((_, index) => (
                <motion.button
                  key={index}
                  onClick={() => goToSlide(index)}
                  className={`w-1.5 h-1.5 rounded-full transition-all duration-300 ${
                    index === currentIndex
                      ? 'bg-raffle-green scale-125 shadow-lg shadow-raffle-green/50'
                      : 'bg-white/30 hover:bg-white/50'
                  }`}
                  whileHover={{ scale: 1.5 }}
                  whileTap={{ scale: 0.8 }}
                />
              ))}
            </div>

            {/* Botones de control */}
            <div className="flex items-center gap-3">
              {/* Botón anterior */}
              <motion.button
                onClick={prevSlide}
                className="p-2.5 bg-white/10 backdrop-blur-sm rounded-full border border-white/20 hover:bg-raffle-green/20 transition-all duration-300 group"
                whileHover={{ scale: 1.1 }}
                whileTap={{ scale: 0.9 }}
              >
                <ChevronLeft size={18} className="text-white group-hover:text-raffle-green transition-colors" />
              </motion.button>

              {/* Botón de play/pause */}
              <motion.button
                onClick={() => setIsAutoPlaying(!isAutoPlaying)}
                className="p-2.5 bg-white/10 backdrop-blur-sm rounded-full border border-white/20 hover:bg-raffle-green/20 transition-all duration-300 group"
                whileHover={{ scale: 1.1 }}
                whileTap={{ scale: 0.9 }}
              >
                {isAutoPlaying ? (
                  <Pause size={14} className="text-white group-hover:text-raffle-green transition-colors" />
                ) : (
                  <Play size={14} className="text-white group-hover:text-raffle-green transition-colors" />
                )}
              </motion.button>

              {/* Botón de rotación */}
              <motion.button
                onClick={toggleRotation}
                className={`p-2.5 backdrop-blur-sm rounded-full border transition-all duration-300 group ${
                  isRotating 
                    ? 'bg-raffle-green/20 border-raffle-green/50' 
                    : 'bg-white/10 border-white/20 hover:bg-raffle-green/20'
                }`}
                whileHover={{ scale: 1.1 }}
                whileTap={{ scale: 0.9 }}
              >
                <RotateCcw size={14} className={`transition-colors ${
                  isRotating ? 'text-raffle-green' : 'text-white group-hover:text-raffle-green'
                }`} />
              </motion.button>

              {/* Botón de mostrar/ocultar esferas */}
              <motion.button
                onClick={toggleFeatureOrbs}
                className={`p-2.5 backdrop-blur-sm rounded-full border transition-all duration-300 group ${
                  showFeatureOrbs 
                    ? 'bg-raffle-green/20 border-raffle-green/50' 
                    : 'bg-white/10 border-white/20 hover:bg-raffle-green/20'
                }`}
                whileHover={{ scale: 1.1 }}
                whileTap={{ scale: 0.9 }}
              >
                {showFeatureOrbs ? (
                  <Eye size={14} className="text-raffle-green" />
                ) : (
                  <EyeOff size={14} className="text-white group-hover:text-raffle-green transition-colors" />
                )}
              </motion.button>

              {/* Botón siguiente */}
              <motion.button
                onClick={nextSlide}
                className="p-2.5 bg-white/10 backdrop-blur-sm rounded-full border border-white/20 hover:bg-raffle-green/20 transition-all duration-300 group"
                whileHover={{ scale: 1.1 }}
                whileTap={{ scale: 0.9 }}
              >
                <ChevronRight size={18} className="text-white group-hover:text-raffle-green transition-colors" />
              </motion.button>
            </div>
          </div>
        </div>
      </div>

      {/* Efectos de fondo adicionales */}
      <div className="absolute inset-0 pointer-events-none">
        <div className="absolute top-1/4 left-1/4 w-24 h-24 bg-raffle-green/8 rounded-full blur-3xl animate-pulse" />
        <div className="absolute bottom-1/4 right-1/4 w-20 h-20 bg-raffle-green-light/8 rounded-full blur-2xl animate-pulse" style={{ animationDelay: '1s' }} />
        <div className="absolute top-3/4 left-1/2 w-16 h-16 bg-raffle-green/5 rounded-full blur-xl animate-pulse" style={{ animationDelay: '2s' }} />
      </div>

      {/* Grid de fondo futurista */}
      <div className="absolute inset-0 opacity-20 pointer-events-none">
        <div className="w-full h-full bg-gradient-to-r from-transparent via-raffle-green/5 to-transparent animate-pulse"></div>
      </div>

      {/* Estilos CSS integrados */}
      <style jsx>{`
        @keyframes slideRight {
          0% {
            transform: translateX(-100%);
          }
          100% {
            transform: translateX(100%);
          }
        }
        
        @keyframes float {
          0%, 100% {
            transform: translateY(0px);
          }
          50% {
            transform: translateY(-10px);
          }
        }
        
        @keyframes glow {
          0%, 100% {
            box-shadow: 0 0 20px rgba(76, 175, 80, 0.3);
          }
          50% {
            box-shadow: 0 0 40px rgba(76, 175, 80, 0.6);
          }
        }
        
        .perspective-1000 {
          perspective: 1000px;
        }
        
        .preserve-3d {
          transform-style: preserve-3d;
        }
        
        .backface-hidden {
          backface-visibility: hidden;
        }
      `}</style>
    </div>
  )
}

export default PhoneMockup3D 