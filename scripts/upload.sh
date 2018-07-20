#!/bin/bash

source /opt/env.sh

path=/videos/$1

python3 /opt/upload.py $path $STORAGE_ACCOUNT $SAS_KEY &> /tmp/upload.log