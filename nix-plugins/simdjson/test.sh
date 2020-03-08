#!/usr/bin/env bash
set -euxo pipefail
PTH="$(nix-build --no-out-link)"
nix eval --experimental-features 'nix-command' --plugin-files $PTH/lib/simdjson.so '(assert builtins.hasSimdJson == (builtins.fromJSON "true"); true)'
