#!/system/bin/sh
# Runs in late_start service mode (non-blocking).
MODDIR=${0%/*}

until [ "$(getprop sys.boot_completed)" = "1" ]; do
  sleep 1
done
# Let vendor perf/thermal services settle first.
sleep 30

sh "$MODDIR/features/perf_mode/perf_mode.sh" boot
