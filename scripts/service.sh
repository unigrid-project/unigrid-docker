#!/bin/bash
# shellcheck disable=SC2034
# Copyright © 2021-2023 The Unigrid Foundation, UGD Software AB

# This program is free software: you can redistribute it and/or modify it under the terms of the
# addended GNU Affero General Public License as published by the Free Software Foundation, version 3
# of the License (see COPYING and COPYING.addendum).

# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
# even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Affero General Public License for more details.

# You should have received an addended copy of the GNU Affero General Public License with this program.

set -e
. /lib/lsb/init-functions

# Must be a valid filename
NAME=unigrid
PIDFILE=/run/$NAME.pid

# Full path to executable
DAEMON="/usr/bin/java -- -jar /usr/local/bin/groundhog.jar"

# Options
DAEMON_OPTS="start -t=false -ll=/usr/local/bin/ -hl=/usr/local/bin/"
DAEMON_OPTS_TESTNET="start -t -ll=/usr/local/bin/ -hl=/usr/local/bin/"
# User to run the command as
USER=$(whoami)

CLI='/usr/local/bin/unigrid-cli'

export PATH="${PATH:+$PATH:}/usr/sbin:/sbin"

CHECK_IF_RUNNING() {
      GROUNDHOG="$(! pgrep -f groundhog &> /dev/null ; echo $?)"
      echo "groundhog: ${GROUNDHOG}"
      if [ "${GROUNDHOG}" = "0" ]; then
      if [ "${1}" = "testnet" ]; 
      then
            start-stop-daemon --start --quiet --background --make-pidfile --pidfile $PIDFILE --chuid $USER --exec $DAEMON $DAEMON_OPTS_TESTNET
            else
            start-stop-daemon --start --quiet --background --make-pidfile --pidfile $PIDFILE --chuid $USER --exec $DAEMON $DAEMON_OPTS
      fi
      else
      echo -e "Groundhog is running"
      fi
}

case "$1" in
  start)
        echo -n "Starting daemon: "$NAME
        start-stop-daemon --start --quiet --background --make-pidfile --pidfile $PIDFILE --chuid $USER --exec $DAEMON $DAEMON_OPTS
        echo "."
        ;;
  start-testnet)
        echo -n "Starting daemon: "$NAME
        start-stop-daemon --start --quiet --background --make-pidfile --pidfile $PIDFILE --chuid $USER --exec $DAEMON $DAEMON_OPTS_TESTNET
        echo "."
        ;;
  stop)
        echo -n "Stopping daemon: "$NAME
        start-stop-daemon --stop --quiet --oknodo --pidfile $PIDFILE
        echo "."
        ;;
  restart)
        echo -n "Restarting daemon: "$NAME
        start-stop-daemon --stop --quiet --oknodo --retry 30 --pidfile $PIDFILE
        sleep 0.3
        start-stop-daemon --start --quiet -b -m --pidfile $PIDFILE --chuid $USER --exec $DAEMON $DAEMON_OPTS
        echo "."
        ;;
  unigrid)
        echo -e "`($CLI $2 $3 $4 $5)`"
        ;;
  check)
        CHECK_IF_RUNNING "$2"
        ;;
  status)
        status_of_proc -p $PIDFILE $DAEMON $NAME && exit 0 || exit $?
        ;;

  *)
        echo "Usage: "$1" {start|stop|restart|unigrid|check <COMMAND>}"
        exit 1
esac


