#!/bin/sh

# delete files more than 60 mins old
find /recordings -name *.* -mmin +60 -delete
find /videos -name *.* -mmin +60 -delete
