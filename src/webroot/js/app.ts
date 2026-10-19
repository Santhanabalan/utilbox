import './material.js';
import { renderHome } from './features.js';
import { initNavigation } from './navigation.js';
import { initTheme } from './theme.js';

async function main(): Promise<void> {
  if (import.meta.env.DEV) await import('./dev-mock.js');
  initTheme();
  initNavigation();
  const summary = document.getElementById('summary-page');
  if (summary) renderHome(summary);
}

void main();
