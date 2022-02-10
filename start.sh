#!/bin/bash
docker-compose -f ./docker-compose.yaml down
mkdir -pv volume/svnadmin
mkdir -pv volume/svnconf
mkdir -pv volume/svnrepo
chmod -Rfv 777 volume/svnadmin 
chmod -Rfv 777 volume/svnconf
chmod -Rfv 777 volume/svnrepo
docker-compose -f ./docker-compose.yaml build --force-rm --build-arg CACHE_DATE=$(date +%Y-%m-%d:%H:%M:%S) && \
docker-compose -f ./docker-compose.yaml up -d