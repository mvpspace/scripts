#!/bin/bash

###################
## CONFIG VARS ####
APP_NAME=myapp
APP_DOMAIN=localhost
# SETTINGS_PATH SHOULD BE EITHER A RELATIVE PATH FROM THE APP ROOT OR AN ABSOLUTE PATH
SETTINGS_PATH=phat/to/settings.json
NGINX_CONF_PATH=.phat/to/with-nginx/nginx.conf
MONGO_URL=172.17.0.2
MONGO_PORT=27017
MONGO_DB=dbname
###################

echo "=> Removing /tmp/${APP_NAME}"
rm -R /tmp/${APP_NAME}

echo "=> Executing Meteor Build..."
meteor build \
  --allow-superuser \
  --directory /tmp/${APP_NAME} \
  --server=http://${APP_DOMAIN}:${APP_PORT}/

echo "=> Copying settings file"
cp ${SETTINGS_PATH} /tmp/${APP_NAME}/bundle/settings.json

echo "=> Copying nginx.conf file"
cp ${NGINX_CONF_PATH} /tmp/${APP_NAME}/bundle/nginx.conf

echo "=> Moving to /tmp/${APP_NAME}/bundle"
cd /tmp/${APP_NAME}/bundle

echo "=> Creating package.json..."
cat > package.json <<- "EOF"
{
    "name": "app",
    "version": "1.0.0",
    "scripts": {
        "start": "METEOR_SETTINGS=$(cat settings.json) node main.js"
    }
}
EOF

echo "=> Creating Dockerfile for NGINX..."
cat > Dockerfile.nginx <<EOF
# Pull base image.
FROM nginx
COPY nginx.conf /etc/nginx/nginx.conf
EOF

echo "=> Creating Dockerfile for Meteor..."
cat > Dockerfile.meteor <<EOF
# Pull base image.
FROM mhart/alpine-node:4

# Install build tools to compile native npm modules
RUN apk add --update build-base python

# Create app directory
RUN mkdir -p /usr/app

COPY . /usr/app

RUN cd /usr/app/programs/server && npm install --production

WORKDIR /usr/app

ENV PORT=3000
ENV MONGO_URL=mongodb://$MONGO_URL:$MONGO_PORT/$MONGO_DB
ENV ROOT_URL=http://$APP_DOMAIN:$APP_PORT/
CMD [ "npm", "start" ]
EXPOSE 3000
EOF

echo "=> Building docker image for Meteor..."
docker stop ${APP_NAME}
docker rm -f ${APP_NAME}
docker rmi -f ${APP_NAME}
docker build -f Dockerfile.meteor -t ${APP_NAME} .

echo "=> Building docker image for NGINX..."
docker stop nginx
docker rm -f nginx
docker build -f Dockerfile.nginx -t nginx .

echo "=> Starting NGINX container..."
docker run --name nginx -d -p 80:80 nginx

echo "=> Starting ${APP_NAME} meteor container..."
docker run -d --name ${APP_NAME} ${APP_NAME}