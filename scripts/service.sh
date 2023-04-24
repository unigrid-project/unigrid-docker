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
PIDFILE_UNIGRIDD=$HOME/.unigrid/unigridd.pid
PIDFILE_GROUNDHOG=$HOME/.unigrid/groundhog.pid
PIDFILE_HEDGEHOG=$HOME/.unigrid/hedgehog.pid

# Full path to java executable
DAEMON_DIR="/usr/bin/java"

# Options for java and jar file
DAEMON_OPTS="-jar /usr/local/bin/groundhog.jar start -t=false -ll=/usr/local/bin/ -hl=/usr/local/bin/"
DAEMON_OPTS_TESTNET="-jar /usr/local/bin/groundhog.jar start -t -ll=/usr/local/bin/ -hl=/usr/local/bin/"


# example start directly on groundhog
# /usr/bin/java -jar /usr/local/bin/groundhog.jar start -t=false -ll=/usr/local/bin/ -hl=/usr/local/bin/
# /usr/bin/java -jar /usr/local/bin/groundhog.jar start -t=false -ll=/usr/local/bin/ -hl=/usr/local/bin/ > ~/.unigrid/groundhog.log 2>&1


# User to run the command as
USER=$(logname 2>/dev/null || echo "${USER:-$(whoami)}")


CLI='/usr/local/bin/unigrid-cli'

export PATH="${PATH:+$PATH:}/usr/sbin:/sbin"

CHECK_IF_RUNNING() {
      GROUNDHOG="$(! pgrep -f groundhog.jar &> /dev/null ; echo $?)"
      echo "groundhog: ${GROUNDHOG}"
      UNIGRID="$(! pgrep -f unigridd &> /dev/null ; echo $?)"
      echo "unigridd: ${UNIGRID}"
      HEDGEHOG="$(! pgrep -f hedgehog.bin &> /dev/null ; echo $?)"
      echo "hedgehog: ${HEDGEHOG}"
      if [ "${GROUNDHOG}" = "0" ]; then
      if [ "${1}" = "testnet" ]; 
      then
            start-stop-daemon --start --quiet --background --make-pidfile --pidfile $PIDFILE_GROUNDHOG --chuid $USER --exec /bin/sh -- -c "$DAEMON_DIR $DAEMON_OPTS_TESTNET"
      else
            start-stop-daemon --start --quiet --background --make-pidfile --pidfile $PIDFILE_GROUNDHOG --chuid $USER --exec /bin/sh -- -c "$DAEMON_DIR $DAEMON_OPTS"
      fi
      else
      echo -e "Groundhog is running"
      fi
}

case "$1" in
  start)
        echo -n "Starting groundhog: "
        start-stop-daemon --start --quiet --background --make-pidfile --pidfile $PIDFILE_GROUNDHOG --chuid $USER --exec /bin/sh -- -c "$DAEMON_DIR $DAEMON_OPTS"
        echo "Groundhog started."

        # Wait for unigridd and hedgehog to start
        sleep 5

        # Find the PIDs of unigridd and hedgehog and store them in their respective PID files

        pgrep -f unigridd > $PIDFILE_UNIGRIDD
        chown $USER $PIDFILE_UNIGRIDD
        pgrep -f hedgehog.bin > $PIDFILE_HEDGEHOG
        chown $USER $PIDFILE_HEDGEHOG
        ;;
  start-testnet)
        echo -n "Starting daemon: "$NAME
        start-stop-daemon --start --quiet --background --make-pidfile --pidfile $PIDFILE_GROUNDHOG --chuid $USER --exec /bin/sh -- -c "$DAEMON_DIR $DAEMON_OPTS_TESTNET"
        # Wait for unigridd and hedgehog to start
        sleep 5

        # Find the PIDs of unigridd and hedgehog and store them in their respective PID files
        pgrep -f unigridd > $PIDFILE_UNIGRIDD
        chown $USER $PIDFILE_UNIGRIDD
        pgrep -f hedgehog.bin > $PIDFILE_HEDGEHOG
        chown $USER $PIDFILE_HEDGEHOG
        echo "Starting testnet"
        ;;
    stop)
        echo -n "Stopping groundhog daemon: "
        start-stop-daemon --stop --quiet --oknodo --pidfile $PIDFILE_GROUNDHOG
        rm -f $PIDFILE_GROUNDHOG
        echo "Groundhog stopped."

        echo -n "Stopping unigridd daemon: "
        start-stop-daemon --stop --quiet --oknodo --pidfile $PIDFILE_UNIGRIDD
        rm -f $PIDFILE_UNIGRIDD
        echo "Unigridd stopped."

        echo -n "Stopping hedgehog daemon: "
        start-stop-daemon --stop --quiet --oknodo --pidfile $PIDFILE_HEDGEHOG
        rm -f $PIDFILE_HEDGEHOG
        echo "Hedgehog stopped."
        ;;
  restart)
        echo -n "Restarting unigridd daemon: "
        start-stop-daemon --stop --quiet --oknodo --retry 30 --pidfile $PIDFILE_UNIGRIDD
        sleep 0.3
        pgrep -f unigridd > $PIDFILE_UNIGRIDD
        echo "Unigridd restarted."

        echo -n "Restarting hedgehog daemon: "
        start-stop-daemon --stop --quiet --oknodo --retry 30 --pidfile $PIDFILE_HEDGEHOG
        sleep 0.3
        pgrep -f hedgehog > $PIDFILE_HEDGEHOG
        echo "Hedgehog restarted."

        echo -n "Restarting groundhog daemon: "
        start-stop-daemon --stop --quiet --oknodo --retry 30 --pidfile $PIDFILE_GROUNDHOG
        sleep 0.3
        start-stop-daemon --start --quiet --background --make-pidfile --pidfile $PIDFILE_GROUNDHOG --chuid $USER --exec /bin/sh -- -c "$DAEMON_DIR $DAEMON_OPTS"
        # Update the PIDs of unigridd and hedgehog and store them in their respective PID files
        pgrep -f unigridd > $PIDFILE_UNIGRIDD
        chown $USER $PIDFILE_UNIGRIDD
        pgrep -f hedgehog > $PIDFILE_HEDGEHOG
        chown $USER $PIDFILE_HEDGEHOG
        echo "Groundhog restarted."
        ;;
  unigrid)
        echo -e "`($CLI $2 $3 $4 $5)`"
        ;;
  check)
        CHECK_IF_RUNNING "$2"
        ;;
  status)
        status_of_proc -p $PIDFILE_GROUNDHOG $DAEMON_DIR $NAME && exit 0 || exit $?
        ;;

  *)
        echo "Usage: "$1" {start|stop|restart|check|unigrid <COMMAND>}"
        exit 1
esac

