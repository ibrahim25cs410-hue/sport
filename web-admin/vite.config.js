import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  base: '/panel/',
  server: {
    port: 5174,
    proxy: {
      '/api': {
        target: process.env.VITE_PROXY_TARGET || 'https://sports-x7v7.onrender.com',
        changeOrigin: true,
        secure: true,
      },
      '/socket.io': {
        target: process.env.VITE_PROXY_TARGET || 'https://sports-x7v7.onrender.com',
        changeOrigin: true,
        ws: true,
        secure: true,
      },
    },
  },
});
