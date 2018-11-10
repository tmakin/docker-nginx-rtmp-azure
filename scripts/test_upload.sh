#!/bin/bash

source /opt/env.sh

path=/recordings/$1
output_path=/test_videos/$1

echo $path &> /tmp/test_upload.log

if [ -f "$output_path" ]
then
    echo Test recording already exists $output_path
    exit
fi

yamdi -i $path -o $output_path
python3 /opt/upload.py $output_path $TEST_STORAGE_ACCOUNT $TEST_SAS_KEY