#!/usr/bin/env bash
set -euo pipefail

## Packet-compatible networking configuration nix expression generator
#
# Please note that different machine types ship with different configurations,
# which is why each machine type is explicitly separated. We will add more types
# to the list as we start using them.
#
# The script will print a nix expression to stdout.
#
# Usage:
#     tf-gen-packet-networking.sh <type> > packet.nix
#
# Currently supported machine types:
#   * c2.medium.x86

if [[ ! -d .terraform ]]; then
    echo 'Could not find terraform state in current directory.'
    exit 1
fi

data="$(terraform output -json)"
value() {
    echo "$data" | jq -r ".$*.value"
}

case "${1:-none}" in
    c2.medium.x86)
    cat <<-EOF
    {
    networking.hostId = "$(head -c4 /dev/urandom | od -A none -t x4 | awk '{$1=$1};1')";
    networking.hostName = "$(value 'hostname')";
    networking.defaultGateway = {
        address =  "$(value 'ipv4_gateway')";
    };

    networking.defaultGateway6 = {
        address = "$(value 'ipv6_gateway')";
    };

    networking.interfaces.bond0 = {

        ipv4 = {
        routes = [
            {
            address = "10.0.0.0";
            prefixLength = 8;
            via = "$(value 'private_gateway')";
            }
        ];
        addresses = [
            {
            address = "$(value 'ipv4_address')";
            prefixLength = $(value 'ipv4_cidr');
            }
            {
            address = "$(value 'private_address')";
            prefixLength = $(value 'private_cidr');
            }
        ];
        };

        ipv6 = {
        addresses = [
            {
            address = "$(value 'ipv6_address')";
            prefixLength = $(value 'ipv6_cidr');
            }
        ];
        };
    };
    }
		EOF
    # BEWARE: line above needs to be indented with tabs, NOT SPACES.
    ;;

    none)
        echo 'Please specify an instance type:'
        echo '  * c2.medium.x86'
        exit 1
        ;;

    *)
        echo 'Unknown instance type'
        exit 1
        ;;
esac
