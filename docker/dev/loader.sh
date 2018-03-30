#!/bin/bash

cd /root/mastani_server/
MIX_ENV=dev mix phx.server &

cd /root/mastani_web/
http-server -p 4000 -s &

cd /root/mastani_api_monitor/
node index &

while true
do
    sleep 100
done
