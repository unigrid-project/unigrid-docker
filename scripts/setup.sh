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

stty sane 2>/dev/null

# Chars for spinner.
SP="/-\\|"
DAEMON_BIN=''
CONTROLLER_BIN=''
GROUNDHOG_BIN=''
HEDGEHOG_BIN=''

if [[ "${DAEMON_NAME}" ]]; then
  echo "passed daemon name " ${DAEMON_NAME}
fi
ASCII_ART

if [[ "${ASCII_ART}" ]]; then
  ${ASCII_ART}
fi

CHECK_SYSTEM() {
  # Only run if user has sudo.
  sudo true >/dev/null 2>&1
  USER_NAME_CURRENT=$(whoami)
  CAN_SUDO=0
  CAN_SUDO=$(timeout --foreground --signal=SIGKILL 1s bash -c "sudo -l 2>/dev/null | grep -v '${USER_NAME_CURRENT}' | wc -l ")
  if [[ ${CAN_SUDO} =~ ${RE} ]] && [[ "${CAN_SUDO}" -gt 2 ]]; then
    :
  else
    echo "Script must be run as a user with no password sudo privileges"
    echo "To switch to the root user type"
    echo
    echo "sudo su"
    echo
    echo "And then re-run this command."
    return 1 2>/dev/null || exit 1
  fi

  # Make sure sudo will work
  if [[ $(sudo false 2>&1) ]]; then
    echo "$(hostname -I | awk '{print $1}') $(hostname)" >>/etc/hosts
  fi
  if [ ! -x "$(command -v jq)" ] ||
    [ ! -x "$(command -v curl)" ] ||
    [ ! -x "$(command -v gzip)" ] ||
    [ ! -x "$(command -v tar)" ] ||
    [ ! -x "$(command -v java)" ] ||
    [ ! -x "$(command -v unzip)" ]; then
    WAIT_FOR_APT_GET
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -yq \
      curl \
      gzip \
      unzip \
      xz-utils \
      jq \
      bc \
      html-xml-utils \
      openjdk-17-jre-headless
  fi
  # Check for systemd
  #systemctl --version >/dev/null 2>&1 || { cat /etc/*-release; echo; echo "systemd is required. Are you using a Debian based distro?" >&2; return 1 2>/dev/null || exit 1; }

}

WAIT_FOR_APT_GET() {
  ONCE=0
  while [[ $(sudo lslocks -n -o COMMAND,PID,PATH | grep -c 'apt-get\|dpkg\|unattended-upgrades') -ne 0 ]]; do
    if [[ "${ONCE}" -eq 0 ]]; then
      while read -r LOCKINFO; do
        PID=$(echo "${LOCKINFO}" | awk '{print $2}')
        ps -up "${PID}"
        echo "${LOCKINFO}"
      done <<<"$(sudo lslocks -n -o COMMAND,PID,PATH | grep 'apt-get\|dpkg\|unattended-upgrades')"
      ONCE=1
      if [[ ${ARG6} == 'y' ]]; then
        echo "Waiting for apt-get to finish"
      fi
    fi
    if [[ ${ARG6} == 'y' ]]; then
      printf "."
    else
      echo -e "\\r${SP:i++%${#SP}:1} Waiting for apt-get to finish... \\c"
    fi
    sleep 0.3
  done
  echo
  echo -e "\\r\\c"
  stty sane 2>/dev/null
}

DAEMON_DOWNLOAD_EXTRACT() {
  PROJECT_DIR=${1}
  DAEMON_BIN=${2}
  CONTROLLER_BIN=${3}
  DAEMON_DOWNLOAD_URL=${4}

  echo "DAEMON_DOWNLOAD_EXTRACT"
  echo "PROJECT_DIR: ${PROJECT_DIR}"
  echo "DAEMON_BIN: ${DAEMON_BIN}"
  echo "CONTROLLER_BIN: ${CONTROLLER_BIN}"
  echo "DAEMON_DOWNLOAD_URL: ${DAEMON_DOWNLOAD_URL}"

  # Create the directory if it does not exist
  mkdir -p /var/unigrid/latest-github-release
  mkdir -p /var/unigrid/"${PROJECT_DIR}"/src

  BIN_FILENAME=$(basename "${DAEMON_DOWNLOAD_URL}")
  echo "URL: ${DAEMON_DOWNLOAD_URL}"
  wget -4 "${DAEMON_DOWNLOAD_URL}" -O /var/unigrid/latest-github-release/"${BIN_FILENAME}" -q --show-progress --progress=bar:force 2>&1
  sleep 0.6
  echo

  if [[ $(echo "${BIN_FILENAME}" | grep -c '.tar.gz$') -eq 1 ]] || [[ $(echo "${BIN_FILENAME}" | grep -c '.tgz$') -eq 1 ]]; then
    tar -xzf /var/unigrid/latest-github-release/"${BIN_FILENAME}" -C /var/unigrid/"${PROJECT_DIR}"/src
  else
    mv /var/unigrid/latest-github-release/"${BIN_FILENAME}" /var/unigrid/"${PROJECT_DIR}"/src/
  fi

  echo "Contents of /var/unigrid/${PROJECT_DIR}/src:"
  ls -l /var/unigrid/"${PROJECT_DIR}"/src

  find /var/unigrid/"${PROJECT_DIR}"/src/ -name "$DAEMON_BIN" -size +128k -exec cp {} /var/unigrid/"${PROJECT_DIR}"/src/ \; 2>/dev/null
  find /var/unigrid/"${PROJECT_DIR}"/src/ -name "$CONTROLLER_BIN" -size +128k -exec cp {} /var/unigrid/"${PROJECT_DIR}"/src/ \; 2>/dev/null

  if [[ -s "/var/unigrid/${PROJECT_DIR}/src/${DAEMON_BIN}" ]]; then
    chmod +x "/var/unigrid/${PROJECT_DIR}/src/${DAEMON_BIN}" 2>/dev/null
  fi
  if [[ -s "/var/unigrid/${PROJECT_DIR}/src/${CONTROLLER_BIN}" ]]; then
    chmod +x "/var/unigrid/${PROJECT_DIR}/src/${CONTROLLER_BIN}" 2>/dev/null
  fi
}

JAR_DOWNLOAD_EXTRACT() {
  PROJECT_DIR=${1}
  JAR_BIN=${2}
  JAR_DOWNLOAD_URL=${3}
  echo "JAR_DOWNLOAD_EXTRACT"
  echo "PROJECT_DIR ${PROJECT_DIR}"
  echo "JAR_BIN ${JAR_BIN}"
  echo "JAR_DOWNLOAD_URL ${JAR_DOWNLOAD_URL}"
  FOUND_JAR=0
  while read -r GITHUB_URL_JAR; do
    if [[ -z "${GITHUB_URL_JAR}" ]]; then
      continue
    fi
    BIN_FILENAME=$(basename "${GITHUB_URL_JAR}" | tr -d '\r')
    echo "URL: ${GITHUB_URL_JAR}"
    stty sane 2>/dev/null
    mkdir -p "/var/unigrid/latest-github-release"
    wget -4 "${GITHUB_URL_JAR}" -O "/var/unigrid/latest-github-release/${BIN_FILENAME}" -q --show-progress --progress=bar:force 2>&1
    sleep 0.6
    echo
    mkdir -p "/var/unigrid/${PROJECT_DIR}/src"
    echo "Copying over ${BIN_FILENAME}."
    mv "/var/unigrid/latest-github-release/${BIN_FILENAME}" "/var/unigrid/${PROJECT_DIR}/src/"

    cd ~/ || return 1 2>/dev/null
    find "/var/unigrid/${PROJECT_DIR}/src/" -name "$JAR_BIN" -size +128k 2>/dev/null
    find "/var/unigrid/${PROJECT_DIR}/src/" -name "$JAR_BIN" -size +128k -exec cp {} "/var/unigrid/${PROJECT_DIR}/src/" \; 2>/dev/null

    if [[ -s "/var/unigrid/${PROJECT_DIR}/src/${JAR_BIN}" ]]; then
      echo "Setting executable bit for daemon ${JAR_BIN}"
      echo "/var/unigrid/${PROJECT_DIR}/src/${JAR_BIN}"
      echo "Good"
      FOUND_JAR=1
    fi

    # Break out of loop if we got what we needed.
    if [[ "${FOUND_JAR}" -eq 1 ]]; then
      break
    fi
  done <<<"${JAR_DOWNLOAD_URL}"
}

DAEMON_DOWNLOAD_SUPER() {
  REPO=${1}
  FILENAME=$(echo "${REPO}" | tr '/' '_')
  echo "Checking ${REPO} for the latest version"
  LATEST=$(curl -s https://api.github.com/repos/${REPO}/releases/latest)
  VERSION_REMOTE=$(echo "${LATEST}" | jq -r '.tag_name' | sed 's/[^0-9.]*\([0-9.]*\).*/\1/')
  echo "Remote version: ${VERSION_REMOTE}"
  PROJECT_DIR="${FILENAME}"
  ech "Filename: ${FILENAME}"
  DAEMON_DOWNLOAD_URL=$(echo "${LATEST}" | jq -r '.assets[] | select(.name | test("unigrid-.*-x86_64-linux-gnu.tar.gz")) | .browser_download_url')

  if [[ -z "${DAEMON_DOWNLOAD_URL}" ]]; then
    echo "Could not find linux wallet from https://api.github.com/repos/${REPO}/releases/latest"
    echo "${DOWNLOADS}"
    echo
  else
    echo "Downloading latest release from github."
    echo "Download url: ${DAEMON_DOWNLOAD_URL}"
    DAEMON_DOWNLOAD_EXTRACT "${PROJECT_DIR}" "unigridd" "unigrid-cli" "${DAEMON_DOWNLOAD_URL}"
  fi
}

DOWNLOAD_SUPER() {
  REPO=${1}
  FILENAME=$(echo "${REPO}" | tr '/' '_')
  RELEASE_TAG='latest'

  if [[ ! -z "${2}" ]] && [[ "${2}" != 'force' ]] && [[ "${2}" != 'force_skip_download' ]]; then
    rm "/var/unigrid/latest-github-release/${FILENAME}.json"
    RELEASE_TAG=${2}
  fi

  if [[ -z "${REPO}" ]]; then
    return 1 2>/dev/null
  fi

  echo "Checking ${REPO} for the latest version"
  PROJECT_DIR="${FILENAME}"

  LATEST=$(curl -H "Accept: application/vnd.github+json" -sL "https://api.github.com/repos/${REPO}/releases/${RELEASE_TAG}")
  VERSION_REMOTE=$(echo "${LATEST}" | jq -r '.tag_name' | sed 's/[^0-9.]*\([0-9.]*\).*/\1/')
  echo "Remote version: ${VERSION_REMOTE}"
  echo "Filename: ${FILENAME}"

  if [[ $REPO == "unigrid-project/groundhog" ]]; then
    BIN_SUFFIX='-SNAPSHOT-jar-with-dependencies.jar'
  elif [[ $REPO == "unigrid-project/hedgehog" ]]; then
    BIN_SUFFIX='-x86_64-linux-gnu.bin'
  else
    BIN_SUFFIX=''
  fi

  BIN_FILENAME=$(echo "${LATEST}" | jq -r --arg suffix "$BIN_SUFFIX" '.assets[] | select(.name | endswith($suffix)) | .name')
  if [[ -z "${BIN_FILENAME}" ]]; then
    echo "Could not find the appropriate binary filename for ${REPO}"
    return 1 2>/dev/null
  fi

  if [[ $REPO == "unigrid-project/groundhog" ]]; then
    GROUNDHOG_BIN="${BIN_FILENAME}"
  elif [[ $REPO == "unigrid-project/hedgehog" ]]; then
    HEDGEHOG_BIN="${BIN_FILENAME}"
  fi

  BIN_NAME="${BIN_FILENAME%.*}"
  BIN_EXTENSION="${BIN_FILENAME##*.}"
  BIN_URL=$(echo "${LATEST}" | jq -r --arg filename "$BIN_FILENAME" '.assets[] | select(.name == $filename) | .browser_download_url')

  if [[ -s "/var/unigrid/${PROJECT_DIR}/src/${BIN_FILENAME}" ]]; then
    VERSION_LOCAL=$(timeout --signal=SIGKILL 9s "/var/unigrid/${PROJECT_DIR}/src/${BIN_FILENAME}" --help 2>/dev/null | head -n 1 | sed 's/[^0-9.]*\([0-9.]*\).*/\1/')
    echo "Local version: ${VERSION_LOCAL}"
    if [[ $(echo "${VERSION_LOCAL}" | grep -c "${VERSION_REMOTE}") -eq 1 ]] && [[ "${2}" != 'force' ]]; then
      return 1 2>/dev/null
    fi
  fi

  ALL_DOWNLOADS=$(echo "${LATEST}" | jq -r '.assets[].browser_download_url')
  DOWNLOADS=$(echo "${ALL_DOWNLOADS}" | grep -E "${BIN_NAME}.*${BIN_EXTENSION}$")
  echo "All Downloads: ${ALL_DOWNLOADS}"
  LINES=$(echo "${DOWNLOADS}" | sed '/^[[:space:]]*$/d' | wc -l)
  if [[ "${LINES}" -eq 1 ]]; then
    DOWNLOAD_URL="${DOWNLOADS}"
  fi
  echo "DOWNLOAD_URL: ${DOWNLOAD_URL}"

  if [[ ! -z "${DOWNLOAD_URL}" ]]; then
    mkdir -p "/var/unigrid/${PROJECT_DIR}/src/"
    JAR_DOWNLOAD_EXTRACT "${PROJECT_DIR}" "${BIN_FILENAME}" "${DOWNLOAD_URL}"
  fi

  if [[ -z "${DOWNLOAD_URL}" ]] || [[ ! -f "/var/unigrid/${PROJECT_DIR}/src/${BIN_FILENAME}" ]]; then
    rm -rf "/var/unigrid/${PROJECT_DIR}/src/"
  fi
}

UPDATE_USER_FILE() {
  STRING=${1}
  FUNCTION_NAME=${2}
  FILENAME=${3/#\~/$HOME}

  # Replace ${FUNCTION_NAME} function if it exists.
  FUNC_START=$(grep -Fxn "# Start of function for ${FUNCTION_NAME}." "${FILENAME}" | sed 's/:/ /g' | awk '{print $1 }' | sort -r)
  FUNC_END=$(grep -Fxn "# End of function for ${FUNCTION_NAME}." "${FILENAME}" | sed 's/:/ /g' | awk '{print $1 }' | sort -r)
  if [ ! -z "${FUNC_START}" ] && [ ! -z "${FUNC_END}" ]; then
    paste <(echo "${FUNC_START}") <(echo "${FUNC_END}") -d ' ' | while read -r START END; do
      sed -i "${START},${END}d" "${FILENAME}"
    done
  fi
  # Remove empty lines at end of file.
  sed -i -r '${/^[[:space:]]*$/d;}' "${FILENAME}"
  echo "" >>"${FILENAME}"
  # Add in ${FUNCTION_NAME} function.
  {
    echo "${STRING}"
    echo ""
  } >>"${FILENAME}"

  # Remove double empty lines in the file.
  sed -i '/^$/N;/^\n$/D' "${FILENAME}"
}

USER_FUNCTION_FOR_CLI() {
  # Create function that can control the new gridnode daemon.
  _CLI_FUNC=$(
    cat <<DAEMON_FUNC_CLI
# Start of function for ${USER_NAME}.
function ${USER_NAME}() {
  unigrid-cli \${1} \${2} \${3} \${4} \${5}
}
# End of function for ${USER_NAME}.
DAEMON_FUNC_CLI
  )
  UPDATE_USER_FILE "${_CLI_FUNC}" "${USER_NAME}" "${1}/.bashrc"

  # create a function in the current user .bashrc
  USER_NAME_CURRENT=$(whoami)
  CLI_LOC="/home/${USER_NAME}/.local/bin/unigrid-cli"
  _CLI_FUNC2=$(
    cat <<FUNC_CLI
# Start of function for ${USER_NAME}2.
function ${USER_NAME}2() {
  if [[ "$(whoami)" == "${USER_NAME}" ]]
    then
     ${CLI_LOC} \${1} \${2} \${3} \${4} \${5}
    else
      sudo su "${USER_NAME}" -c ${CLI_LOC} \${1} \${2} \${3} \${4} \${5}
  fi
}
# End of function for ${USER_NAME}2.
FUNC_CLI
  )
  UPDATE_USER_FILE "${_CLI_FUNC2}" "${USER_NAME}2" "/home/${USER_NAME_CURRENT}/.bashrc"
}

MOVE_FILES_SETOWNER() {
  sudo true >/dev/null 2>&1
  if ! sudo useradd -m "${USER_NAME}" -s /bin/bash 2>/dev/null; then
    if ! sudo useradd -g "${USER_NAME}" -m "${USER_NAME}" -s /bin/bash 2>/dev/null; then
      echo
      echo "User ${USER_NAME} exists. Skipping."
      echo
    fi
  fi
  # Make a unigrid directory if it doesn't exist
  mkdir -p /home/"${USER_NAME_CURRENT}"/.local/unigrid

  DAEMON_DIR="${DAEMON_REPO/\//_}"
  echo "DAEMON_DIR: ${DAEMON_DIR}"
  GROUNDHOG_DIR="${GROUNDHOG_REPO/\//_}"
  HEDGEHOG_DIR="${HEDGEHOG_REPO/\//_}"
  echo "moving bins to /usr/local/bin"
  echo "ALL DIRS"
  echo "$(ls -l /var/unigrid/)"
  echo "GROUNDHOG_DIR"
  echo "$(ls -l /var/unigrid/${GROUNDHOG_DIR}/src/)"
  echo "HEDGEHOG_DIR"
  echo "$(ls -l /var/unigrid/${HEDGEHOG_DIR}/src/)"
  sudo mkdir -p "/usr/local/bin"

  sudo cp "/var/unigrid/${DAEMON_DIR}/src/${DAEMON_BIN}" /usr/local/bin
  sudo chmod +x "/usr/local/bin/${DAEMON_BIN}"
  sudo chown "${USER_NAME_CURRENT}:${USER_NAME_CURRENT}" "/usr/local/bin/${DAEMON_BIN}"

  sudo cp "/var/unigrid/${DAEMON_DIR}/src/${CONTROLLER_BIN}" /usr/local/bin/
  sudo chown "${USER_NAME_CURRENT}:${USER_NAME_CURRENT}" "/usr/local/bin/${CONTROLLER_BIN}"
  sudo chmod +x "/usr/local/bin/${CONTROLLER_BIN}"

  echo "GROUNDHOG_BIN: ${GROUNDHOG_BIN}"
  sudo cp "/var/unigrid/${GROUNDHOG_DIR}/src/${GROUNDHOG_BIN}" "/usr/local/bin/groundhog.jar"
  sudo chown "${USER_NAME_CURRENT}:${USER_NAME_CURRENT}" "/usr/local/bin/groundhog.jar"
  sudo chmod +x "/usr/local/bin/groundhog.jar"

  echo "HEDGEHOG_BIN: ${HEDGEHOG_BIN}"
  sudo cp "/var/unigrid/${HEDGEHOG_DIR}/src/${HEDGEHOG_BIN}" "/usr/local/bin/hedgehog.bin"
  sudo chown "${USER_NAME_CURRENT}:${USER_NAME_CURRENT}" "/usr/local/bin/hedgehog.bin"
  sudo chmod +x "/usr/local/bin/hedgehog.bin"

  echo "bins moved to /usr/local/bin/"
}

INSTALL_JAVA() {
  JAVA_URL=${1}
  JAVA_FILENAME=$(basename "${JAVA_URL}" | tr -d '\r')
  stty sane 2>/dev/null
  wget -4 "${JAVA_URL}" -O /var/unigrid/latest-github-releasese/"${JAVA_FILENAME}" -q --show-progress --progress=bar:force 2>&1
  echo "Downloaded ${JAVA_FILENAME}"
  if [[ $(echo "${JAVA_FILENAME}" | grep -c '.deb$') -eq 1 ]]; then
    WAIT_FOR_APT_GET
    echo "Installing java"
    sudo -n dpkg -i /var/unigrid/latest-github-releasese/"${JAVA_FILENAME}"
    echo "Extracting Java deb package."
    echo "$(java -version) "
  fi
}

SETUP_SYSTEMCTL() {
  # Setup systemd to start unigrid on restart.
  TIMEOUT='1min'
  STARTLIMITINTERVAL='200s'
  RESTART_TIME='30s'

  OOM_SCORE_ADJUST=$(sudo cat /etc/passwd | wc -l)
  CPU_SHARES=$((1024 - OOM_SCORE_ADJUST))
  STARTUP_CPU_SHARES=$((768 - OOM_SCORE_ADJUST))
  echo "Creating systemd service for ${DAEMON_NAME}"

  GN_TEXT="Creating systemd shutdown service."
  GN_TEXT1="Shutdown service for unigrid"

  # TODO shange USER_NAME to DIR_NAME
  cat <<SYSTEMD_CONF | sudo tee /etc/systemd/system/"${USER_NAME}".service >/dev/null
[Unit]
Description=${DAEMON_NAME} for user ${USER_NAME}
After=network.target

[Service]
Type=simple
User=${USER_NAME}
WorkingDirectory=${USR_HOME}
#PIDFile=${USR_HOME}/${DIRECTORY}/${DAEMON_BIN}.pid
ExecStart=java -jar ${USR_HOME}/.local/bin/groundhog.jar start -t=false -l=${USR_HOME}/.local/bin/
ExecStartPost=/bin/sleep 1
ExecStop=/bin/kill -15 $MAINPID
Restart=always
RestartSec=${RESTART_TIME}
TimeoutStartSec=${TIMEOUT}
TimeoutStopSec=infinity
TimeoutStopSec=${TIMEOUT}
StartLimitInterval=${STARTLIMITINTERVAL}
StartLimitBurst=5
OOMScoreAdjust=${OOM_SCORE_ADJUST}
CPUShares=${CPU_SHARES}
StartupCPUShares=${STARTUP_CPU_SHARES}

[Install]
WantedBy=multi-user.target
SYSTEMD_CONF

  sudo systemctl daemon-reload
  sudo systemctl enable "${USER_NAME}".service --now

  # Use systemctl if it exists.
  SYSTEMD_FULLFILE=$(grep -lrE "ExecStart=${FILENAME}.*start" /etc/systemd/system/ | head -n 1)
  if [[ -n "${SYSTEMD_FULLFILE}" ]]; then
    SYSTEMD_FILE=$(basename "${SYSTEMD_FULLFILE}")
  fi
  if [[ -n "${SYSTEMD_FILE}" ]]; then
    systemctl start "${SYSTEMD_FILE}"
  fi
  stty sane 2>/dev/null
  echo "groundhog started"

  ASCII_ART

  if [[ "${ASCII_ART}" ]]; then
    ${ASCII_ART}
  fi
}

CREATE_CRONTAB_JOB() {
  if [[ -n "${TESTNET}" ]]; then
    START_CMD="@reboot /usr/local/bin/ugd_service start-${TESTNET}"
    CHK_CMD="* * * * * /usr/local/bin/ugd_service check ${TESTNET}"
  else
    START_CMD="@reboot /bin/sh -c \"/usr/local/bin/ugd_service start 2>&1 | tee -a ~/.unigrid/ugd_service.log\""
    CHK_CMD="* * * * * /usr/local/bin/ugd_service check"
  fi
  echo "write out current crontab"
  touch /var/spool/cron/root
  /usr/bin/crontab /var/spool/cron/root
  touch rebootcron
  crontab rebootcron
  crontab -l >rebootcron
  echo "new cron into cron file"
  echo "${START_CMD}" >>rebootcron
  # check every minute groundhog is still running
  echo "${CHK_CMD}" >>rebootcron
  echo ""
  echo "install new cron file"
  crontab rebootcron
  rm rebootcron
}

UNIGRID_SETUP_THREAD() {
  CHECK_SYSTEM
  if [ $? == "1" ]; then
    return 1 2>/dev/null || exit 1
  fi

  DOWNLOAD_SUPER "${HEDGEHOG_REPO}"
  DAEMON_DOWNLOAD_SUPER "${DAEMON_REPO}"
  DOWNLOAD_SUPER "${GROUNDHOG_REPO}"
  MOVE_FILES_SETOWNER
  #CREATE_CRONTAB_JOB
  stty sane 2>/dev/null
  ASCII_ART

  if [[ "${ASCII_ART}" ]]; then
    ${ASCII_ART}
  fi
  exit
  echo "Install Complete"
  # use apt-get
  #INSTALL_JAVA "${JAVA_URL_LINK}"
  #SETUP_SYSTEMCTL
}

#stty sane 2>/dev/null
echo
sleep 0.1
# End of setup script.
