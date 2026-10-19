import './material.js';
import { renderHome } from './features.js';
import { initTheme } from './theme.js';

async function main(): Promise<void> {
  if (import.meta.env.DEV) await import('./dev-mock.js');
  initTheme();
  const home = document.getElementById('home-page');
  if (home) renderHome(home);
}

void main();
