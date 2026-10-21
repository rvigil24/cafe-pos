#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"

require_command flutter
require_file "${ADB}"

device_id="$(resolve_android_device)"
echo "Using Android device ${device_id}."

if [[ -n "${1:-}" ]]; then
  echo "Usage: $0" >&2
  exit 2
fi

echo 'Building the debug APK...'
flutter build apk --debug

flutter run \
  -d "${device_id}" \
  --no-build \
  --no-resident \
  --use-application-binary=build/app/outputs/flutter-apk/app-debug.apk

echo 'Cafe POS is running on the connected Android device.'
