#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"

require_command flutter
require_file "${ADB}"

device_id="$(resolve_android_device)"
echo "Using Android device ${device_id}."

"${PROJECT_ROOT}/scripts/check.sh"

echo 'Building the integration-test APK without an emulator...'
flutter build apk \
  --debug \
  --target=integration_test/plugin_smoke_test.dart

echo 'Running the prebuilt Android integration test...'
flutter drive \
  -d "${device_id}" \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/plugin_smoke_test.dart \
  --use-application-binary=build/app/outputs/flutter-apk/app-debug.apk

echo 'Restoring the normal debug APK...'
flutter build apk --debug

echo 'Launching the normal APK as the final smoke test...'
flutter run \
  -d "${device_id}" \
  --no-build \
  --no-resident \
  --use-application-binary=build/app/outputs/flutter-apk/app-debug.apk

"${ADB}" -s "${device_id}" shell pidof com.rvigil.cafe_pos >/dev/null

echo 'All checks, integration tests, build, and launch checks passed.'
