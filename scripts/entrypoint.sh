#!/bin/sh

if [ ! -d "$HOME/.unigrid" ]; then
  mkdir -p $HOME/.unigrid
fi

if [ "${1}" = "testnet" ]; 
then
# startup unigrid
/usr/local/bin/ugd_service start-testnet 2>&1 | awk '{ print strftime("%Y-%m-%d %H:%M:%S"), $0; fflush() }' | tee -a ~/.unigrid/ugd_service.log &
else
# startup unigrid
/usr/local/bin/ugd_service start 2>&1 | awk '{ print strftime("%Y-%m-%d %H:%M:%S"), $0; fflush() }' | tee -a ~/.unigrid/ugd_service.log &
fi

env >> /etc/environment

# execute CMD
echo "$@"
exec "$@"