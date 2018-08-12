#!/bin/bash

source /opt/env.sh

path=/recordings/$1

echo $path &> /tmp/test_upload.log

yamdi -i $path -o /videos/$1

python3 /opt/upload.py $path $TEST_STORAGE_ACCOUNT $TEST_SAS_KEY &> /tmp/test_upload.log