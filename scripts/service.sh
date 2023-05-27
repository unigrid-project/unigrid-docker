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

# Full path to java executable
DAEMON_DIR="/usr/bin/java"

# Options for java and jar file
DAEMON_OPTS="-jar /usr/local/bin/groundhog.jar start -t=false -ll=/usr/local/bin/ -hl=/usr/local/bin/"   #--hp=<someport>
DAEMON_OPTS_TESTNET="-jar /usr/local/bin/groundhog.jar start -t -ll=/usr/local/bin/ -hl=/usr/local/bin/" #--hp=<someport>

# User to run the command as
USER=$(logname 2>/dev/null || echo "${USER:-$(whoami)}")

LOGFILE="$HOME/.unigrid/ugd_service.log"

CLI='/usr/local/bin/unigrid-cli'

export PATH="${PATH:+$PATH:}/usr/sbin:/sbin"

CHECK_IF_RUNNING() {
      GROUNDHOG="$(
            ! pgrep -f groundhog &>/dev/null
            echo $?
      )"
      echo "groundhog: ${GROUNDHOG}"
      UNIGRID="$(
            ! pgrep -f unigridd &>/dev/null
            echo $?
      )"
      echo "unigridd: ${UNIGRID}"
      HEDGEHOG="$(
            ! pgrep -f hedgehog &>/dev/null
            echo $?
      )"
      echo "hedgehog: ${HEDGEHOG}"
      if [ "${GROUNDHOG}" = "0" ]; then
            if [ "${1}" = "testnet" ]; then
                  echo "$(date) - Grounding was not running, starting now." >>"${LOGFILE}"
                  start-stop-daemon --start --quiet --background --chuid $USER --exec /bin/sh -- -c "$DAEMON_DIR $DAEMON_OPTS_TESTNET"
            else
                  start-stop-daemon --start --quiet --background --chuid $USER --exec /bin/sh -- -c "$DAEMON_DIR $DAEMON_OPTS"
            fi
      else
            echo -e "Groundhog is running"
      fi
}

CHECK_PORT() {
      # Define the file that contains the rpcport line
      PORT_TXT="$HOME/.unigrid/port.txt"
      PORT_OPTS=''
      if [ -f "$PORT_TXT" ]; then
            PORT=$(cat "$PORT_TXT")
            PORT_OPTS="--hp=$PORT"
            echo -e "Hedgehog Port is $PORT"
      else
            echo -e "File $PORT_TXT does not exist."
      fi

      # Append the port to the DAEMON_OPTS variables
      DAEMON_OPTS="-jar /usr/local/bin/groundhog.jar start -t=false -ll=/usr/local/bin/ -hl=/usr/local/bin/ $PORT_OPTS"
      DAEMON_OPTS_TESTNET="-jar /usr/local/bin/groundhog.jar start -t -ll=/usr/local/bin/ -hl=/usr/local/bin/ $PORT_OPTS"
      #echo -e $DAEMON_OPTS
      #echo -e $DAEMON_OPTS_TESTNET
}

case "$1" in
start)
      CHECK_PORT
      #echo $DAEMON_OPTS
      echo -e "Starting groundhog: "
      echo "$(date) - Starting groundhog" >>"${LOGFILE}"
      start-stop-daemon --start --quiet --background --chuid $USER --exec /bin/sh -- -c "$DAEMON_DIR $DAEMON_OPTS"
      echo "Groundhog started."
      ;;
start-testnet)
      CHECK_PORT
      echo -e "Starting daemon: "$NAME
      echo "$(date) - Starting groundhog testnet" >>"${LOGFILE}"
      start-stop-daemon --start --quiet --background --chuid $USER --exec /bin/sh -- -c "$DAEMON_DIR $DAEMON_OPTS_TESTNET"
      echo "Starting testnet"
      ;;
stop)
      echo -e "Stopping groundhog daemon: "
      echo "$(date) - Stopping groundhog" >>"${LOGFILE}"
      pkill -f groundhog || echo "Groundhog not running"
      echo "Groundhog stopped."

      echo -e "Stopping unigridd daemon: "
      echo "$(date) - Starting daemon" >>"${LOGFILE}"
      pkill -f unigridd || echo "Unigridd not running"
      echo "Unigridd stopped."

      echo -e "Stopping hedgehog daemon: "
      echo "$(date) - Starting hedgehog" >>"${LOGFILE}"
      pkill -f hedgehog || echo "Hedgehog not running"
      echo "Hedgehog stopped."
      ;;
restart)
      echo -e "Restarting groundhog, unigridd, and hedgehog daemons: "
      echo "$(date) - Restarting groundhog" >>"${LOGFILE}"
      $0 stop
      $0 start
      ;;
unigrid)
      echo -e "$( ($CLI $2 $3 $4 $5))"
      ;;
check)
      CHECK_IF_RUNNING "$2"
      ;;
status)
      if pgrep -f unigridd >/dev/null 2>&1
      then
            echo "unigridd is running."
      else
            echo "unigridd is not running."
      fi

      if pgrep -f hedgehog >/dev/null 2>&1
      then
            echo "hedgehog is running."
      else
            echo "hedgehog is not running."
      fi

      if pgrep -f groundhog >/dev/null 2>&1
      then
            echo "groundhog is running."
      else
            echo "groundhog is not running."
      fi
      ;;
*)
      echo "Usage: "$1" {start|stop|restart|check|status|unigrid <COMMAND>}"
      exit 1
      ;;
esac

exit 0
