#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"

require_command flutter
require_command dart

echo 'Resolving dependencies...'
flutter pub get

echo 'Checking formatting...'
dart format --output=none --set-exit-if-changed .

echo 'Running static analysis...'
flutter analyze

echo 'Running unit and widget tests...'
flutter test

echo 'Fast checks passed.'
