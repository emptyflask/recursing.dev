function esc(s) {
  return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
}

function hexToRgb(hex) {
  const n = parseInt(hex.slice(1), 16);
  return [(n >> 16) & 255, (n >> 8) & 255, n & 255];
}

function rgbToHex([r, g, b]) {
  return "#" + [r, g, b].map((v) => Math.round(v).toString(16).padStart(2, "0")).join("");
}

function lerp(a, b, t) {
  return a + (b - a) * t;
}

const STOPS = ["#fe8019", "#fabd2f", "#b8bb26", "#8ec07c", "#83a598"].map(hexToRgb);

function colorAt(t) {
  const segments = STOPS.length - 1;
  const pos = t * segments;
  const i = Math.min(Math.floor(pos), segments - 1);
  const localT = pos - i;
  const rgb = [0, 1, 2].map((k) => lerp(STOPS[i][k], STOPS[i + 1][k], localT));
  return rgbToHex(rgb);
}

export function buildLogoHtml(asciiText) {
  const lines = asciiText.replace(/\n$/, "").split("\n");
  const totalContentRows = lines.filter((l) => l.trim() !== "").length;

  const out = ['<pre class="logo-art" aria-label="recursing.dev">'];
  let rowCounter = 0;
  for (const line of lines) {
    if (line.trim() === "") {
      out.push("\n");
      continue;
    }
    const t = totalContentRows <= 1 ? 0 : rowCounter / (totalContentRows - 1);
    const color = colorAt(t);
    rowCounter++;
    out.push(`<span style="color:${color}">${esc(line)}</span>\n`);
  }
  out.push("</pre>");
  return out.join("");
}
