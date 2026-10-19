#!/system/bin/sh
# Performance Mode (SD888 only).
# Usage: perf_mode.sh list | status | apply <mode-id> | boot
# status prints "<mode-id> ok|drift|unknown" (whether live values still match).

FEATDIR=$(cd "${0%/*}" && pwd)
MODDIR=$(cd "$FEATDIR/../.." && pwd)
. "$MODDIR/lib/common.sh"

MODES_LIST=$FEATDIR/modes.list
MODES_DIR=$FEATDIR/modes
STATE_DIR=$DATA_DIR/perf_mode
STATE_FILE=$STATE_DIR/mode
DEFAULTS_FILE=$STATE_DIR/defaults
BOOT_ID_FILE=$STATE_DIR/defaults.boot_id
BOOT_ID_NODE=/proc/sys/kernel/random/boot_id

supported() {
  [ "$(getprop ro.board.platform)" = "lahaina" ]
}

valid_mode() {
  case "$1" in
    "" | *[!a-z]*) return 1 ;;
  esac
  grep -q "^$1|" "$MODES_LIST"
}

current_mode() {
  mode=$(cat "$STATE_FILE" 2>/dev/null)
  valid_mode "$mode" || mode=default
  echo "$mode"
}

# Values file for a mode: the boot snapshot for default, else its .conf.
mode_file() {
  if [ "$1" = "default" ]; then
    echo "$DEFAULTS_FILE"
  else
    echo "$MODES_DIR/$1.conf"
  fi
}

# Every node touched by any mode, in first-seen order.
mode_nodes() {
  for f in "$MODES_DIR"/*.conf; do
    [ -f "$f" ] && sed 's/#.*//' "$f"
  done | awk 'NF == 2 && !seen[$1]++ { print $1 }'
}

# Snapshot stock values once per boot, before this boot's first apply.
snapshot() {
  boot_id=$(cat "$BOOT_ID_NODE" 2>/dev/null)
  if [ -f "$DEFAULTS_FILE" ] && [ "$(cat "$BOOT_ID_FILE" 2>/dev/null)" = "$boot_id" ]; then
    return 0
  fi
  mkdir -p "$STATE_DIR"
  : >"$DEFAULTS_FILE.tmp"
  for node in $(mode_nodes); do
    [ -r "$node" ] && echo "$node $(cat "$node")" >>"$DEFAULTS_FILE.tmp"
  done
  mv -f "$DEFAULTS_FILE.tmp" "$DEFAULTS_FILE"
  echo "$boot_id" >"$BOOT_ID_FILE"
  log INFO "perf_mode: snapshot taken"
}

# write_values <file>: returns non-zero if any write failed.
write_values() {
  rc=0
  [ -f "$1" ] || return 0
  while read -r node value; do
    case "$node" in "" | "#"*) continue ;; esac
    write_node "$node" "$value" || rc=1
  done <"$1"
  return $rc
}

apply_mode() {
  snapshot
  # Start from stock so nodes not listed in the new mode don't keep old values.
  write_values "$DEFAULTS_FILE" || return 1
  [ "$1" = "default" ] || write_values "$(mode_file "$1")"
}

status() {
  mode=$(current_mode)
  file=$(mode_file "$mode")
  if [ ! -f "$file" ]; then
    echo "$mode unknown"
    return 0
  fi
  live=ok
  while read -r node value; do
    case "$node" in "" | "#"*) continue ;; esac
    [ -r "$node" ] && [ "$(cat "$node")" != "$value" ] && live=drift
  done <"$file"
  echo "$mode $live"
}

cmd_apply() {
  if ! valid_mode "$1"; then
    echo "unknown mode: $1" >&2
    return 2
  fi
  if [ "$1" != "default" ] && ! supported; then
    echo "unsupported device: needs Snapdragon 888 (lahaina)" >&2
    return 3
  fi
  prev=$(current_mode)
  if ! apply_mode "$1"; then
    apply_mode "$prev"
    echo "failed to apply $1; kept $prev (see $LOG_FILE)" >&2
    return 1
  fi
  mkdir -p "$STATE_DIR"
  echo "$1" >"$STATE_FILE"
  log INFO "perf_mode: applied $1"
}

cmd_boot() {
  snapshot
  mode=$(current_mode)
  [ "$mode" = "default" ] && return 0
  cmd_apply "$mode" 2>>"$LOG_FILE"
}

case "$1" in
  list) grep -v '^#' "$MODES_LIST" ;;
  status) status ;;
  apply) cmd_apply "$2" ;;
  boot) cmd_boot ;;
  *)
    echo "usage: ${0##*/} list | status | apply <mode-id> | boot" >&2
    exit 2
    ;;
esac
