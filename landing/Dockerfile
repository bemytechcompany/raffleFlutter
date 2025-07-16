# ---------------------------------------------------------
# Dockerfile para el proyecto "landing" (Next.js 14)
# Optimizado para despliegue en Coolify utilizando multi-stage
# build y teniendo en cuenta las variables de entorno que
# comienzan por NEXT_PUBLIC_.
# ---------------------------------------------------------

###############
#   BUILDER   #
###############
FROM node:20-alpine AS builder

# Directorio de trabajo
WORKDIR /app

# Copiamos los archivos que definen las dependencias antes que
# el resto para aprovechar la cache de Docker si el package.json
#/lock no cambia.
COPY landing/package.json landing/package-lock.json* ./

# Instalamos TODAS las dependencias (incluidas dev-deps) porque
# son necesarias para generar el build de Next.js.
RUN npm ci --include-workspace-root

# Copiamos el resto del código fuente de la aplicación.
COPY landing/ .

# ---------------------------------------------------------
# Variables de entorno públicas
# ---------------------------------------------------------
# Todas las variables que empiecen por NEXT_PUBLIC_ deben estar
# disponibles en tiempo de *build* para que Next.js las "inyecte"
# en el código del cliente. Las declaramos como ARG para que
# Coolify pueda suministrarlas en la sección "Build Secrets" o
# "Build Args".
ARG NEXT_PUBLIC_NAME_APP
ARG NEXT_PUBLIC_LINK_IOS
ARG NEXT_PUBLIC_LINK_ANDROID
ARG NEXT_PUBLIC_WHATSAPP_URL
ARG NEXT_PUBLIC_PHONE_NUMBER
ARG NEXT_PUBLIC_EMAIL
ARG NEXT_PUBLIC_LINK_BEMYTECH
ARG NEXT_PUBLIC_LINK_PRIVACIDAD
ARG NEXT_PUBLIC_FACEBOOK_URL
ARG NEXT_PUBLIC_LINKEDIN_URL

# Se exportan a variables de entorno para que Next las lea.
ENV NEXT_PUBLIC_NAME_APP="$NEXT_PUBLIC_NAME_APP" \
    NEXT_PUBLIC_LINK_IOS="$NEXT_PUBLIC_LINK_IOS" \
    NEXT_PUBLIC_LINK_ANDROID="$NEXT_PUBLIC_LINK_ANDROID" \
    NEXT_PUBLIC_WHATSAPP_URL="$NEXT_PUBLIC_WHATSAPP_URL" \
    NEXT_PUBLIC_PHONE_NUMBER="$NEXT_PUBLIC_PHONE_NUMBER" \
    NEXT_PUBLIC_EMAIL="$NEXT_PUBLIC_EMAIL" \
    NEXT_PUBLIC_LINK_BEMYTECH="$NEXT_PUBLIC_LINK_BEMYTECH" \
    NEXT_PUBLIC_LINK_PRIVACIDAD="$NEXT_PUBLIC_LINK_PRIVACIDAD" \
    NEXT_PUBLIC_FACEBOOK_URL="$NEXT_PUBLIC_FACEBOOK_URL" \
    NEXT_PUBLIC_LINKEDIN_URL="$NEXT_PUBLIC_LINKEDIN_URL"

# Compilamos la aplicación en modo producción
RUN npm run build

# ---------------------------------------------------------
# El comando `next build` en Next.js 14 crea un directorio
# .next que incluye una carpeta `standalone` que contiene un
# bundle optimizado para producción. Lo usamos para reducir el
# tamaño de la imagen final.
# ---------------------------------------------------------

###############
#   RUNNER    #
###############
FROM node:20-alpine AS runner

WORKDIR /app
ENV NODE_ENV=production
ENV PORT=3000

# Copiamos de la etapa anterior únicamente las dependencias y el
# artefacto `standalone`.
COPY --from=builder /app/next.config.js ./
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static

# Instalamos sólo las dependencias de producción.
COPY --from=builder /app/package.json ./
COPY --from=builder /app/package-lock.json* ./
RUN npm ci --omit=dev --ignore-scripts --include-workspace-root

# Exponemos el puerto por defecto
EXPOSE 3000

# Comando por defecto
CMD ["node", "server.js"] 