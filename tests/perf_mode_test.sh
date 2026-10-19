#!/bin/sh
# perf_mode.sh against fake sysfs nodes.
. "$(dirname "$0")/lib.sh"

setup_module
F=$T/fs
P=$MOD/features/perf_mode/perf_mode.sh
rewrite "$P" "s#^BOOT_ID_NODE=.*#BOOT_ID_NODE=$T/boot_id#"
for conf in "$MOD"/features/perf_mode/modes/*.conf; do
  rewrite "$conf" "s#^/#$F/#"
done
stub getprop '[ "$1" = ro.board.platform ] && echo "${PLATFORM:-lahaina}"; exit 0'
echo boot1 >"$T/boot_id"

CPU=$F/sys/devices/system/cpu
GPU=$F/sys/class/kgsl/kgsl-3d0
stock() {
  for c in 0 4 7; do mkdir -p "$CPU/cpu$c/cpufreq"; done
  echo 1804800 >"$CPU/cpu0/cpufreq/scaling_max_freq"
  echo 300000 >"$CPU/cpu0/cpufreq/scaling_min_freq"
  echo 2419200 >"$CPU/cpu4/cpufreq/scaling_max_freq"
  echo 710400 >"$CPU/cpu4/cpufreq/scaling_min_freq"
  echo 2841600 >"$CPU/cpu7/cpufreq/scaling_max_freq"
  echo 844800 >"$CPU/cpu7/cpufreq/scaling_min_freq"
  mkdir -p "$GPU" "$F/proc/sys/vm"
  echo 0 >"$GPU/max_pwrlevel"
  echo 840000000 >"$GPU/max_gpuclk"
  echo 60 >"$F/proc/sys/vm/swappiness"
}
live() {
  cat "$CPU/cpu0/cpufreq/scaling_max_freq" "$CPU/cpu4/cpufreq/scaling_max_freq" \
    "$CPU/cpu7/cpufreq/scaling_max_freq" "$GPU/max_gpuclk" "$F/proc/sys/vm/swappiness" | tr '\n' ' '
}
pm() {
  $TEST_SH "$P" "$@" 2>/dev/null
}
STOCK="1804800 2419200 2841600 840000000 60 "
stock

check "list starts with default" "default|Default (no change)" "$(pm list | head -n 1)"
check "list has every mode" "default low med high max" "$(pm list | cut -d'|' -f1 | tr '\n' ' ' | sed 's/ $//')"
check "status before any apply" "default unknown" "$(pm status)"

pm apply low
check "apply low exits 0" 0 $?
check "low values written" "1708800 2227200 2592000 608000000 15 " "$(live)"
check "status after low" "low ok" "$(pm status)"

pm apply max
check "max values written" "1497600 1881600 2035200 608000000 15 " "$(live)"
pm apply default
check "default restores stock" "$STOCK" "$(live)"

for mode in med high; do
  pm apply "$mode"
  check "status after $mode" "$mode ok" "$(pm status)"
done

pm apply bogus
check "unknown mode rejected" 2 $?
pm apply ../low
check "path-like mode rejected" 2 $?
# Subshell: POSIX keeps variable assignments made before a function call.
(
  PLATFORM=kona
  export PLATFORM
  pm apply low
)
check "non-SD888 rejected" 3 $?
check "rejections keep current mode" "high ok" "$(pm status)"

echo 1 >"$F/proc/sys/vm/swappiness"
check "external change reported as drift" "high drift" "$(pm status)"

pm boot
pm apply default
check "re-running boot in the same boot keeps stock snapshot" "$STOCK" "$(live)"

pm apply max
stock
echo boot2 >"$T/boot_id"
pm boot
check "saved mode re-applied after reboot" "1497600 1881600 2035200 608000000 15 " "$(live)"
check "status after reboot" "max ok" "$(pm status)"

rm "$F/proc/sys/vm/swappiness"
mkdir "$F/proc/sys/vm/swappiness"
pm apply low
check "failed write exits 1" 1 $?
check "failed apply keeps previous mode" "max" "$(pm status | cut -d' ' -f1)"

finish
