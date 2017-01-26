#!/bin/bash

###################
## CONFIG VARS ####
APP_NAME=myapp
REMOTE_SERVER=SERVER_IP
MONGO_CONTAINER=mongodb
MONGO_URL=DOCKER_IP
## It should be MONGO_URL=172.17.0.2
MONGO_PORT=27017
MONGO_DB=dbname
###################

echo "=> Connecting to remote server..."
ssh root@${REMOTE_SERVER} "docker stop ${APP_NAME} && docker start ${MONGO_CONTAINER} && docker exec -i ${MONGO_CONTAINER} mongo ${MONGO_DB} --eval 'db.dropDatabase()' && docker start ${APP_NAME}"