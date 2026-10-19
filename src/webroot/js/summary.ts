import "@material/web/icon/icon.js";
import { MODDIR, exec } from "./bridge.js";
import { el } from "./dom.js";

interface Row {
  icon: string;
  label: string;
  value: string;
}

interface Group {
  title: string;
  tone: "primary" | "secondary" | "tertiary";
  rows: Row[];
}

const INFO_SCRIPT = `${MODDIR}/common/info.sh`;

function parseInfo(stdout: string): Map<string, string> {
  const info = new Map<string, string>();
  for (const line of stdout.split("\n")) {
    const eq = line.indexOf("=");
    if (eq > 0) info.set(line.slice(0, eq), line.slice(eq + 1).trim());
  }
  return info;
}

const ghz = (khz: string) => `${(Number(khz) / 1e6).toFixed(2)} GHz`;

function joinParts(...parts: (string | undefined)[]): string {
  return parts.filter(Boolean).join(" · ");
}

function formatUptime(seconds: string): string {
  const s = Number(seconds);
  const days = Math.floor(s / 86400);
  const hours = Math.floor((s % 86400) / 3600);
  const minutes = Math.floor((s % 3600) / 60);
  return days > 0 ? `${days}d ${hours}h ${minutes}m` : `${hours}h ${minutes}m`;
}

function clusterRows(info: Map<string, string>): Row[] {
  const clusters = [...info.entries()]
    .filter(([key]) => key.startsWith("cluster_"))
    .sort(([a], [b]) => Number(a.slice(8)) - Number(b.slice(8)));
  const names =
    clusters.length === 3
      ? ["Efficiency", "Performance", "Prime"]
      : ["Efficiency", "Performance"];
  return clusters.map(([key, value], i) => {
    const [cpus = "", hwMax = "", curMax = ""] = value.split(" ");
    const limit =
      curMax && curMax !== hwMax
        ? `${ghz(curMax)} of ${ghz(hwMax)}`
        : ghz(hwMax);
    return {
      icon: "memory",
      label: `${names[i] ?? `Cluster ${key.slice(8)}`} cores`,
      value: joinParts(`CPU ${cpus.replace(/,/g, ", ")}`, `max ${limit}`),
    };
  });
}

function buildGroups(info: Map<string, string>): Group[] {
  const get = (key: string) => info.get(key);
  // MemTotal excludes kernel-reserved memory, so round up to the marketed size.
  const memGb =
    get("mem_total_kb") &&
    `${Math.ceil(Number(get("mem_total_kb")) / 1048576)} GB RAM`;
  const temp =
    get("battery_temp") &&
    `${(Number(get("battery_temp")) / 10).toFixed(1)} °C`;
  const full = Number(get("battery_full_uah"));
  const design = Number(get("battery_design_uah"));
  const capacity =
    full && design
      ? `${Math.round((full / design) * 100)}% of design capacity`
      : undefined;

  const groups: Group[] = [
    {
      title: "Device",
      tone: "primary",
      rows: [
        {
          icon: "smartphone",
          label: "Model",
          value: joinParts(get("model"), get("codename")),
        },
        {
          icon: "developer_board",
          label: "Chipset",
          value: joinParts(get("soc"), get("platform")),
        },
        { icon: "storage", label: "Memory", value: memGb ?? "" },
      ],
    },
    {
      title: "System",
      tone: "secondary",
      rows: [
        {
          icon: "android",
          label: "Android",
          value: joinParts(get("android"), get("api") && `API ${get("api")}`),
        },
        { icon: "system_update", label: "Build", value: get("os") ?? "" },
        {
          icon: "security",
          label: "Security patch",
          value: get("patch") ?? "",
        },
        { icon: "terminal", label: "Kernel", value: get("kernel") ?? "" },
        {
          icon: "schedule",
          label: "Uptime",
          value: get("uptime") ? formatUptime(get("uptime")!) : "",
        },
      ],
    },
    {
      title: "Processor",
      tone: "primary",
      rows: [
        ...clusterRows(info),
        {
          icon: "videogame_asset",
          label: "GPU",
          value: joinParts(
            get("gpu_model"),
            get("gpu_max_hz") && `max ${Number(get("gpu_max_hz")) / 1e6} MHz`,
          ),
        },
        {
          icon: "swap_horiz",
          label: "Swappiness",
          value: get("swappiness") ?? "",
        },
      ],
    },
    {
      title: "Battery",
      tone: "tertiary",
      rows: [
        {
          icon: "battery_full",
          label: "Level",
          value: joinParts(
            get("battery_level") && `${get("battery_level")}%`,
            get("battery_status"),
          ),
        },
        { icon: "thermostat", label: "Temperature", value: temp ?? "" },
        {
          icon: "favorite",
          label: "Health",
          value: joinParts(get("battery_health"), capacity),
        },
        {
          icon: "autorenew",
          label: "Charge cycles",
          value: get("battery_cycles") ?? "",
        },
      ],
    },
    {
      title: "Module",
      tone: "secondary",
      rows: [
        {
          icon: "inventory_2",
          label: "UtilBox",
          value: get("module_version") ?? "",
        },
        {
          icon: "admin_panel_settings",
          label: "Root",
          value: get("root") ?? "",
        },
      ],
    },
  ];
  return groups
    .map((group) => ({ ...group, rows: group.rows.filter((row) => row.value) }))
    .filter((group) => group.rows.length > 0);
}

function renderRow(row: Row): HTMLElement {
  const item = el("div", "list-item list-item--info");
  const icon = el("div", "li-icon");
  icon.append(el("md-icon", undefined, row.icon));
  const content = el("div", "list-item-content");
  content.append(
    el("div", "toggle-text", row.label),
    el("span", "supporting-text", row.value),
  );
  item.append(icon, content);
  return item;
}

export async function renderSummary(page: HTMLElement): Promise<void> {
  const { stdout } = await exec(`sh ${INFO_SCRIPT}`);
  for (const group of buildGroups(parseInfo(stdout))) {
    const list = el("div", `list-container list-container--${group.tone}`);
    list.append(...group.rows.map(renderRow));
    page.append(el("h2", "list-title", group.title), list);
  }
}
