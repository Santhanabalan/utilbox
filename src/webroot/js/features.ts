import "@material/web/icon/icon.js";
import "@material/web/progress/circular-progress.js";
import "@material/web/radio/radio.js";
import "@material/web/ripple/ripple.js";
import { MODDIR, exec } from "./bridge.js";
import { showToast } from "./toast.js";

type Tone = "primary" | "secondary" | "tertiary";

interface Feature {
  title: string;
  icon: string;
  tone: Tone;
  page: string;
  script: string;
}

interface Mode {
  id: string;
  label: string;
}

const FEATURES: Feature[] = [
  {
    title: "Performance mode",
    icon: "speed",
    tone: "primary",
    page: "optimization-page",
    script: `${MODDIR}/features/perf_mode/perf_mode.sh`,
  },
  {
    title: "Charge mode",
    icon: "bolt",
    tone: "tertiary",
    page: "battery-page",
    script: `${MODDIR}/features/charge_mode/charge_mode.sh`,
  },
];

const MODE_ID = /^[a-z]+$/;

const LIVE_NOTES: Record<string, string> = {
  drift: "Changed by something else, tap to re-apply",
  unsupported: "Not supported on this device",
};

function el<K extends keyof HTMLElementTagNameMap>(
  tag: K,
  className?: string,
  text?: string,
): HTMLElementTagNameMap[K] {
  const node = document.createElement(tag);
  if (className) node.className = className;
  if (text !== undefined) node.textContent = text;
  return node;
}

function parseModes(stdout: string): Mode[] {
  return stdout
    .trim()
    .split("\n")
    .map((line) => line.split("|"))
    .filter(
      (parts): parts is [string, string] =>
        MODE_ID.test(parts[0] ?? "") && !!parts[1],
    )
    .map(([id, label]) => ({ id, label }));
}

function renderFeature(
  feature: Feature,
  hero: HTMLElement,
  page: HTMLElement,
): void {
  const heroCard = el("div", "hero-card");
  const heroValue = el("span", "hero-card__value", "—");
  const heroNote = el("span", "hero-card__note");
  heroCard.append(
    el("span", "hero-card__label", feature.title),
    heroValue,
    heroNote,
  );
  hero.append(heroCard);

  const list = el("div", `list-container list-container--${feature.tone}`);
  list.setAttribute("role", "radiogroup");
  list.setAttribute("aria-label", feature.title);
  page.append(el("h2", "list-title", feature.title), list);

  let busy = false;

  async function load(): Promise<void> {
    const [listResult, statusResult] = await Promise.all([
      exec(`sh ${feature.script} list`),
      exec(`sh ${feature.script} status`),
    ]);
    const modes = parseModes(listResult.stdout);
    const [current = "default", live = ""] = statusResult.stdout
      .trim()
      .split(" ");
    const note = LIVE_NOTES[live] ?? "";

    heroValue.textContent =
      modes.find((m) => m.id === current)?.label ?? current;
    heroNote.textContent = note;
    list.replaceChildren(
      ...modes.map((mode) => renderRow(mode, mode.id === current, note)),
    );
  }

  function renderRow(mode: Mode, selected: boolean, note: string): HTMLElement {
    const row = el("div", "list-item");
    row.setAttribute("role", "radio");
    row.setAttribute("aria-checked", String(selected));
    row.tabIndex = 0;

    const icon = el("div", "li-icon");
    icon.append(el("md-icon", undefined, feature.icon));
    const content = el("div", "list-item-content");
    content.append(el("div", "toggle-text", mode.label));
    if (selected)
      content.append(el("span", "supporting-text", note || "Active"));

    const spinner = el("md-circular-progress", "action-spinner");
    spinner.setAttribute("indeterminate", "");
    spinner.hidden = true;
    const radio = el("md-radio");
    radio.setAttribute("aria-hidden", "true");
    radio.tabIndex = -1;
    if (selected) radio.setAttribute("checked", "");

    row.append(icon, content, spinner, radio, el("md-ripple"));

    const activate = () => {
      if (busy || (selected && !note)) return;
      void apply(mode, spinner);
    };
    row.addEventListener("click", activate);
    row.addEventListener("keydown", (event) => {
      if (event.key === "Enter" || event.key === " ") {
        event.preventDefault();
        activate();
      }
    });
    return row;
  }

  async function apply(mode: Mode, spinner: HTMLElement): Promise<void> {
    busy = true;
    list.setAttribute("aria-busy", "true");
    spinner.hidden = false;
    try {
      const result = await exec(`sh ${feature.script} apply ${mode.id}`);
      if (result.errno === 0)
        showToast(`${feature.title}: ${mode.label}`, "success", "check_circle");
      else
        showToast(
          result.stderr.trim() || `Failed to apply ${mode.label}`,
          "error",
          "error",
        );
      await load();
    } catch (err) {
      showToast((err as Error).message, "error", "error");
    } finally {
      busy = false;
      list.removeAttribute("aria-busy");
      spinner.hidden = true;
    }
  }

  load().catch((err: Error) => {
    heroNote.textContent = err.message;
  });
}

// Status cards go on the summary page; each mode list goes on its feature's page.
export function renderFeatures(summary: HTMLElement): void {
  const hero = el("div", "hero-grid");
  summary.append(hero);
  for (const feature of FEATURES) {
    const page = document.getElementById(feature.page);
    if (page) renderFeature(feature, hero, page);
  }
}
