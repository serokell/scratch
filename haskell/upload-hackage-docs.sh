#!/usr/bin/env bash

# SPDX-FileCopyrightText: 2020 Serokell <https://serokell.io/>
#
# SPDX-License-Identifier: MPL-2.0

# Authors: @maksbotan, @gromak

# Use this script if you want to manually upload documentation to Hackage and prefer `stack`.
# Sometimes Hackage fails to build your package and you don't want to fix
# it but want to make your documentation available.
# You need to specify:
# • ${PACKAGE_NAME} is a name of a package you are uploading docs for
# • ${PACKAGE_DIR} is a relative path to that package's directory
# • ${HACKAGE_TOKEN} is an authentication token that you can get from your Hackage profile page.
# • Instead of ${HACKAGE_TOKEN} you can specify ${HACKAGE_USERNAME} and ${HACKAGE_PASSWORD}.

set -euo pipefail

stack build --haddock "${PACKAGE_NAME}"
# Check that package is ok
stack sdist "${PACKAGE_DIR}"
# Upload it and ignore errors because it might be already uploaded
stack upload "${PACKAGE_DIR}" || true

dist=$(stack path --dist-dir 2>/dev/null)
version=$(stack query locals "${PACKAGE_NAME}" version 2>/dev/null)
cd "${PACKAGE_DIR}/${dist}/doc/html"
# Hackage expects documentation in dir with -docs suffix.
cp -r "${PACKAGE_NAME}" "${PACKAGE_NAME}-${version}-docs"
# Hackage does not like GNU tar's default format, have to use "ustar".
tar cvz --format=ustar -f "${PACKAGE_NAME}.tar.gz" "${PACKAGE_NAME}-${version}-docs"

if [ -z "${HACKAGE_TOKEN:-}" ]; then
    echo "I will upload documentation using username and password since token is not provided"
    curl -X PUT -H 'Content-Type: application/x-tar' -H 'Content-Encoding: gzip' \
        --data-binary "@${PACKAGE_NAME}.tar.gz" \
        "https://${HACKAGE_USERNAME}:${HACKAGE_PASSWORD}@hackage.haskell.org/package/${PACKAGE_NAME}-${version}/docs"
else
    echo "I will upload documentation using authentication token"
    curl -X PUT -H 'Content-Type: application/x-tar' -H 'Content-Encoding: gzip' \
        -H "Authorization: X-ApiKey ${HACKAGE_TOKEN}" \
        --data-binary "@${PACKAGE_NAME}.tar.gz" \
        "https://hackage.haskell.org/package/${PACKAGE_NAME}-${version}/docs"
fi
