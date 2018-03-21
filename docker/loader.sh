#!/bin/bash

cd /root/
MIX_ENV=dev mix phx.server

while true
do
    sleep 100
done
