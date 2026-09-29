#!/usr/bin/env bash

set -Eeuo pipefail

readonly PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly ANDROID_SDK="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-${HOME}/Android/Sdk}}"
readonly ADB="${ANDROID_SDK}/platform-tools/adb"

cd "${PROJECT_ROOT}"

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

require_file() {
  if [[ ! -x "$1" ]]; then
    echo "Missing required executable: $1" >&2
    exit 1
  fi
}

resolve_android_device() {
  require_file "${ADB}"

  if [[ -n "${CAFE_POS_DEVICE:-}" ]]; then
    if ! "${ADB}" -s "${CAFE_POS_DEVICE}" get-state >/dev/null 2>&1; then
      echo "Android device ${CAFE_POS_DEVICE} is not connected or authorized." >&2
      exit 1
    fi
    printf '%s\n' "${CAFE_POS_DEVICE}"
    return
  fi

  local -a devices=()
  mapfile -t devices < <("${ADB}" devices | awk 'NR > 1 && $2 == "device" { print $1 }')

  if ((${#devices[@]} == 0)); then
    echo 'No authorized Android device is connected.' >&2
    echo 'Connect the phone by USB, enable USB debugging, and accept its authorization prompt.' >&2
    exit 1
  fi

  if ((${#devices[@]} > 1)); then
    echo 'More than one Android device is connected.' >&2
    echo 'Set CAFE_POS_DEVICE to the desired adb serial.' >&2
    "${ADB}" devices -l >&2
    exit 1
  fi

  printf '%s\n' "${devices[0]}"
}
