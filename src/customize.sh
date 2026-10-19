# shellcheck shell=sh
# Sourced by the root manager installer; MODPATH, API, ARCH and ui_print are provided.

# shellcheck disable=SC2034
SKIPUNZIP=0

if [ "$KSU" = "true" ]; then
  ui_print "- Root: KernelSU ($KSU_VER_CODE)"
elif [ "$APATCH" = "true" ]; then
  ui_print "- Root: APatch ($APATCH_VER_CODE)"
else
  ui_print "- Root: Magisk ($MAGISK_VER_CODE)"
fi

ui_print "- Device API: $API, arch: $ARCH"

set_perm_recursive "$MODPATH" 0 0 0755 0644
