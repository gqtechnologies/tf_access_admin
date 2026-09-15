import vue from '@vitejs/plugin-vue'
import tailwindcss from '@tailwindcss/vite'
import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'
import tsconfigPaths from 'vite-tsconfig-paths'

export default defineConfig({
  plugins: [
    vue(),
    tailwindcss(),
    RubyPlugin(),
    tsconfigPaths(),
  ],
  build: {
    // Keep the production build lean in memory: no sourcemaps, no gzip size
    // report (it re-reads every chunk), and let Rollup process fewer files in
    // parallel. Rendering chunks was the step that OOM-killed small builders.
    sourcemap: false,
    reportCompressedSize: false,
    rollupOptions: {
      maxParallelFileOps: 2,
    },
  },
})
