#!/bin/bash

source /opt/env.sh

path=/test_videos/$1

python3 /opt/upload.py $path $TEST_STORAGE_ACCOUNT $TEST_SAS_KEY &> /tmp/test_upload.log