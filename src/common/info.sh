#!/system/bin/sh
# Prints device and module metadata for the WebUI summary as key=value lines.

MODDIR=$(cd "${0%/*}/.." && pwd)
BATTERY=/sys/class/power_supply/battery

kv() {
  [ -n "$2" ] && echo "$1=$2"
}

first_prop() {
  for prop in "$@"; do
    value=$(getprop "$prop")
    if [ -n "$value" ]; then
      echo "$value"
      return
    fi
  done
}

read_node() {
  [ -r "$1" ] && cat "$1" 2>/dev/null
}

root_type() {
  if [ -d /data/adb/ap ]; then
    echo APatch
  elif [ -d /data/adb/ksu ]; then
    if [ -f /data/adb/ksu/.dynamic_sign ]; then
      echo SukiSU-Ultra
    elif [ -f /sys/module/kernelsu/parameters/expected_manager_size ]; then
      echo KernelSU-Next
    else
      echo KernelSU
    fi
  elif [ -d /data/adb/magisk ] || [ -f /data/adb/magisk.db ]; then
    echo Magisk
  fi
}

kv model "$(first_prop ro.product.marketname ro.product.vendor.marketname ro.product.model)"
kv codename "$(getprop ro.product.device)"
kv brand "$(getprop ro.product.brand)"
kv soc "$(first_prop ro.soc.model ro.board.platform)"
kv platform "$(getprop ro.board.platform)"
kv android "$(getprop ro.build.version.release)"
kv api "$(getprop ro.build.version.sdk)"
kv os "$(first_prop ro.mi.os.version.incremental ro.build.version.incremental)"
kv patch "$(getprop ro.build.version.security_patch)"
kv kernel "$(uname -r)"
kv root "$(root_type)"
kv module_version "$(sed -n 's/^version=//p' "$MODDIR/module.prop")"
kv uptime "$(cut -d. -f1 /proc/uptime)"
kv mem_total_kb "$(awk '/^MemTotal:/ { print $2 }' /proc/meminfo)"
kv swappiness "$(read_node /proc/sys/vm/swappiness)"

for policy in /sys/devices/system/cpu/cpufreq/policy*; do
  [ -d "$policy" ] || continue
  kv "cluster_${policy##*policy}" "$(read_node "$policy/related_cpus" | tr ' ' ',') $(read_node "$policy/cpuinfo_max_freq") $(read_node "$policy/scaling_max_freq")"
done

kv gpu_model "$(read_node /sys/class/kgsl/kgsl-3d0/gpu_model)"
kv gpu_max_hz "$(read_node /sys/class/kgsl/kgsl-3d0/max_gpuclk)"

kv battery_level "$(read_node "$BATTERY/capacity")"
kv battery_status "$(read_node "$BATTERY/status")"
kv battery_temp "$(read_node "$BATTERY/temp")"
kv battery_health "$(read_node "$BATTERY/health")"
kv battery_cycles "$(read_node "$BATTERY/cycle_count")"
kv battery_full_uah "$(read_node "$BATTERY/charge_full")"
kv battery_design_uah "$(read_node "$BATTERY/charge_full_design")"
