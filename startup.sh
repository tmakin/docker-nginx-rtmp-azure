#!/bin/bash
set -e

# set default password
: ${PASSWORD:=password}

echo STORAGE_CONTAINER=$STORAGE_CONTAINER
echo STORAGE_KEY=${STORAGE_KEY:0:20}...
echo PASSWORD=${PASSWORD:0:3}...

: ${STORAGE_CONTAINER?environment var not set}
: ${STORAGE_KEY?environment var not set}

# Inject the environment vars into the upload script to ensure they are available from nginx
sed -i -e 's|$STORAGE_KEY|'"$STORAGE_KEY"'|' /opt/upload.sh
sed -i -e 's|$STORAGE_CONTAINER|'"$STORAGE_CONTAINER"'|' /opt/upload.sh

# geneate htpasswd file
htpasswd -b -c /opt/nginx/htpasswd admin $PASSWORD


#/opt/upload-log.sh test.txt

echo "Starting nginx"
/opt/nginx/sbin/nginx
