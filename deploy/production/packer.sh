#!/bin/bash

ENV="production"

PRJ_DIR="./"
PACKER_TMP_DIR="./packer_tmp"
ARCHIVE_NAME="./deploy/${ENV}/api_server.tar.gz"
TOTAL_STEPS=5

cd "${PRJ_DIR}"

# echo "[Step 1/${TOTAL_STEPS}] mix deps.get ..."
# mix deps.get
# echo "[Step 2/${TOTAL_STEPS}] MIX_ENV=${ENV} mix compile ..."
# MIX_ENV="${ENV}" mix compile

echo "[Step 1/${TOTAL_STEPS}] create tmp packer dir..."
if [ -d "${PACKER_TMP_DIR}" ]; then
    echo "remove ${PACKER_TMP_DIR}"
    rm -rf "${PACKER_TMP_DIR}"
fi

# mkdir -p "$PACKER_TMP_DIR/{config, lib, priv}/" # not work
mkdir -p "${PACKER_TMP_DIR}/config"
mkdir -p "${PACKER_TMP_DIR}/lib"
mkdir -p "${PACKER_TMP_DIR}/priv"
mkdir -p "${PACKER_TMP_DIR}/test/support"

echo "[Step 3/${TOTAL_STEPS}] creating ${ARCHIVE_NAME} ..."

cp mix.exs "${PACKER_TMP_DIR}/"
cp Makefile "${PACKER_TMP_DIR}/"
cp Makefile.include.mk "${PACKER_TMP_DIR}/"
cp config/prod.exs "${PACKER_TMP_DIR}/config"
cp config/config.exs "${PACKER_TMP_DIR}/config"
cp test/support/factory.ex "${PACKER_TMP_DIR}/test/support"
cp -rf lib/* "${PACKER_TMP_DIR}/lib"
cp -rf priv/* "${PACKER_TMP_DIR}/priv"

cd "${PACKER_TMP_DIR}"
tar czvf api_server.tar.gz *
cd ..
mv "${PACKER_TMP_DIR}/api_server.tar.gz" "${ARCHIVE_NAME}"
rm -rf packer_tmp

echo "[Step 4/${TOTAL_STEPS}] ${ARCHIVE_NAME} created!"
echo "------------------------------------------------"
echo "[Step 4/${TOTAL_STEPS}] run git push to push the code to ali-cloud to finish!"
