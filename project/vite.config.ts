import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  build: {
    outDir: 'dist', // The output directory for the build
    emptyOutDir: true, // Ensure the output directory is cleared before building
    rollupOptions: {
      input: 'project/index.html', // Specify the correct path to the entry file
    },
  },
});
