#!/bin/bash
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
mkdir -p "$root/build/module-cache"
xcrun swiftc -swift-version 5 -module-cache-path "$root/build/module-cache" \
  "$root/src/FnGesture.swift" "$root/tests/main.swift" -o "$root/build/gesture-tests"
"$root/build/gesture-tests"
for script in "$root"/scripts/*.sh; do /bin/bash -n "$script"; done
