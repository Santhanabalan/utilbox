#!/system/bin/sh
# Charge Mode (Xiaomi only): stopping the batterysecret service disables HyperCharge
# authentication, so charging falls back to Quick Charge (18 W).
# Usage: charge_mode.sh list | status | apply <mode-id> | boot
# status prints "<mode-id> ok|drift|unsupported" (whether the service state still matches).

FEATDIR=$(cd "${0%/*}" && pwd)
MODDIR=$(cd "$FEATDIR/../.." && pwd)
. "$MODDIR/lib/common.sh"

SERVICE=batterysecret
STATE_DIR=$DATA_DIR/charge_mode
STATE_FILE=$STATE_DIR/mode

valid_mode() {
  case "$1" in
    default | qc) return 0 ;;
  esac
  return 1
}

service_state() {
  getprop "init.svc.$SERVICE"
}

supported() {
  [ -n "$(service_state)" ]
}

expected_state() {
  if [ "$1" = "qc" ]; then echo stopped; else echo running; fi
}

current_mode() {
  mode=$(cat "$STATE_FILE" 2>/dev/null)
  valid_mode "$mode" || mode=default
  echo "$mode"
}

# init updates init.svc.* asynchronously, so wait for the new state.
apply_mode() {
  if [ "$1" = "qc" ]; then stop "$SERVICE"; else start "$SERVICE"; fi
  tries=0
  while [ "$(service_state)" != "$(expected_state "$1")" ]; do
    tries=$((tries + 1))
    [ "$tries" -gt 5 ] && return 1
    sleep 1
  done
}

status() {
  mode=$(current_mode)
  if ! supported; then
    echo "$mode unsupported"
  elif [ "$(service_state)" = "$(expected_state "$mode")" ]; then
    echo "$mode ok"
  else
    echo "$mode drift"
  fi
}

cmd_apply() {
  if ! valid_mode "$1"; then
    echo "unknown mode: $1" >&2
    return 2
  fi
  if ! supported; then
    echo "unsupported device: no $SERVICE service (Xiaomi only)" >&2
    return 3
  fi
  prev=$(current_mode)
  if ! apply_mode "$1"; then
    apply_mode "$prev"
    echo "failed to apply $1; kept $prev (see $LOG_FILE)" >&2
    log ERROR "charge_mode: $SERVICE did not reach $(expected_state "$1")"
    return 1
  fi
  mkdir -p "$STATE_DIR"
  echo "$1" >"$STATE_FILE"
  log INFO "charge_mode: applied $1"
}

cmd_boot() {
  mode=$(current_mode)
  [ "$mode" = "default" ] && return 0
  cmd_apply "$mode" 2>>"$LOG_FILE"
}

case "$1" in
  list) printf '%s\n' "default|HyperCharge (120 W)" "qc|Quick Charge (18 W)" ;;
  status) status ;;
  apply) cmd_apply "$2" ;;
  boot) cmd_boot ;;
  *)
    echo "usage: ${0##*/} list | status | apply <mode-id> | boot" >&2
    exit 2
    ;;
esac
