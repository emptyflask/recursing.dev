import { readFileSync, writeFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";
import { buildLogoHtml } from "./logo-gradient.mjs";

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = join(__dirname, "..");

const asciiText = readFileSync(join(ROOT, "ascii.txt"), "utf8");
writeFileSync(join(ROOT, "_includes/logo.html"), buildLogoHtml(asciiText));
console.log("Wrote _includes/logo.html");
