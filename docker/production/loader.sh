#!/bin/bash

cd /root/mastani_server/
MIX_ENV=dev mix phx.server &

cd /root/mastani_web/
http-server -p 5000 -s &

while true
do
    sleep 100
done
