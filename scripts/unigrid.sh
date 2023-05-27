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
# If not, see <http://www.gnu.org/licenses/> and <https://github.com/unigrid-project/unigrid-installer>.

: '
# Run this file

```
sudo bash -ic "$(wget -4qO- -o- https://raw.githubusercontent.com/unigrid-project/unigrid-docker/main/scripts/unigrid.sh)" ; source ~/.bashrc
```

'

# Github user and project.
INSTALLER_REPO='unigrid-project/unigrid-installer'
DAEMON_REPO='unigrid-project/daemon'
HEDGEHOG_REPO='unigrid-project/hedgehog'
GROUNDHOG_REPO='unigrid-project/groundhog'
# GitHub Auth Token
AUTH_TOKEN=''
USER_NAME=''
# Set username
if [[ -n "$1" ]]
then
USER_NAME="${1}"
else
# Set user to whoever runs the script
USER_NAME=$(( whoami ))
fi

# Display Name.
DAEMON_NAME='UNIGRID'
# Coin Ticker.
TICKER='UGD'
# Binary base name.
BIN_BASE='unigrid'
# Java Download
JAVA_URL_LINK='https://download.oracle.com/java/17/latest/jdk-17_linux-x64_bin.deb'
# Directory.
DIRECTORY='.unigrid'
# Conf File.
CONF='unigrid.conf'
# Port.
DEFAULT_PORT=51992
# Explorer URL.
EXPLORER_URL='http://explorer.unigrid.org/'
# Rate limit explorer.
EXPLORER_SLEEP=1
# Amount of Collateral needed.
COLLATERAL=3000
# Blocktime in seconds.
BLOCKTIME=60
# Multiple on single IP.
MULTI_IP_MODE=0
# Home directory
USR_HOME="/home/${USER_NAME}"
# build testnet?
if [[ "$2" = "testnet" ]]
then
TESTNET="${2}"
else
TESTNET=""
fi

ASCII_ART () {
echo -e "\e[0m"
clear 2> /dev/null
cat << "UNIGRID"
 _   _ _   _ ___ ____ ____  ___ ____
| | | | \ | |_ _/ ___|  _ \|_ _|  _ \
| | | |  \| || | |  _| |_) || || | | |
| |_| | |\  || | |_| |  _ < | || |_| |
 \___/|_| \_|___\____|_| \_\___|____/

Copyright © 2021-2023 The Unigrid Foundation, UGD Software AB 

UNIGRID
}

cd ~/ || exit
COUNTER=0

while [[ ! -f ~/__ugd.sh ]] || [[ $( grep -Fxc "# End of setup script." ~/__ugd.sh ) -eq 0 ]]
do
  echo "Downloading Unigrid Setup Script."
  COUNTER=1
  if [[ "${COUNTER}" -gt 3 ]]
  then
    echo
    echo "Copy of setup script failed."
    echo
    exit 1
  fi
done

(
# shellcheck disable=SC1091
# shellcheck source=/root/___ugd.sh
. ~/__ugd.sh
UNIGRID_SETUP_THREAD
)
# shellcheck source=/root/.bashrc
. ~/.bashrc
#stty sane 2>/dev/null
exit

