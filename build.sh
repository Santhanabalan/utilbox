#!/bin/sh
# Assemble src/ into Module/, build the WebUI and package a flashable zip.
set -eu

ROOT=$(cd "$(dirname "$0")" && pwd)
SRC="$ROOT/src"
OUT="$ROOT/Module"

version=$(sed -n 's/^version=//p' "$SRC/module.prop")
zip_name="utilbox-$version.zip"

rm -rf "${OUT:?}" "${ROOT:?}/$zip_name"
mkdir -p "$OUT"
cp -R "$SRC/." "$OUT/"
rm -rf "$OUT/webroot"

[ -d "$ROOT/node_modules" ] || (cd "$ROOT" && npm ci)
(cd "$ROOT" && npm run --silent build:webui)

(cd "$OUT" && zip -qr9 "$ROOT/$zip_name" . -x '.*')
echo "Built $zip_name"
