// Dev-server stand-in for the KernelSU bridge; never included in production builds.
const MODES: Record<string, string[]> = {
  perf_mode: [
    "default|Default (no change)",
    "low|High Efficiency",
    "med|Low Power",
    "high|Ultra Low Power",
    "max|Extreme Efficiency",
  ],
  charge_mode: ["default|HyperCharge (120 W)", "qc|Quick Charge (18 W)"],
};
const state: Record<string, string> = {
  perf_mode: "default",
  charge_mode: "default",
};

type Callback = (errno: number, stdout: string, stderr: string) => void;

const INFO = `model=Xiaomi 11T Pro
codename=vili
soc=SM8350
platform=lahaina
android=14
api=34
os=OS2.0.6.0.UKDMIXM
patch=2025-03-01
kernel=5.4.289-perf
root=KernelSU
module_version=v0.1.0
uptime=93784
mem_total_kb=7779244
swappiness=60
cluster_0=0,1,2,3 1804800 1804800
cluster_4=4,5,6 2419200 2419200
cluster_7=7 2841600 2841600
gpu_model=Adreno660v2
gpu_max_hz=840000000
battery_level=78
battery_status=Discharging
battery_temp=312
battery_health=Good
battery_cycles=412
battery_full_uah=4310000
battery_design_uah=5000000
`;

function run(command: string): [number, string, string] {
  if (command.endsWith("/common/info.sh")) return [0, INFO, ""];
  const [, script = "", action = "", arg = ""] =
    command.match(/\/(\w+)\.sh (\w+) ?(\S*)$/) ?? [];
  const modes = MODES[script];
  if (!modes) return [0, "", ""];
  if (action === "list") return [0, modes.join("\n") + "\n", ""];
  if (action === "status") return [0, `${state[script]} ok\n`, ""];
  if (action === "apply") {
    if (!modes.some((m) => m.startsWith(`${arg}|`)))
      return [2, "", `unknown mode: ${arg}\n`];
    state[script] = arg;
  }
  return [0, "", ""];
}

(window as unknown as { ksu: unknown }).ksu = {
  exec(command: string, _options: string, callback: string) {
    const result = run(command);
    setTimeout(
      () =>
        (window as unknown as Record<string, Callback>)[callback]!(...result),
      400,
    );
  },
};

export {};
