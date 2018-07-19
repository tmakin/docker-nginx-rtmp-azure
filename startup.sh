#!/bin/bash
set -e

: ${STORAGE_ACCOUNT?environment var not set}
: ${SAS_KEY?environment var not set}

# set default password
: ${PASSWORD:=password}

# nginx log level
: ${LOG_LEVEL:=notice}

# max video size
: ${MAX_SIZE:=100M}

# use same account for test if undefined
: ${TEST_STORAGE_ACCOUNT:=$STORAGE_ACCOUNT}
: ${TEST_SAS_KEY:=$SAS_KEY}

echo STORAGE_ACCOUNT=$STORAGE_ACCOUNT
echo SAS_KEY=${SAS_KEY:0:20}...

echo TEST_STORAGE_ACCOUNT=$TEST_STORAGE_ACCOUNT
echo TEST_SAS_KEY=${TEST_SAS_KEY:0:20}...

echo PASSWORD=${PASSWORD:0:3}...

# generate env file to be included in upload scripts
env=/opt/env.sh
echo STORAGE_ACCOUNT=$STORAGE_ACCOUNT >> $env
echo 'SAS_KEY="'$SAS_KEY'"' >> $env
echo TEST_STORAGE_ACCOUNT=$TEST_STORAGE_ACCOUNT >> $env
echo 'TEST_SAS_KEY="'$TEST_SAS_KEY'"' >> $env

# add vars to nginx Conf
sed -i -e 's|$LOG_LEVEL|'"$LOG_LEVEL"'|' /opt/nginx/nginx.conf
sed -i -e 's|$MAX_SIZE|'"$MAX_SIZE"'|' /opt/nginx/nginx.conf

# generate htpasswd file
htpasswd -b -c /opt/nginx/htpasswd admin $PASSWORD

#cat /opt/env.sh

#/bin/bash
/opt/upload.sh test.flv

echo "Starting nginx"
/opt/nginx/sbin/nginx
