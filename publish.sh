#!/bin/bash

ENV="$1"

if [ "$ENV" == "prod" ];then
    echo "running ./docker/production/builder.sh"
    ./docker/production/builder.sh
elif [ "$ENV" == "dev" ]
then
    echo "do dev"
else
    echo "invalid publish env, support env: dev / prod"
    echo "usage: ./publish.sh dev OR ./publish.sh prod"
fi
