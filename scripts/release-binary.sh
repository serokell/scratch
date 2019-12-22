#!/usr/bin/env nix-shell
#!nix-shell -p gitAndTools.hub git -i bash

# Project name, inferred from repository name
project=$(basename $(pwd))

# The directory in which tarball will be created
TEMPDIR=`mktemp -d`

# Build release/default.nix
nix build -f release -o $TEMPDIR/$project

# Create a tarball with the result
tar --owner=serokell:1000 --mode='u+rwX' -czhf $TEMPDIR/release.tar.gz -C $TEMPDIR $project

# Delete release and tag
hub release delete auto-release
git tag -d auto-release

# Create release
hub release create -a $TEMPDIR/release.tar.gz -m "Automatic build on $(date -I)" --prerelease auto-release
