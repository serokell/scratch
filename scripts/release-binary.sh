#!/usr/bin/env nix-shell
#!nix-shell -p gitAndTools.hub -i bash
nix build -f release

cp -r result/bin .
tar --owner=serokell:1000 -czf release.tar.gz README.md LICENSE bin/*

if hub release | grep nightly
then
    action=edit
else
    action=create
fi

hub release $action -a release.tar.gz -m "Nightly build on $(date -I)" --draft=true --prerelease nightly
