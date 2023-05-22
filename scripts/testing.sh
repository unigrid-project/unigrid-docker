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

DAEMON_REPO='unigrid-project/daemon'
HEDGEHOG_REPO='unigrid-project/hedgehog'
GROUNDHOG_REPO='unigrid-project/groundhog'

GROUNDHOG_DOWNLOAD_SUPER() {
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

    LATEST=$(curl -H "Accept: application/vnd.github+json" -sL "https://api.github.com/repos/unigrid-project/${REPO}/releases/${RELEASE_TAG}")
    VERSION_REMOTE=$(echo "${LATEST}" | jq -r '.tag_name' | sed 's/[^0-9.]*\([0-9.]*\).*/\1/')
    echo "Remote version: ${VERSION_REMOTE}"
    GROUNDHOG_BIN="groundhog-${VERSION_REMOTE}-SNAPSHOT-jar-with-dependencies.jar"

    if [[ -s "/var/unigrid/${PROJECT_DIR}/src/${GROUNDHOG_BIN}" ]]; then
        VERSION_LOCAL=$(timeout --signal=SIGKILL 9s "/var/unigrid/${PROJECT_DIR}/src/${GROUNDHOG_BIN}" --help 2>/dev/null | head -n 1 | sed 's/[^0-9.]*\([0-9.]*\).*/\1/')
        echo "Local version: ${VERSION_LOCAL}"
        if [[ $(echo "${VERSION_LOCAL}" | grep -c "${VERSION_REMOTE}") -eq 1 ]] && [[ "${2}" != 'force' ]]; then
            return 1 2>/dev/null
        fi
    fi

    ALL_DOWNLOADS=$(echo "${LATEST}" | jq -r '.assets[].browser_download_url')
    DOWNLOADS=$(echo "${ALL_DOWNLOADS}" | grep -v '.exe$' | grep -v '.sh$' | grep -v '.pdf$' | grep -v '.sig$' | grep -v '.asc$')

    LINES=$(echo "${DOWNLOADS}" | sed '/^[[:space:]]*$/d' | wc -l)
    if [[ "${LINES}" -eq 1 ]]; then
        GROUNDHOG_DOWNLOAD_URL="${DOWNLOADS}"
    fi

    if [[ ! -z "${GROUNDHOG_DOWNLOAD_URL}" ]]; then
        mkdir -p /var/unigrid/"${PROJECT_DIR}"/src/
        JAR_DOWNLOAD_EXTRACT "${PROJECT_DIR}" "${GROUNDHOG_BIN}" "${GROUNDHOG_DOWNLOAD_URL}"
    fi

    if [[ -z "${GROUNDHOG_DOWNLOAD_URL}" ]] || [[ ! -f "/var/unigrid/${PROJECT_DIR}/src/${GROUNDHOG_BIN}" ]]; then
        rm -rf /var/unigrid/"${PROJECT_DIR}"/src/
    fi
}

HEDGEHOG_DOWNLOAD_SUPER() {
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

    LATEST=$(curl -H "Accept: application/vnd.github+json" -sL "https://api.github.com/repos/unigrid-project/${REPO}/releases/${RELEASE_TAG}")
    VERSION_REMOTE=$(echo "${LATEST}" | jq -r '.tag_name' | sed 's/[^0-9.]*\([0-9.]*\).*/\1/')
    echo "Remote version: ${VERSION_REMOTE}"
    echo "Filename: ${FILENAME}"
    # hedgehog-0.0.3-x86_64-linux-gnu.bin
    HEDGEHOG_BIN="hedgehog-${VERSION_REMOTE}-x86_64-linux-gnu.bin"
    echo "Hedgehog Bin: ${HEDGEHOG_BIN}"

    if [[ -s "/var/unigrid/${PROJECT_DIR}/src/${HEDGEHOG_BIN}" ]]; then
        VERSION_LOCAL=$(timeout --signal=SIGKILL 9s "/var/unigrid/${PROJECT_DIR}/src/${HEDGEHOG_BIN}" --help 2>/dev/null | head -n 1 | sed 's/[^0-9.]*\([0-9.]*\).*/\1/')
        echo "Local version: ${VERSION_LOCAL}"
        if [[ $(echo "${VERSION_LOCAL}" | grep -c "${VERSION_REMOTE}") -eq 1 ]] && [[ "${2}" != 'force' ]]; then
            return 1 2>/dev/null
        fi
    fi

    ALL_DOWNLOADS=$(echo "${LATEST}" | jq -r '.assets[].browser_download_url')
    DOWNLOADS=$(echo "${ALL_DOWNLOADS}" | grep -E 'hedgehog-[0-9.]+-x86_64-linux-gnu.bin$')
    echo "All Downloads: ${ALL_DOWNLOADS}"
    LINES=$(echo "${DOWNLOADS}" | sed '/^[[:space:]]*$/d' | wc -l)
    if [[ "${LINES}" -eq 1 ]]; then
        HEDGEHOG_DOWNLOAD_URL="${DOWNLOADS}"
    fi
    echo "HEDGEHOG_DOWNLOAD_URL: ${HEDGEHOG_DOWNLOAD_URL}"
    if [[ ! -z "${HEDGEHOG_DOWNLOAD_URL}" ]]; then
        mkdir -p "/var/unigrid/${PROJECT_DIR}/src/"
        JAR_DOWNLOAD_EXTRACT "${PROJECT_DIR}" "${HEDGEHOG_BIN}" "${HEDGEHOG_DOWNLOAD_URL}"
    fi

    if [[ -z "${HEDGEHOG_DOWNLOAD_URL}" ]] || [[ ! -f "/var/unigrid/${PROJECT_DIR}/src/${HEDGEHOG_BIN}" ]]; then
        rm -rf "/var/unigrid/${PROJECT_DIR}/src/"
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

    sudo cp -R "/var/unigrid/${DAEMON_DIR}/src/${DAEMON_BIN}" /usr/local/bin
    sudo chmod +x "/usr/local/bin/${DAEMON_BIN}"
    sudo chown "${USER_NAME_CURRENT}:${USER_NAME_CURRENT}" "/usr/local/bin/${DAEMON_BIN}"

    sudo cp -R "/var/unigrid/${DAEMON_DIR}/src/${CONTROLLER_BIN}" /usr/local/bin/
    sudo chown "${USER_NAME_CURRENT}:${USER_NAME_CURRENT}" "/usr/local/bin/${CONTROLLER_BIN}"
    sudo chmod +x "/usr/local/bin/${CONTROLLER_BIN}"

    sudo cp -R "/var/unigrid/${GROUNDHOG_DIR}/src/${GROUNDHOG_BIN}" "/usr/local/bin/groundhog.jar"
    sudo chown "${USER_NAME_CURRENT}:${USER_NAME_CURRENT}" "/usr/local/bin/groundhog.jar"
    sudo chmod +x "/usr/local/bin/groundhog.jar"

    sudo cp -R "/var/unigrid/${HEDGEHOG_DIR}/src/${HEDGEHOG_BIN}" "/usr/local/bin/hedgehog.bin"
    sudo chown "${USER_NAME_CURRENT}:${USER_NAME_CURRENT}" "/usr/local/bin/hedgehog.bin"
    sudo chmod +x "/usr/local/bin/hedgehog.bin"

    echo "bins moved to /usr/local/bin/"
}

USER_NAME_CURRENT=$(whoami)
DOWNLOAD_SUPER "${HEDGEHOG_REPO}"
DAEMON_DOWNLOAD_SUPER "${DAEMON_REPO}"
DOWNLOAD_SUPER "${GROUNDHOG_REPO}"
MOVE_FILES_SETOWNER
