#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"

require_command flutter
require_file "${ADB}"

readonly app_id='com.rvigil.cafe_pos'
readonly apk_path='build/app/outputs/flutter-apk/app-debug.apk'

assume_yes=false
if (($# > 1)); then
  echo "Usage: $0 [--yes]" >&2
  exit 2
elif [[ "${1:-}" == '--yes' ]]; then
  assume_yes=true
elif [[ -n "${1:-}" ]]; then
  echo "Usage: $0 [--yes]" >&2
  exit 2
fi

device_id="$(resolve_android_device)"
echo "Using Android device ${device_id}."
echo "WARNING: This permanently erases all Cafe POS data stored by ${app_id}."
echo 'Tables, catalog records, orders, payments, and app preferences will be removed.'
echo 'Backup files exported outside the app remain untouched.'

if [[ "${assume_yes}" != true ]]; then
  if [[ ! -t 0 ]]; then
    echo 'Confirmation requires an interactive terminal; rerun with --yes to proceed.' >&2
    exit 2
  fi

  read -r -p 'Type RESET to continue: ' confirmation
  if [[ "${confirmation}" != 'RESET' ]]; then
    echo 'Reset cancelled. No data was changed.'
    exit 0
  fi
fi

echo 'Building the normal debug APK...'
flutter build apk --debug

echo 'Installing the normal Cafe POS APK without changing data yet...'
"${ADB}" -s "${device_id}" install -r "${apk_path}" >/dev/null

echo 'Erasing local Cafe POS data...'
clear_output="$("${ADB}" -s "${device_id}" shell pm clear "${app_id}")"
if [[ "${clear_output//$'\r'/}" != 'Success' ]]; then
  echo "Android did not confirm the reset: ${clear_output}" >&2
  exit 1
fi

echo 'Local Cafe POS data was erased successfully.'
echo 'Opening the clean application...'
if ! "${ADB}" -s "${device_id}" shell am start \
  -n "${app_id}/.MainActivity" >/dev/null; then
  echo 'The data was erased, but Android could not open Cafe POS.' >&2
  echo 'Open the application manually or run ./cafe run.' >&2
  exit 1
fi

echo 'Cafe POS is running with a fresh local database.'
