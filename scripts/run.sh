#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"

require_command flutter
require_file "${ADB}"

device_id="$(resolve_android_device)"
echo "Using Android device ${device_id}."

offline=false
if [[ "${1:-}" == '--offline' ]]; then
  offline=true
elif [[ -n "${1:-}" ]]; then
  echo "Usage: $0 [--offline]" >&2
  exit 2
fi

if [[ "${offline}" == true && "${device_id}" == *:* ]]; then
  echo 'Offline testing requires a USB connection.' >&2
  echo 'Airplane mode would disconnect the current Wi-Fi debugging session.' >&2
  exit 1
fi

echo 'Building the debug APK...'
flutter build apk --debug

if [[ "${offline}" == true ]]; then
  "${ADB}" -s "${device_id}" shell cmd connectivity airplane-mode enable
  echo 'Airplane mode enabled.'
fi

flutter run \
  -d "${device_id}" \
  --no-build \
  --no-resident \
  --use-application-binary=build/app/outputs/flutter-apk/app-debug.apk

echo 'Cafe POS is running on the connected Android device.'
