#!/bin/bash
# FiveM Installation Script & Github init
#
# Server Files: /mnt/server
apt update -y
apt install -y tar xz-utils file jq

mkdir -p /mnt/server/resources

cd /mnt/server

echo "updating citizenfx resource files"
git clone https://github.com/citizenfx/cfx-server-data.git /tmp
cp -Rf /tmp/resources/* resources/

RELEASE_PAGE=$(curl -sSL https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/)
CHANGELOGS_PAGE=$(curl -sSL https://changelogs-live.fivem.net/api/changelog/versions/linux/server)



if [ "${ENABLE_GIT}" = "true" ]; then
  echo -e "📦 Git Integration Enabled" 
    if command -v git > /dev/null 2>&1; then
        echo "Git is already installed"
    else 
        echo "Installing Git..."
        apt install -y git
    fi

  git config --global user.name "${GIT_USERNAME}"
  git config --global user.email "${GIT_EMAIL}"

    if [ -n "${GIT_SSH_KEY}" ]; then
        echo "🔐 SSH Key detected. Configuring SSH..."

        mkdir -p ~/.ssh
        echo "${GIT_SSH_KEY}" > ~/.ssh/id_rsa
        chmod 600 ~/.ssh/id_rsa

        echo -e "Host github.com\n\tStrictHostKeyChecking no\n" >> ~/.ssh/config
        export GIT_SSH_COMMAND="ssh -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no"

        git clone "${GIT_REPO_SSH}"
    else
        echo "🌐 No SSH Key provided. Cloning via HTTPS..."
        git clone "${GIT_REPO_HTTPS}"
    fi
fi

if [[ "${ARTIFACTS_VERSION}" == "recommended" ]] || [[ -z ${ARTIFACTS_VERSION} ]]; then
  DOWNLOAD_LINK=$(echo $CHANGELOGS_PAGE | jq -r '.recommended_download')
elif [[ "${ARTIFACTS_VERSION}" == "latest" ]]; then
  DOWNLOAD_LINK=$(echo $CHANGELOGS_PAGE | jq -r '.latest_download')
else
  VERSION_LINK=$(echo -e "${RELEASE_PAGE}" | grep -Eo '".*/*.tar.xz"' | grep -Eo '".*/*.tar.xz"' | sed 's/\"//g'  | sed 's/\.\///1' | grep -i "${ARTIFACTS_VERSION}" | grep -o =.* |  tr -d '=')
  if [[ "${VERSION_LINK}" == "" ]]; then
    echo -e "defaulting to recommedned as the version requested was invalid."
    DOWNLOAD_LINK=$(echo $CHANGELOGS_PAGE | jq -r '.recommended_download')
  else
    DOWNLOAD_LINK=$(echo https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/${VERSION_LINK})
  fi
fi

echo -e "Running curl -sSL ${DOWNLOAD_LINK} -o ${DOWNLOAD_LINK##*/}"

curl -sSL ${DOWNLOAD_LINK} -o ${DOWNLOAD_LINK##*/}

echo "Extracting fivem files"

FILETYPE=$(file -F ',' ${DOWNLOAD_LINK##*/} | cut -d',' -f2 | cut -d' ' -f2)
if [ "$FILETYPE" == "gzip" ]; then
  tar xzvf ${DOWNLOAD_LINK##*/}
elif [ "$FILETYPE" == "Zip" ]; then
  unzip ${DOWNLOAD_LINK##*/}
elif [ "$FILETYPE" == "XZ" ]; then
  tar xvf ${DOWNLOAD_LINK##*/}
else
  echo -e "unknown filetype. Exiting"
  exit 2
fi

rm -rf ${DOWNLOAD_LINK##*/} run.sh

if [ -e server.cfg ]; then
  echo "Skipping downloading default server config file as one already exists"
else
  echo "Downloading default fivem config"
  curl https://raw.githubusercontent.com/ptero-eggs/game-eggs/main/gta/fivem/server.cfg >> server.cfg
fi


echo "Downloading start.sh"
curl https://raw.githubusercontent.com/IsolyaFA/FiveM_EGG/refs/heads/main/start.sh >> start.sh

chmod +x /home/container/start.sh

mkdir -p logs/

echo "Installation terminée à $(date)" >> logs/install.log