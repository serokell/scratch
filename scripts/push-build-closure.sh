#!/usr/bin/env bash

# SPDX-FileCopyrightText: 2020 Serokell <https://serokell.io/>
# SPDX-License-Identifier: MPL-2.0

###
#
# Take a path and make sure everything needed to build it is present in the
# remote store (e.g. a binary cache) and signed.
#
# Use:
#
#   push-build-closure.sh <store> <path>
#

store="$1"
target="$2"
[ -z "$store" -o -z "$target" ] && { echo "Usage: $0 <store> <path>" >&2; exit 1; }

# Get the closure of the deriver of our target path
deriver=$(nix-store -q --deriver "$target")
deriver_deps=$(nix-store -q -R "$deriver")

# Closure of everything needed to build our target path
all_outputs=$(nix-store -q -R $(nix-store -r $deriver_deps))

# Make sure we have everything locally
nix-store -r $all_outputs
# Copy everything to the remote store
# (IIUC, it will not copy if the path is already present there)
nix copy --to "$store" $all_outputs
# Explicitly sign just in case something was already there but was not signed
# (IIUC, it will not sign if it belives the path is already signed)
nix sign-paths --store "$store" -k /root/nix-binary-cache.key $all_outputs
