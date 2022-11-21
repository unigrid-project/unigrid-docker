#!/bin/sh

if [ "${1}" = "testnet" ]; 
then
# startup unigrid
/usr/local/bin/ugd_service start-testnet
else
# startup unigrid
/usr/local/bin/ugd_service start
fi

env >> /etc/environment

# execute CMD
echo "$@"
exec "$@"