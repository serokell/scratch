#!/usr/bin/env nix-shell
#!nix-shell -p gitAndTools.hub -i bash
project=$(basename $(pwd))

nix build -f release -o $project

tar --owner=serokell:1000 -czf release.tar.gz $project

if hub release | grep nightly
then
    action=edit
else
    action=create
fi

hub release $action -a release.tar.gz -m "Nightly build on $(date -I)" --draft=true --prerelease nightly
