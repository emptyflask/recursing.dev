import { defineConfig } from "vite";
import { resolve } from "node:path";

export default defineConfig({
  build: {
    outDir: "assets/dist",
    emptyOutDir: true,
    rollupOptions: {
      input: {
        main: resolve(import.meta.dirname, "src/main.ts"),
      },
      output: {
        entryFileNames: "[name].js",
      },
    },
  },
});
