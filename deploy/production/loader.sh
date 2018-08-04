#!/bin/bash

cd /root/api_server/

MIX_ENV=prod mix phx.server &

while true
do
    sleep 100
done
