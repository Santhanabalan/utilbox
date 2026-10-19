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

function run(command: string): [number, string, string] {
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
