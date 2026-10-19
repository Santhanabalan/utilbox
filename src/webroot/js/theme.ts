import { Hct, MaterialDynamicColors, SchemeTonalSpot, hexFromArgb } from '@material/material-color-utilities';
import { exec, hasBridge } from './bridge.js';

const FALLBACK_SEED = 0xff6750a4;
const darkQuery = window.matchMedia('(prefers-color-scheme: dark)');
let seed = FALLBACK_SEED;

function applyScheme(): void {
  const scheme = new SchemeTonalSpot(Hct.fromInt(seed), darkQuery.matches, 0);
  const style = document.documentElement.style;
  for (const color of new MaterialDynamicColors().allColors) {
    style.setProperty(`--md-sys-color-${color.name.replace(/_/g, '-')}`, hexFromArgb(color.getArgb(scheme)));
  }
}

// Android 12+ exposes the wallpaper (Monet) accent as a framework color resource.
async function systemSeed(): Promise<number | null> {
  if (!hasBridge()) return null;
  const { stdout } = await exec('cmd overlay lookup com.android.systemui android:color/system_accent1_500');
  const hex = stdout.trim().match(/(?:#|0x)?([0-9a-f]{8}|[0-9a-f]{6})$/i)?.[1];
  if (!hex) return null;
  const argb = parseInt(hex, 16);
  return (hex.length === 6 ? argb | 0xff000000 : argb) >>> 0;
}

export function initTheme(): void {
  applyScheme();
  darkQuery.addEventListener('change', applyScheme);
  systemSeed()
    .then((s) => {
      if (s === null) return;
      seed = s;
      applyScheme();
    })
    .catch(() => {});
}
