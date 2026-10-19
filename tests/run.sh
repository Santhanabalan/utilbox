#!/bin/sh
# Runs every tests/*_test.sh; set TEST_SH (e.g. "busybox sh") to pick the shell under test.
cd "$(dirname "$0")" || exit 1

failed=0
for test in ./*_test.sh; do
  echo "# ${test#./} (${TEST_SH:-sh})"
  sh "$test" || failed=$((failed + 1))
done

if [ "$failed" -gt 0 ]; then
  echo "$failed test file(s) failed"
  exit 1
fi
echo "all tests passed"
