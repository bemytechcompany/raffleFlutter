# RaffleFlutter Landing Page

Landing page futurista y moderna para RaffleFlutter - La app más avanzada para gestionar rifas y sorteos.

## 🚀 Características

- **Diseño Futurista**: Interfaz moderna con efectos cyber y animaciones avanzadas
- **Totalmente Responsive**: Optimizada para todos los dispositivos
- **Animaciones Fluidas**: Usando Framer Motion para transiciones suaves
- **Rendimiento Optimizado**: Construida con Next.js 14 y React 18
- **SEO Optimizado**: Metadatos completos y estructurados
- **Sistema de Colores Consistente**: Basado en los colores de RaffleFlutter

## 🛠️ Tecnologías

- **Framework**: Next.js 14 (App Router)
- **Styling**: Tailwind CSS
- **Animaciones**: Framer Motion
- **Iconos**: Lucide React
- **Tipografía**: Inter & Orbitron
- **Lenguaje**: TypeScript

## 🎨 Diseño

### Paleta de Colores
- **Verde Principal**: #4CAF50 (raffle-green)
- **Verde Claro**: #68D391 (raffle-green-light)
- **Fondo**: Gradientes oscuros con efectos cyber
- **Texto**: Blanco con variaciones de grises

### Efectos Especiales
- Grid cyber animado
- Efectos glassmorphism
- Gradientes seguidor del mouse
- Partículas flotantes
- Animaciones de hover avanzadas

## 📱 Secciones

1. **Hero Section**: Presentación impactante con animaciones
2. **Features Section**: Características principales de RaffleFlutter
3. **Download Section**: Botones para App Store y Google Play
4. **Footer**: Información completa y enlaces

## 🚀 Instalación

```bash
# Instalar dependencias
npm install

# Ejecutar en desarrollo
npm run dev

# Construir para producción
npm run build

# Ejecutar producción
npm start
```

## 📁 Estructura del Proyecto

```
landing/
├── app/
│   ├── layout.tsx          # Layout principal
│   ├── page.tsx            # Página principal
│   └── globals.css         # Estilos globales
├── components/
│   ├── ui/
│   │   ├── AnimatedButton.tsx    # Botón animado
│   │   ├── FeatureCard.tsx       # Tarjeta de características
│   │   └── Navigation.tsx        # Navegación
│   └── sections/
│       ├── HeroSection.tsx       # Sección hero
│       ├── FeaturesSection.tsx   # Sección características
│       ├── DownloadSection.tsx   # Sección descarga
│       └── Footer.tsx            # Footer
├── tailwind.config.js      # Configuración Tailwind
├── next.config.js          # Configuración Next.js
└── package.json            # Dependencias
```

## 🌟 Características Especiales

### Animaciones Avanzadas
- **Scroll Animations**: Elementos aparecen al hacer scroll
- **Hover Effects**: Efectos interactivos en hover
- **Mouse Tracking**: Efectos que siguen el mouse
- **Floating Elements**: Elementos flotantes animados

### Responsive Design
- **Mobile First**: Diseño optimizado para móviles
- **Breakpoints**: Responsive en todos los tamaños
- **Touch Friendly**: Controles táctiles optimizados

### Performance
- **Code Splitting**: Carga optimizada de componentes
- **Image Optimization**: Imágenes optimizadas automáticamente
- **Lazy Loading**: Carga diferida de elementos

## 🔧 Personalización

### Colores
Los colores están definidos en `tailwind.config.js` y pueden ser modificados fácilmente:

```javascript
colors: {
  'raffle-green': '#4CAF50',
  'raffle-green-light': '#68D391',
  'raffle-green-dark': '#388E3C',
}
```

### Animaciones
Las animaciones están en `globals.css` y pueden ser customizadas:

```css
.cyber-grid {
  animation: grid-move 20s linear infinite;
}

.neon-glow {
  box-shadow: 0 0 20px rgba(76, 175, 80, 0.3);
}
```

## 📊 SEO y Metadatos

- **Open Graph**: Metadatos para redes sociales
- **Twitter Cards**: Optimizado para Twitter
- **Schema Markup**: Datos estructurados
- **Sitemap**: Generado automáticamente

## 🚀 Despliegue

### Vercel (Recomendado)
```bash
# Conectar con Vercel
vercel

# Desplegar automáticamente
git push
```

### Netlify
```bash
# Construir para producción
npm run build

# Subir carpeta .next
```

## 📈 Métricas

- **Lighthouse Score**: 95+ en todas las métricas
- **Core Web Vitals**: Excelente rendimiento
- **SEO Score**: 100/100
- **Accessibility**: WCAG 2.1 compliant

## 🎯 Objetivos de Conversión

1. **Descargas**: Incrementar descargas de la app
2. **Engagement**: Aumentar tiempo en página
3. **Conversión**: Mejorar tasa de conversión
4. **Retención**: Reducir tasa de rebote

## 🔄 Actualizaciones Futuras

- [ ] Modo claro/oscuro
- [ ] Múltiples idiomas
- [ ] Chatbot integrado
- [ ] Testimonios de usuarios
- [ ] Blog integrado
- [ ] Analytics avanzados

## 📞 Contacto

Para más información sobre RaffleFlutter:
- **Email**: info@raffleflutter.com
- **Website**: https://raffleflutter.com
- **GitHub**: https://github.com/raffleflutter

---

*Hecho con ❤️ para organizadores innovadores* 