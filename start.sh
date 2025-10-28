#!/bin/bash

# Auto-pull Git updates if enabled
if [ "${ENABLE_GIT}" = "true" ]; then
    echo "📦 Git auto-pull enabled"

    # Configuration SSH si clé fournie
    if [ -n "${GIT_SSH_KEY}" ]; then
        echo "🔐 Using SSH key for Git pull"

        mkdir -p ~/.ssh
        echo "${GIT_SSH_KEY}" > ~/.ssh/id_rsa
        chmod 600 ~/.ssh/id_rsa
        echo -e "Host github.com\n\tStrictHostKeyChecking no\n" >> ~/.ssh/config
        export GIT_SSH_COMMAND="ssh -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no"
        git pull origin main
        
    elif [ -n "${GIT_REPO_HTTPS}" ]; then
        echo "🌐 Using HTTPS for Git pull"

        cd resources || exit
        git pull origin main
    else
        echo "⚠️ No Git repo URL provided. Skipping pull."
    fi
fi


$(pwd)/alpine/opt/cfx-server/ld-musl-x86_64.so.1 \
  --library-path "$(pwd)/alpine/usr/lib/v8/:$(pwd)/alpine/lib/:$(pwd)/alpine/usr/lib/" \
  -- $(pwd)/alpine/opt/cfx-server/FXServer \
    +set citizen_dir $(pwd)/alpine/opt/cfx-server/citizen/ \
    +set sv_licenseKey {{FIVEM_LICENSE}} \
    +set steam_webApiKey {{STEAM_WEBAPIKEY}} \
    +set sv_maxplayers {{MAX_PLAYERS}} \
    +set serverProfile default \
    +set txAdminPort {{TXADMIN_PORT}} \
    $( [ "$TXADMIN_ENABLE" == "1" ] || printf %s '+exec server.cfg' )