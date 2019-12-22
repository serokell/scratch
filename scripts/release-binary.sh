#!/usr/bin/env nix-shell
#!nix-shell -p gitAndTools.hub git -i bash
project=$(basename $(pwd))

TEMPDIR=`mktemp -d`

REV=`git rev-parse HEAD`

nix build -f release -o $TEMPDIR/$project

tar --owner=serokell:1000 --mode='u+rwX' -czhf $TEMPDIR/release.tar.gz -C $TEMPDIR $project

hub release delete auto-release

hub release create -a $TEMPDIR/release.tar.gz -m "Automatic build on $(date -I)" --prerelease auto-release
