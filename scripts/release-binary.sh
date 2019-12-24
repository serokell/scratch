#!/usr/bin/env nix-shell
#!nix-shell -p gitAndTools.hub git -i bash

# This script will create a new GitHub (pre-)release for the current repository with tag `auto-release`.
# If such tag already exists, it will be overwritten.
# It will automatically build `release/default.nix` and put its result into a tar archive that will be attached to the release.

# Suggested usage:
# 1. Make sure your repository has `release/default.nix` that produces whatever you want to release.
# 2. Run this script from CI on each commit to master.
# 3. When you think it's time to make a real release, edit the auto release: change the tag, write a description, remove "pre-release" checkmark.

set -euo pipefail

# Project name, inferred from repository name
project=$(basename $(pwd))

# The directory in which tarball will be created
TEMPDIR=`mktemp -d`

# Build release/default.nix
nix-build release -o $TEMPDIR/$project

# Create a tarball with the result
tar --owner=serokell:1000 --mode='u+rwX' -czhf $TEMPDIR/release.tar.gz -C $TEMPDIR $project

# Delete release
hub release delete auto-release

# Update the tag
git fetch # So that the script can be run from an arbitrary checkout
git tag -f auto-release
git push --force --tags

# Create release
hub release create -a $TEMPDIR/release.tar.gz -m "Automatic build on $(date -I)" --prerelease auto-release
