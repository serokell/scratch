#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 3 ]]; then
  echo "usage: $0 <store_path> <target_host> {switch|reboot}"
  exit 1
fi

STORE_PATH=$(readlink -f "$1")
SSH_TARGET=$2
ACTION=$3

if [[ $ACTION != "switch" ]] && [[ $ACTION != "reboot" ]]; then
  echo "error: unknown action"
  exit 1
fi

# set to empty value if unset
export SSHOPTS=${SSHOPTS:-}

TARGET_PROFILE=/nix/var/nix/profiles/system

echo "Copying system closure"
NIX_SSHOPTS=$SSHOPTS nix copy "$STORE_PATH" --to "ssh://$SSH_TARGET" --no-check-sigs

echo "Updating system profile"
ssh $SSHOPTS "$SSH_TARGET" "nix-env --profile $TARGET_PROFILE --set $STORE_PATH"

if [[ $ACTION == "switch" ]]; then
  echo "Switching to new configuration"
  ssh $SSHOPTS "$SSH_TARGET" "$STORE_PATH/bin/switch-to-configuration switch"
elif [[ $ACTION == "reboot" ]]; then
  echo "Setting new configuration to run at boot"
  ssh $SSHOPTS "$SSH_TARGET" "$STORE_PATH/bin/switch-to-configuration boot"
  echo "Rebooting"
  ssh $SSHOPTS "$SSH_TARGET" "reboot"
fi