import { renderFeatures } from "./features.js";
import "./material.js";
import { initNavigation } from "./navigation.js";
import { renderSummary } from "./summary.js";
import { initTheme } from "./theme.js";

async function main(): Promise<void> {
  if (import.meta.env.DEV) await import("./dev-mock.js");
  initTheme();
  initNavigation();
  const summary = document.getElementById("summary-page");
  if (summary) {
    renderFeatures(summary);
    renderSummary(summary).catch(() => {});
  }
}

void main();
