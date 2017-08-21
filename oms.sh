#!/bin/bash

## This file gathers all docker-compose.yml files from [subfolders]/docker/docker-compose.yml and merges them with the -f option of the compose command.
## Instead of docker-compose up -d, write ./oms.sh up -d


if ! [[ -f ".env" ]]; then
    echo -e "[OMS] Copying .env file from .env.example"
    cp ./.env.example ./.env
fi


## Declare docker-compose.yml folders
declare -a services=("oms-global" "oms-core")

command="docker-compose -f empty-docker-compose.yml"
for s in "${services[@]}"; do
    if [[ -f "${s}/docker/docker-compose.yml" ]]; then
        command="${command} -f ${s}/docker/docker-compose.yml"
    fi
done

command="${command} ${@}"
echo -e "\n[OMS] Full command:\n${command}\n"
eval $command
