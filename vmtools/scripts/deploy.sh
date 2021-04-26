#!/usr/bin/env bash
set -euo pipefail

NIX_COPY_OPTS=()
if [[ ${1:-} == "--substitute-on-destination" ]] || [[ ${1:-} == "-s" ]]; then
  NIX_COPY_OPTS=("--substitute-on-destination")
  shift
fi

if [[ $# -ne 3 ]]; then
  echo "usage: $0 [--substitute-on-destination|-s] <store_path> <target_host> {switch|reboot|boot|copy}"
  exit 1
fi

STORE_PATH=$(readlink -f "$1")
SSH_TARGET=$2
ACTION=$3

if \
  [[ $ACTION != "switch" ]] && \
  [[ $ACTION != "boot" ]] && \
  [[ $ACTION != "reboot" ]] && \
  [[ $ACTION != "copy" ]]; \
  then
  echo "error: unknown action: $ACTION"
  exit 1
fi

# set to empty string if unset
export SSHOPTS=${SSHOPTS:-}

# enable ssh multiplexing to reuse a single ssh connection for all commands
SSH_CONTROL_DIR=$(mktemp -d)
SSHOPTS="$SSHOPTS -o ControlMaster=auto -o ControlPath=$SSH_CONTROL_DIR/control -o ControlPersist=60"
cleanup_ssh_control() {
  if [[ -e "$SSH_CONTROL_DIR/control" ]]; then
    # stop accepting connections
    ssh -o "ControlPath=$SSH_CONTROL_DIR/control" -O exit dummyhost 2>/dev/null || true
  fi
  rm -rf "$SSH_CONTROL_DIR"
}
trap cleanup_ssh_control EXIT

# calculate system closure size
CLOSURE_SIZE=$(du -hc $(nix-store -qR "$STORE_PATH") | tail -1 | cut -f1)

echo "* Copying system closure ($CLOSURE_SIZE)"
NIX_SSHOPTS=$SSHOPTS nix copy "$STORE_PATH" --to "ssh://$SSH_TARGET" --no-check-sigs "${NIX_COPY_OPTS[@]}"

if [[ $ACTION == "copy" ]]; then
  echo '* Copy finished'
  exit 0
fi

echo "* Updating system profile"
TARGET_PROFILE=/nix/var/nix/profiles/system
ssh $SSHOPTS "$SSH_TARGET" "sudo nix-env --profile $TARGET_PROFILE --set $STORE_PATH"

if [[ $ACTION == "switch" ]]; then
  echo "* Switching to new configuration"
  ssh $SSHOPTS "$SSH_TARGET" "sudo $STORE_PATH/bin/switch-to-configuration switch"
  echo "* Switched to new configuration"
elif [[ $ACTION == "boot" ]]; then
  echo "* Setting new configuration to run at boot"
  ssh $SSHOPTS "$SSH_TARGET" "sudo $STORE_PATH/bin/switch-to-configuration boot"
  echo "* Done"
elif [[ $ACTION == "reboot" ]]; then
  echo "* Setting new configuration to run at boot"
  ssh $SSHOPTS "$SSH_TARGET" "sudo $STORE_PATH/bin/switch-to-configuration boot"
  echo "* Rebooting"
  ssh $SSHOPTS "$SSH_TARGET" "sudo reboot & exit"
fi
