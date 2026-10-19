#!/bin/sh
# common/info.sh output format with stubbed getprop.
. "$(dirname "$0")/lib.sh"

setup_module
stub getprop 'case "$1" in
  ro.product.marketname) echo "Xiaomi 11T Pro" ;;
  ro.product.model) echo M2012K11G ;;
  ro.board.platform) echo lahaina ;;
esac
exit 0'

out=$($TEST_SH "$MOD/common/info.sh" 2>/dev/null)
get() {
  echo "$out" | sed -n "s/^$1=//p"
}

check "marketname preferred over model" "Xiaomi 11T Pro" "$(get model)"
check "soc falls back to platform" lahaina "$(get soc)"
check "module version from module.prop" "$(sed -n 's/^version=//p' "$SRC/module.prop")" "$(get module_version)"
check "every line is key=value" "" "$(echo "$out" | grep -v '^[a-z0-9_]*=.')"
check "empty values are omitted" "" "$(get codename)"

finish
