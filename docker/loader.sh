#!/bin/bash

cd /root/
MIX_ENV=mock mix phx.server

while true
do
    sleep 100
done
