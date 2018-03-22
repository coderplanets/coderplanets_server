#!/bin/bash

ENGINE_PORT=5000

echo "engine running at ${ENGINE_PORT}"

docker run --env "ENGINE_CONFIG=$(cat ./engine-config.json)" -p "${ENGINE_PORT}:${ENGINE_PORT}" gcr.io/mdg-public/engine:1.0.2
