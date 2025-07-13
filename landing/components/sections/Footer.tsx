'use client'

import React from 'react'
import { motion } from 'framer-motion'
import { 
  Zap, 
  Mail, 
  Twitter, 
  Instagram, 
  Facebook, 
  Github,
  Heart,
  ArrowUp
} from 'lucide-react'

const Footer = () => {
  const scrollToTop = () => {
    window.scrollTo({ top: 0, behavior: 'smooth' })
  }

  const footerLinks = {
    product: [
      { name: 'Características', href: '#features' },
      { name: 'Descargar', href: '#download' },
      { name: 'Soporte', href: '#support' },
      { name: 'FAQ', href: '#faq' },
    ],
    company: [
      { name: 'Sobre Nosotros', href: '#about' },
      { name: 'Blog', href: '#blog' },
      { name: 'Prensa', href: '#press' },
      { name: 'Carreras', href: '#careers' },
    ],
    legal: [
      { name: 'Privacidad', href: '#privacy' },
      { name: 'Términos', href: '#terms' },
      { name: 'Cookies', href: '#cookies' },
      { name: 'Seguridad', href: '#security' },
    ],
  }

  const socialLinks = [
    { icon: Twitter, href: '#twitter', label: 'Twitter' },
    { icon: Instagram, href: '#instagram', label: 'Instagram' },
    { icon: Facebook, href: '#facebook', label: 'Facebook' },
    { icon: Github, href: '#github', label: 'Github' },
  ]

  return (
    <footer className="relative bg-gradient-to-b from-black to-gray-900 border-t border-raffle-green/20">
      {/* Efectos de fondo */}
      <div className="absolute inset-0">
        <div className="absolute inset-0 bg-[radial-gradient(circle_at_50%_0%,rgba(76,175,80,0.05),transparent_50%)]" />
        <div className="absolute top-0 left-0 w-full h-px bg-gradient-to-r from-transparent via-raffle-green to-transparent" />
      </div>

      <div className="relative z-10 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        
        {/* Contenido principal del footer */}
        <div className="py-16">
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-8">
            
            {/* Información de la marca */}
            <div className="lg:col-span-2">
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.6 }}
                viewport={{ once: true }}
                className="mb-6"
              >
                <div className="flex items-center gap-2 mb-4">
                  <div className="relative">
                    <div className="w-10 h-10 bg-gradient-to-r from-raffle-green to-raffle-green-light rounded-lg flex items-center justify-center">
                      <Zap size={20} className="text-white" />
                    </div>
                    <div className="absolute inset-0 bg-gradient-to-r from-raffle-green to-raffle-green-light rounded-lg blur opacity-60 animate-pulse" />
                  </div>
                  <span className="text-2xl font-bold bg-gradient-to-r from-raffle-green to-raffle-green-light bg-clip-text text-transparent">
                    RaffleFlutter
                  </span>
                </div>
                <p className="text-gray-300 leading-relaxed mb-6">
                  La aplicación más avanzada para gestionar rifas y sorteos. 
                  Diseñada con tecnología de vanguardia para profesionales que buscan excelencia.
                </p>
                
                {/* Redes sociales */}
                <div className="flex gap-4">
                  {socialLinks.map((social, index) => (
                    <motion.a
                      key={index}
                      href={social.href}
                      whileHover={{ scale: 1.1, y: -2 }}
                      whileTap={{ scale: 0.9 }}
                      className="w-10 h-10 bg-gray-800 rounded-lg flex items-center justify-center hover:bg-raffle-green/20 hover:border-raffle-green/50 border border-gray-700 transition-all duration-300 group"
                      aria-label={social.label}
                    >
                      <social.icon size={18} className="text-gray-400 group-hover:text-raffle-green transition-colors duration-300" />
                    </motion.a>
                  ))}
                </div>
              </motion.div>
            </div>

            {/* Links del producto */}
            <div>
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.6, delay: 0.1 }}
                viewport={{ once: true }}
              >
                <h4 className="text-lg font-semibold text-white mb-4">Producto</h4>
                <ul className="space-y-2">
                  {footerLinks.product.map((link, index) => (
                    <li key={index}>
                      <a 
                        href={link.href}
                        className="text-gray-400 hover:text-raffle-green transition-colors duration-200 block py-1"
                      >
                        {link.name}
                      </a>
                    </li>
                  ))}
                </ul>
              </motion.div>
            </div>

            {/* Links de la empresa */}
            <div>
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.6, delay: 0.2 }}
                viewport={{ once: true }}
              >
                <h4 className="text-lg font-semibold text-white mb-4">Empresa</h4>
                <ul className="space-y-2">
                  {footerLinks.company.map((link, index) => (
                    <li key={index}>
                      <a 
                        href={link.href}
                        className="text-gray-400 hover:text-raffle-green transition-colors duration-200 block py-1"
                      >
                        {link.name}
                      </a>
                    </li>
                  ))}
                </ul>
              </motion.div>
            </div>

            {/* Links legales */}
            <div>
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.6, delay: 0.3 }}
                viewport={{ once: true }}
              >
                <h4 className="text-lg font-semibold text-white mb-4">Legal</h4>
                <ul className="space-y-2">
                  {footerLinks.legal.map((link, index) => (
                    <li key={index}>
                      <a 
                        href={link.href}
                        className="text-gray-400 hover:text-raffle-green transition-colors duration-200 block py-1"
                      >
                        {link.name}
                      </a>
                    </li>
                  ))}
                </ul>
              </motion.div>
            </div>
          </div>
        </div>

        {/* Newsletter */}
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          whileInView={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.4 }}
          viewport={{ once: true }}
          className="border-t border-gray-800 py-8"
        >
          <div className="max-w-2xl mx-auto text-center">
            <h3 className="text-2xl font-bold text-white mb-2">
              Mantente al día con las novedades
            </h3>
            <p className="text-gray-400 mb-6">
              Recibe actualizaciones sobre nuevas características y mejoras.
            </p>
            <div className="flex flex-col sm:flex-row gap-4 max-w-md mx-auto">
              <input
                type="email"
                placeholder="Tu email"
                className="flex-1 px-4 py-3 bg-gray-800 border border-gray-700 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:border-raffle-green focus:ring-1 focus:ring-raffle-green transition-all duration-300"
              />
              <motion.button
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
                className="px-6 py-3 bg-gradient-to-r from-raffle-green to-raffle-green-light text-white font-semibold rounded-lg hover:shadow-lg hover:shadow-raffle-green/30 transition-all duration-300"
              >
                Suscribirse
              </motion.button>
            </div>
          </div>
        </motion.div>

        {/* Línea divisoria */}
        <div className="border-t border-gray-800" />

        {/* Copyright */}
        <div className="py-6">
          <div className="flex flex-col md:flex-row items-center justify-between gap-4">
            <motion.div
              initial={{ opacity: 0 }}
              whileInView={{ opacity: 1 }}
              transition={{ duration: 0.6, delay: 0.5 }}
              viewport={{ once: true }}
              className="flex items-center gap-2 text-gray-400"
            >
              <span>© 2025 RaffleFlutter. Hecho con</span>
              <Heart size={16} className="text-raffle-green animate-pulse" />
              <span>para organizadores innovadores producto de Bemytech.</span>
            </motion.div>
            
            <motion.button
              onClick={scrollToTop}
              whileHover={{ scale: 1.1, y: -2 }}
              whileTap={{ scale: 0.9 }}
              className="w-10 h-10 bg-raffle-green/20 rounded-full flex items-center justify-center hover:bg-raffle-green/30 transition-all duration-300 group"
              aria-label="Volver arriba"
            >
              <ArrowUp size={18} className="text-raffle-green group-hover:text-white transition-colors duration-300" />
            </motion.button>
          </div>
        </div>
      </div>
    </footer>
  )
}

export default Footer 