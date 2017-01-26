#!/bin/bash

###################
## CONFIG VARS ####
APP_NAME=myapp
APP_DOMAIN=serverdomain.com
APP_PORT=80
SETTINGS_PATH=phat/to/settings.json
NGINX_CONF_PATH=phat/to/with-nginx/nginx.conf
REMOTE_SERVER=0.0.0.0
MONGO_URI=whathever.mlab.com
MONGO_CREDENTIALS=dbuser:dbpassword
MONGO_PORT=41328
MONGO_DB=dbname
####################

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
ENV MONGO_URL=mongodb://$MONGO_CREDENTIALS@$MONGO_URI:$MONGO_PORT/$MONGO_DB
ENV ROOT_URL=http://$APP_DOMAIN:$APP_PORT/
CMD [ "npm", "start" ]
EXPOSE 3000
EOF

echo "=> Creating ${APP_NAME}.tar.gz ..."
cd ..
tar czvf ${APP_NAME}.tar.gz bundle

echo "=> Uploading ${APP_NAME}.tar.gz to remote server..."
cat ${APP_NAME}.tar.gz | ssh root@${REMOTE_SERVER} "tar zxvf - -C /tmp && docker stop ${APP_NAME} ; docker rm -f ${APP_NAME} ; docker rmi -f ${APP_NAME} ; docker stop nginx ; docker rm -f nginx ; cd /tmp/bundle && docker build  -f Dockerfile.meteor -t ${APP_NAME} . && docker build -f Dockerfile.nginx -t nginx . && rm -R /tmp/bundle | rm /tmp/${APP_NAME}.tar.gz ; docker run --name nginx -d -p ${APP_PORT}:80 nginx && docker run --name ${APP_NAME} ${APP_NAME}"