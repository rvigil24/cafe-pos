#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"

require_command flutter
require_file "${ADB}"

echo 'On the phone, open Developer options > Wireless debugging.'
echo 'Choose Pair device with pairing code.'
read -r -p 'Pairing address shown by Android (IP:port): ' pairing_address

if [[ ! "${pairing_address}" =~ ^[^:[:space:]]+:[0-9]+$ ]]; then
  echo 'Expected an address such as 192.168.1.20:37123.' >&2
  exit 2
fi

read -r -p 'Six-digit pairing code: ' pairing_code
if [[ ! "${pairing_code}" =~ ^[0-9]{6}$ ]]; then
  echo 'The pairing code must contain exactly six digits.' >&2
  exit 2
fi

printf '%s\n' "${pairing_code}" | "${ADB}" pair "${pairing_address}"
unset pairing_code

echo 'Waiting for the phone to connect...'
for _ in {1..10}; do
  if "${ADB}" devices | awk 'NR > 1 && $2 == "device" { found = 1 } END { exit !found }'; then
    "${PROJECT_ROOT}/scripts/devices.sh"
    exit 0
  fi
  sleep 1
done

phone_ip="${pairing_address%:*}"
connection_address="$(
  "${ADB}" mdns services |
    awk -v prefix="${phone_ip}:" '$2 == "_adb-tls-connect._tcp" && index($3, prefix) == 1 { print $3; exit }'
)"

if [[ -z "${connection_address}" ]]; then
  echo 'Automatic discovery did not find the connection port.'
  read -r -p 'Connection address from the Wireless debugging screen (IP:port): ' connection_address
fi

if [[ ! "${connection_address}" =~ ^[^:[:space:]]+:[0-9]+$ ]]; then
  echo 'Expected an address such as 192.168.1.20:40715.' >&2
  exit 2
fi

"${ADB}" connect "${connection_address}"
"${PROJECT_ROOT}/scripts/devices.sh"
