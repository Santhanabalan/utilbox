# shellcheck shell=sh
# Shared helpers. Source after setting MODDIR.

DATA_DIR=/data/adb/utilbox
LOG_FILE=$DATA_DIR/utilbox.log
LOG_MAX_BYTES=65536

log() {
  mkdir -p "$DATA_DIR"
  if [ -f "$LOG_FILE" ] && [ "$(wc -c <"$LOG_FILE")" -gt "$LOG_MAX_BYTES" ]; then
    mv -f "$LOG_FILE" "$LOG_FILE.old"
  fi
  echo "$(date '+%F %T') [$1] $2" >>"$LOG_FILE"
}

# write_node <path> <value>: skip (and log) missing nodes, report failed writes.
write_node() {
  if [ ! -e "$1" ]; then
    log WARN "skip missing $1"
    return 0
  fi
  if ! echo "$2" >"$1" 2>/dev/null; then
    log ERROR "write failed $1=$2"
    return 1
  fi
}
