#!/bin/bash

PRJ_DIR="./docker"
BRANCH_NAME="master"
ARCHIVE_NAME="mastani_server.tar.gz"

cd "${PRJ_DIR}"
git checkout "${BRANCH_NAME}"
git fetch --all
git reset --hard origin/"${BRANCH_NAME}"

mix deps.get --only prod
MIX_ENV=prod mix compile

tar czf "${ARCHIVE_NAME}" _build/ config/ deps/ lib/ mix.exs  mix.lock  priv/
