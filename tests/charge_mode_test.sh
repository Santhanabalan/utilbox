#!/bin/sh
# charge_mode.sh with stubbed getprop/start/stop.
. "$(dirname "$0")/lib.sh"

setup_module
P=$MOD/features/charge_mode/charge_mode.sh
echo running >"$T/svc"
stub getprop "[ \"\$1\" = init.svc.batterysecret ] && [ ! -f '$T/nosvc' ] && cat '$T/svc'; exit 0"
stub stop "[ -f '$T/stuck' ] || echo stopped >'$T/svc'"
stub start "echo running >'$T/svc'"
stub sleep ":"

cm() {
  $TEST_SH "$P" "$@" 2>/dev/null
}

check "list" "default|HyperCharge (120 W) qc|Quick Charge (18 W)" "$(cm list | tr '\n' ' ' | sed 's/ $//')"
check "initial status" "default ok" "$(cm status)"

cm apply qc
check "apply qc exits 0" 0 $?
check "qc stops batterysecret" stopped "$(cat "$T/svc")"
check "status after qc" "qc ok" "$(cm status)"

echo running >"$T/svc"
check "restarted service reported as drift" "qc drift" "$(cm status)"
cm boot
check "boot re-applies qc" stopped "$(cat "$T/svc")"

cm apply default
check "default starts batterysecret" running "$(cat "$T/svc")"
check "status after default" "default ok" "$(cm status)"

cm apply bogus
check "unknown mode rejected" 2 $?

touch "$T/stuck"
cm apply qc
check "apply that never takes effect exits 1" 1 $?
check "failed apply keeps previous mode" "default ok" "$(cm status)"
rm "$T/stuck"

touch "$T/nosvc"
check "no batterysecret is unsupported" "default unsupported" "$(cm status)"
cm apply qc
check "unsupported device rejected" 3 $?

finish
