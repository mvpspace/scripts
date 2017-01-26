# scripts
A lot of useful scripts

# METEOR DEPLOYMENTS USING DOCKER
## DEPLOYMENT

### STAND ALONE
* To deploy to staging from the root of the app `bash path/to/deployitremote.sh`. It is critical that you invoke the script from the root folder of your app.

Input the remote server password if asked.

[Works with Digital Ocean droplets (tested). Should work with any remote server accessible via ssh]

You may also deploy to your local machine to see how things are working using `bash path/to/deployitlocal.sh`

Go to http://localhost:3000

## NGINX PROXY
* To deploy to staging from the root of the app `bash path/to/with-nginx/deployitremote.sh`

Input the server password if asked.

You may also deploy to your local machine to see how things are working using `bash path/to/with-nginx/deployitlocal.sh`

Go to http://localhost


# MONGODB

## RESET THE DB
To reset the mongo db use the following script inside `path/to/resetremotedb.sh` like this:
`cd path/to/script_folder`
`bash resetremotedb.sh`

or simply from the app root folder:
`bash /path/to/resetremotedb.sh`

**NOTE**: Make sure you have docker installed on either on your machine or remote server depending on where you are deploying
