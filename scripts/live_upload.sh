#!/bin/bash

source /opt/env.sh

path=/recordings/$1
output_path=/videos/$1

if [ -f "$output_path" ]
then
    echo Recording already exists $output_path
    exit
fi

yamdi -i $path -o $output_path
python3 /opt/upload.py $output_path $STORAGE_ACCOUNT $SAS_KEY
