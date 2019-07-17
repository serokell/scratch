#!/usr/bin/env bash
set -euo pipefail
SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# if [[ -z ${IN_NIX_SHELL:-} ]]; then
#     echo 'Please run this command in nix-shell'
#     exit 1
# fi

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
