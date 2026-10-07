import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    environment: "jsdom",
    // Scope discovery to this project's own tests. Vitest's default include
    // glob isn't restricted to the project root, and nix-direnv's .direnv/
    // directory symlinks in unrelated flake inputs' source trees — without
    // this, vitest wanders into those repos and runs their test files too.
    include: ["src/**/*.test.ts", "scripts/**/*.test.mjs"],
  },
});
