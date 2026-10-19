# shellcheck shell=sh
# Sourced by the root manager installer; MODPATH, API, ARCH and ui_print are provided.

# shellcheck disable=SC2034
SKIPUNZIP=0

ui_print ""
ui_print "██╗   ██╗████████╗██╗██╗     ██████╗  ██████╗ ██╗  ██╗"
ui_print "██║   ██║╚══██╔══╝██║██║     ██╔══██╗██╔═══██╗╚██╗██╔╝"
ui_print "██║   ██║   ██║   ██║██║     ██████╔╝██║   ██║ ╚███╔╝ "
ui_print "██║   ██║   ██║   ██║██║     ██╔══██╗██║   ██║ ██╔██╗ "
ui_print "╚██████╔╝   ██║   ██║███████╗██████╔╝╚██████╔╝██╔╝ ██╗"
ui_print " ╚═════╝    ╚═╝   ╚═╝╚══════╝╚═════╝  ╚═════╝ ╚═╝  ╚═╝"
ui_print ""

# Detect Root Type
ROOT_TYPE=Magisk
[ "$KSU" = "true" ] && ROOT_TYPE=KernelSU
[ "$APATCH" = "true" ] && ROOT_TYPE=APatch

# Device Metadata
ui_print "- Device: $(getprop ro.product.device)"
ui_print "- Root: $ROOT_TYPE"
ui_print "- Android: $(getprop ro.build.version.release) (API $API, $ARCH)"
ui_print "- Processor: $(getprop ro.soc.model)"
ui_print "- Kernel: $(uname -r)"
ui_print ""

set_perm_recursive "$MODPATH" 0 0 0755 0644
