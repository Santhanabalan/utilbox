# shellcheck shell=sh
# Shared helpers for shell tests. Set TEST_SH to choose the shell that runs module scripts.

TEST_SH=${TEST_SH:-sh}
SRC=$(cd "$(dirname "$0")/../src" && pwd)
failures=0

# check <description> <expected> <actual>
check() {
  if [ "$2" = "$3" ]; then
    echo "ok - $1"
  else
    echo "not ok - $1"
    echo "    expected: '$2'"
    echo "    actual:   '$3'"
    failures=$((failures + 1))
  fi
}

# Copy src/ into a temp dir with DATA_DIR redirected; sets T and MOD.
setup_module() {
  T=$(mktemp -d)
  trap 'rm -rf "$T"' EXIT
  MOD=$T/mod
  cp -R "$SRC" "$MOD"
  rewrite "$MOD/lib/common.sh" "s#^DATA_DIR=.*#DATA_DIR=$T/data#"
  mkdir -p "$T/bin"
  PATH="$T/bin:$PATH"
  export PATH
}

# rewrite <file> <sed-expr>: portable in-place sed.
rewrite() {
  sed "$2" "$1" >"$1.tmp" && mv "$1.tmp" "$1"
}

# stub <name> <body>: put a fake command on PATH.
stub() {
  printf '#!/bin/sh\n%s\n' "$2" >"$T/bin/$1"
  chmod +x "$T/bin/$1"
}

finish() {
  if [ "$failures" -gt 0 ]; then
    echo "$failures check(s) failed"
    exit 1
  fi
}
