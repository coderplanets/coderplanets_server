#!/bin/bash

ENV="dev"

PRJ_DIR="./"
BRANCH_NAME="master"
ARCHIVE_NAME="./docker/mastani_server.tar.gz"

cd "${PRJ_DIR}"
git checkout "${BRANCH_NAME}"
# git pull origin/master
git fetch --all
git reset --hard origin/"${BRANCH_NAME}"

mix deps.get
MIX_ENV="${ENV}" mix compile

tar czf "${ARCHIVE_NAME}" _build/ config/ deps/ lib/ mix.exs  mix.lock  priv/ test/
