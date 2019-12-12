#!/usr/bin/env nix-shell
#!nix-shell -p git jq gitAndTools.hub niv -i bash

set -euo pipefail

author="serokell-bot <operations+github@serokell.io>"

# Make sure "git push" works
export GIT_ASKPASS=`mktemp`

chmod +x $GIT_ASKPASS

echo 'printf "$GITHUB_TOKEN\n\n"' > $GIT_ASKPASS

# Print all packages in format "package-name revision"
pkgs() {
    jq ".[] | .repo, .rev" nix/sources.json | tr -d \" | xargs -n2 echo
}

# Print the differences between $1 and $2 (outputs of pkgs) in format of "package-name: oldrev->newrev"
changes() {
    diff -y --suppress-common-lines <(echo "$1") <(echo "$2") \
        | awk '{print $1": "substr($2, 0, 7)"->"substr($5, 0, 7)}' \
        | column -t
}

# Send a pull request with a message $1
new_pr() {
    hub pull-request --no-edit -r serokell/operations -m "Update dependencies [automatic]" -m "$1"
}

# If there is no nix folder, don't do anything
[ -d nix ]

git checkout -B "automatic/update"

# In case niv's sources.nix file changed
niv init
[ $(git diff | wc -l) -eq 0 ] || { # Commit only if there are changes
    git add nix
    git commit --author="$author" -m "Update niv's sources.nix file [automatic]"
}

before="$(pkgs)"

niv update

after="$(pkgs)"


[ $(git diff | wc -l) -eq 0 ] || { # Commit only if there are changes
    git add nix
    git commit --author="$author" -m "Update dependencies with niv [automatic]" -m "$(changes "$before" "$after")"
}


[ $(git diff origin/master | wc -l) -eq 0 ] || {
    # --force is so that if there is a PR already, we're still pushing to it
    git push --force --set-upstream origin automatic/update
    # Submit a PR if there isn't one already 
    hub pr list | grep "Update dependencies \[automatic\]" || new_pr "\`\`\`$(changes "$before" "$after")\`\`\`"
}
