import { defineConfig } from 'vitest/config'
import react from '@vitejs/plugin-react'

// Dev: Vite on 5173, /api proxied to the Vapor server.
// Target is 127.0.0.1, not "localhost": API-CONTRACT §0 says the server binds
// 127.0.0.1:8080, and "localhost" can resolve to ::1 first, which would not connect.
// Prod: the Vapor server serves `dist/` itself, so there is a single origin (DECISIONS.md D4).
export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    strictPort: true,
    proxy: {
      '/api': {
        target: 'http://127.0.0.1:8080',
        changeOrigin: false,
      },
    },
  },
  build: {
    outDir: 'dist',
    emptyOutDir: true,
    sourcemap: true,
  },
  test: {
    environment: 'node',
    include: ['src/**/*.test.ts', 'src/**/*.test.tsx'],
  },
})
