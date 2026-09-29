#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"

require_command flutter
require_file "${ADB}"

echo 'Android devices:'
"${ADB}" devices -l

echo 'Flutter devices:'
flutter devices
