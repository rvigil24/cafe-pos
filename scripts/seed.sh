#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"

require_command flutter
require_file "${ADB}"

readonly app_id='com.rvigil.cafe_pos'
readonly seed_success='CAFE_POS_SEED_SUCCESS'
readonly seed_failure='CAFE_POS_SEED_FAILURE'
readonly apk_path='build/app/outputs/flutter-apk/app-debug.apk'

device_id="$(resolve_android_device)"
readonly recovery_dir="$(mktemp -d)"
readonly recovery_apk="${recovery_dir}/app-debug.apk"
echo "Using Android device ${device_id}."
echo 'Existing application data will be preserved; only missing dummy data is created.'

restore_normal_apk=false

restore_app() {
  if [[ "${restore_normal_apk}" != true ]]; then
    return
  fi
  echo 'Restoring the normal Cafe POS debug APK...'
  "${ADB}" -s "${device_id}" install -r "${recovery_apk}" >/dev/null
  restore_normal_apk=false
}

finish() {
  local exit_code=$?
  trap - EXIT
  set +e
  restore_app
  local restore_code=$?
  rm -rf "${recovery_dir}"
  if ((restore_code != 0)); then
    echo 'Failed to restore the normal Cafe POS APK.' >&2
    exit_code=1
  fi
  exit "${exit_code}"
}

trap finish EXIT

echo 'Preparing a normal APK for immediate restoration...'
flutter build apk --debug
cp "${apk_path}" "${recovery_apk}"

echo 'Building the development seeder...'
flutter build apk --debug --target=tool/seed.dart

echo 'Installing and running the seeder without clearing application data...'
"${ADB}" -s "${device_id}" install -r "${apk_path}" >/dev/null
restore_normal_apk=true
"${ADB}" -s "${device_id}" logcat -c
"${ADB}" -s "${device_id}" shell am force-stop "${app_id}"
"${ADB}" -s "${device_id}" shell am start \
  -n "${app_id}/.MainActivity" >/dev/null

deadline=$((SECONDS + 60))
while ((SECONDS < deadline)); do
  seed_logs="$("${ADB}" -s "${device_id}" logcat -d -s flutter:I '*:S')"
  if grep -Fq "${seed_failure}" <<<"${seed_logs}"; then
    grep -F "${seed_failure}" <<<"${seed_logs}" >&2
    exit 1
  fi
  if grep -Fq "${seed_success}" <<<"${seed_logs}"; then
    grep -F "${seed_success}" <<<"${seed_logs}" | tail -1
    restore_app
    echo 'Dummy data seeded. Run ./cafe run to open the normal application.'
    exit 0
  fi
  sleep 1
done

echo 'Timed out waiting for the development seeder.' >&2
exit 1
