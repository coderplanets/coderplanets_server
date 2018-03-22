#!/bin/bash

ENV="prod"

PRJ_DIR="./"
BRANCH_NAME="master"
ARCHIVE_NAME="./docker/production/mastani_server.tar.gz"

cd "${PRJ_DIR}"
# git checkout "${BRANCH_NAME}"
# git fetch --all
# git reset --hard origin/"${BRANCH_NAME}"

echo "[STEP 1/5] mix deps.get ..."
mix deps.get
echo "[STEP 2/5] MIX_ENV=${ENV} mix compile ..."
MIX_ENV="${ENV}" mix compile

echo "[STEP 3/5] creating ${ARCHIVE_NAME} ..."
tar czf "${ARCHIVE_NAME}" _build/ config/ deps/ lib/ mix.exs  mix.lock  priv/ test/

echo "[STEP 4/5] tar complete!"
echo "[STEP 4/6] run git push to push the code to ali-cloud to finish!"
