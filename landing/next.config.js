/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'standalone',
  images: {
    domains: ['images.unsplash.com', 'ui-avatars.com'],
  },
  reactStrictMode: true,
  swcMinify: true,
}

module.exports = nextConfig 