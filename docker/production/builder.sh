#!/bin/bash

ENV="prod"

PRJ_DIR="./"
BRANCH_NAME="master"
ARCHIVE_NAME="./docker/production/mastani_server.tar.gz"

cd "${PRJ_DIR}"
# git checkout "${BRANCH_NAME}"
# git fetch --all
# git reset --hard origin/"${BRANCH_NAME}"

echo "mix deps.get ..."
mix deps.get
echo "MIX_ENV=${ENV} mix compile ..."
MIX_ENV="${ENV}" mix compile

echo "creating ${ARCHIVE_NAME} ..."
tar czf "${ARCHIVE_NAME}" _build/ config/ deps/ lib/ mix.exs  mix.lock  priv/ test/
