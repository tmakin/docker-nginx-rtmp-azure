#!/bin/sh

# delete files more than 60 mins old
find /videos -name *.* -mmin +60 -delete
find /test_videos -name *.* -mmin +60 -delete
