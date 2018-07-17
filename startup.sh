#!/bin/bash
set -e

echo "Starting SSH ..."
service ssh start

echo AZ_STORAGE_CONTAINER=$AZ_STORAGE_CONTAINER
echo AZ_STORAGE_KEY=$AZ_STORAGE_KEY

# : ${AZ_STORAGE_CONTAINER?environment var not set}
# : ${AZ_STORAGE_KEY?environment var not set}

# Inject the environment vars into the upload script to ensure they are available from nginx
sed -i -e 's|$AZ_STORAGE_KEY|'"$AZ_STORAGE_KEY"'|' /opt/upload.sh
sed -i -e 's|$AZ_STORAGE_CONTAINER|'"$AZ_STORAGE_CONTAINER"'|' /opt/upload.sh

#/opt/upload-log.sh test.txt

echo "Starting nginx"
/opt/nginx/sbin/nginx
