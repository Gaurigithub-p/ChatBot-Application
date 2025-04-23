import { defineConfig } from 'vite'

export default defineConfig({
  root: '.', // This means the root of your frontend folder
  build: {
    outDir: 'dist', // Output directory (optional; defaults to dist)
    rollupOptions: {
      input: 'index.html' // Make sure index.html is here in frontend/
    }
  }
})
