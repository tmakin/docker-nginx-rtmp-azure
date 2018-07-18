#!/bin/bash
set -e

: ${1?Filename required}

src=/videos/$1
key=$STORAGE_KEY
container=$STORAGE_CONTAINER

echo src=$src
echo container=$container
echo key=${key:0:20}

# Upload to azure
azcopy --source $src --destination $container/$1 --dest-key $key --dest-type blob --quiet

# Delete the source file
rm $src
