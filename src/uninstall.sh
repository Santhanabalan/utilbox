#!/system/bin/sh
# Runs when the module is removed.
MODDIR=${0%/*}
. "$MODDIR/lib/common.sh"

# sysfs values reset on reboot; only persistent state needs removing.
rm -rf "${DATA_DIR:?}"
