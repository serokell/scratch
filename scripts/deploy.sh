#!/usr/bin/env bash
set -euo pipefail

## Deployment pipeline script
# This script is a wrapper around terraform and nixos-rebuild to deploy a
# machine given its configuration in the current folder.
#
# It needs to be called FROM the folder containing this configuration. For
# example, to deploy the temp builder, you would:
#     $ cd iac/packet/builder
#     $ ../../../scripts/deploy.sh
#
# Please note that this script will not run `terraform apply` for you. You need
# to do that yourself first.

SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

if [[ ! -d .terraform ]] && [[ ! -f configuration.nix ]]; then
    echo 'Could not find terraform state or configuration.nix in current directory.'
    exit 1
fi

if ! terraform plan -detailed-exitcode; then
    # shellcheck disable=SC2016
    echo 'Terraform has pending changes that need to be applied. Please run `terraform apply` first.'
    exit 1
fi

data="$(terraform output -json)"
value() {
    echo "$data" | jq -r ".$*.value"
}

TARGET="root@$(value ipv4_address)"
TYPE="$(value plan)"
"$SCRIPTS/tf-gen-packet-networking.sh" "$TYPE" >| packet.nix

NIXOS_CONFIG="$PWD/configuration.nix" "$SCRIPTS/nixos-rebuild" --target-host "$TARGET" --build-host localhost switch
