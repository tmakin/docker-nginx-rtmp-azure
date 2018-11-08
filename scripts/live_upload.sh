#!/bin/bash

source /opt/env.sh

path=/recordings/$1

yamdi -i $path -o /videos/$1

python3 /opt/upload.py $path $STORAGE_ACCOUNT $SAS_KEY
