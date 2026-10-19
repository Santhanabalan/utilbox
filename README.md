# UtilBox

[![CI](https://github.com/Santhanabalan/utilbox/actions/workflows/ci.yml/badge.svg)](https://github.com/Santhanabalan/utilbox/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/Santhanabalan/utilbox)](https://github.com/Santhanabalan/utilbox/releases/latest)

A root module with a WebUI for tuning the Xiaomi 11T Pro (Snapdragon 888). Each
feature checks that it is running on a supported device before changing anything.

## Features

### Performance mode (Snapdragon 888 only)

Lowers the CPU and GPU clock limits to reduce heat and battery drain. Values are
based on the XDA _Snapdragon Performance Scaling_ profiles.

| Mode                | Prime core | Performance cores | Efficiency cores | GPU   | Swappiness |
| ------------------- | ---------- | ----------------- | ---------------- | ----- | ---------- |
| Default (no change) | stock      | stock             | stock            | stock | stock      |
| High Efficiency     | -9%        | -8%               | -5%              | -28%  | 15         |
| Low Power           | -12%       | -13%              | -5%              | -28%  | 15         |
| Ultra Low Power     | -20%       | -17%              | -17%             | -28%  | 15         |
| Extreme Efficiency  | -28%       | -22%              | -17%             | -28%  | 15         |

Stock values are saved at every boot, and **Default** restores them exactly. If
applying a mode fails, the previous mode is kept.

### Charge mode (Xiaomi only)

- **HyperCharge (120 W)**: stock behaviour.
- **Quick Charge (18 W)**: stops the `batterysecret` service, so charging falls
  back to Quick Charge for slower, cooler charging.

### WebUI

- Material You design that follows your wallpaper colours and the system
  light/dark setting.
- **Summary** tab: current modes plus device, system, processor, battery and
  module details.
- **Optimization** and **Battery** tabs for switching modes.

Selected modes are saved in `/data/adb/utilbox` and re-applied after every
reboot. Uninstalling the module removes that data.

## Compatibility

| Root manager                                  | Install | Re-apply on boot | WebUI |
| --------------------------------------------- | ------- | ---------------- | ----- |
| KernelSU, KernelSU-Next, SukiSU-Ultra, APatch | Yes     | Yes              | Yes   |
| Magisk                                        | Yes     | Yes              | No    |

## Installation

Download the latest `utilbox-vX.Y.Z.zip` from
[Releases](https://github.com/Santhanabalan/utilbox/releases), flash it from your
root manager and reboot.

## Development

Requires Node.js (LTS) and a POSIX shell. ShellCheck is optional locally but runs
in CI.

```sh
npm install
npm run dev           # WebUI dev server with a mock root bridge
npm run typecheck     # TypeScript checks
npm test              # shell tests (TEST_SH="busybox sh" npm test to use BusyBox)
npm run format        # Prettier (format:check to verify only)
npm run build         # builds Module/ and utilbox-<version>.zip
```

### Layout

```text
src/
  META-INF/            Magisk installer
  module.prop          module metadata; version is the single source of truth
  customize.sh         install-time banner and device info
  service.sh           re-applies saved modes after boot
  uninstall.sh         removes /data/adb/utilbox
  lib/common.sh        shared shell helpers (logging, sysfs writes)
  common/info.sh       device and module metadata for the WebUI
  features/
    perf_mode/         performance mode script, modes.list and modes/*.conf
    charge_mode/       charge mode script
  webroot/             WebUI (Vite, TypeScript, Material Web)
tests/                 shell tests run in CI under dash and BusyBox ash
```

Each feature script exposes `list`, `status`, `apply <mode>` and `boot`; the WebUI
only calls these entry points.

### CI and releases

- **CI** runs on pushes to `main` and on pull requests: ShellCheck, the shell
  tests, WebUI typecheck and format check, and a full module build.
- **Releases**: bump `version` (and `versionCode`) in `src/module.prop`, commit,
  then push a matching tag. The release workflow builds the zip and publishes a
  GitHub release with it attached.

  ```sh
  git tag v0.2.0
  git push origin v0.2.0
  ```

## Disclaimer

Changing clock limits and charging behaviour is at your own risk. Every mode can
be reverted by selecting **Default** / **HyperCharge** or by uninstalling the
module.
