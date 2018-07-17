#!/bin/bash -x

echo filename=$1
: ${1?Filename required}

key=$AZ_STORAGE_KEY
container=$AZ_STORAGE_CONTAINER

echo container=$container
echo key=$key

# Set Source path
src=/videos/$1

echo src=$src


# Upload to azure
azcopy --source $src --destination $container/$1 --dest-key $key --dest-type blob --quiet || { echo 'azcopy failed' ; exit 1; }

# Delete the source file
rm $src
