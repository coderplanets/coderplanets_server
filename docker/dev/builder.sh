#!/bin/bash

ENV="dev"

PRJ_DIR="./"
BRANCH_NAME="dev"
ARCHIVE_NAME="./docker/${ENV}/mastani_server.tar.gz"
TOTAL_STEPS=5

cd "${PRJ_DIR}"
# git checkout "${BRANCH_NAME}"
# git fetch --all
# git reset --hard origin/"${BRANCH_NAME}"

echo "[Step 1/${TOTAL_STEPS}] mix deps.get ..."
mix deps.get
echo "[Step 2/${TOTAL_STEPS}] MIX_ENV=${ENV} mix compile ..."
MIX_ENV="${ENV}" mix compile

echo "[Step 3/${TOTAL_STEPS}] creating ${ARCHIVE_NAME} ..."
tar czf "${ARCHIVE_NAME}" _build/ config/ deps/ lib/ mix.exs  mix.lock  priv/ test/

echo "[Step 4/${TOTAL_STEPS}] ${ARCHIVE_NAME} created!"
echo "------------------------------------------------"
echo "[Step 4/${TOTAL_STEPS}] run git push to push the code to ali-cloud to finish!"
