#!/bin/sh

# startup unigrid
/usr/local/bin/ugd_service start

env >> /etc/environment

# execute CMD
echo "$@"
exec "$@"