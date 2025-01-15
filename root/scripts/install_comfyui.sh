#!/bin/bash

echo "########################################"
echo "[INFO] Installing/Updating ComfyUI..."
echo "########################################"

[ -n "${DEBUG}" ] && set -euxo pipefail
export APP_PATH_BASE=/app

echo "[INFO] Downloading ComfyUI & Manager..."

# Import utils
. /scripts/utils

# Lets copy the default config files to /config
cp -Rn /defaults/config/* /config

# Update pip
pip install --upgrade $( [ -z "${DEBUG}" ] && echo "-q" ) pip

# Install packages
if [ -f "/scripts/install_packages.sh" ]; then
    chmod +x /scripts/install_packages.sh
    bash /scripts/install_packages.sh || true
fi

# ComfyUI
cd ${APP_PATH_BASE}
if [ ! -d "/app/.git" ] || [ "${COMFYUI_AUTO_UPDATE}" = "true" ]; then
    get_or_update_repo https://github.com/comfyanonymous/ComfyUI.git ${APP_PATH_BASE}/ComfyUI
    get_or_update_repo https://github.com/ltdrdata/ComfyUI-Manager.git ${APP_PATH_BASE}/ComfyUI/custom_nodes/ComfyUI-Manager
fi
