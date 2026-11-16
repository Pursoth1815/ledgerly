#!/usr/bin/env bash
# Fails if an APK requests any of the given permissions (ADR 0017).
#
#   tool/check_apk_permissions.sh <apk> <permission>...
#
# CI runs it on both release builds: no build may request the internet, and
# the store build may never request SMS.
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "usage: $0 <apk> <permission>..." >&2
  exit 2
fi

apk=$1
shift

sdk=${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}
if [[ -z "$sdk" ]]; then
  echo "ANDROID_HOME is not set" >&2
  exit 2
fi
aapt2=$(ls -d "$sdk"/build-tools/*/aapt2 | sort -V | tail -1)

permissions=$("$aapt2" dump permissions "$apk")
status=0
for permission in "$@"; do
  if grep -q "name='$permission'" <<<"$permissions"; then
    echo "FORBIDDEN: $(basename "$apk") requests $permission" >&2
    status=1
  fi
done

if [[ $status -eq 0 ]]; then
  echo "$(basename "$apk"): none of the forbidden permissions are requested"
fi
exit $status
