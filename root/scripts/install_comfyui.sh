#!/bin/bash

echo "########################################"
echo "[INFO] Downloading ComfyUI & Manager..."
echo "########################################"

[ -n "${DEBUG}" ] && set -euxo pipefail

cp -R /defaults/config/* /config
cp -R /defaults/workflows/* /workflows

pip install --upgrade $( [ -z "${DEBUG}" ] && echo "-q" ) pip

if [ -f "/scripts/install_packages.sh" ]; then
    chmod +x /scripts/install_packages.sh
    bash /scripts/install_packages.sh || true
fi

# ComfyUI
cd /app
git clone --recurse-submodules \
    https://github.com/comfyanonymous/ComfyUI.git \
    || (cd /app/ComfyUI && git pull)

echo "Adding /app/ComfyUI/* to git safe.directory..." && \
    git config --global --add safe.directory /app/ComfyUI  

# ComfyUI Manager
cd /app/ComfyUI/custom_nodes
git clone --recurse-submodules \
    https://github.com/ltdrdata/ComfyUI-Manager.git \
    || (cd /app/ComfyUI/custom_nodes/ComfyUI-Manager && git pull)

git config --global --add safe.directory /app/ComfyUI/custom_nodes/ComfyUI-Manager

if [ -f "/scripts/install_comfyui_nodes.sh" ]; then
    chmod +x /scripts/install_comfyui_nodes.sh    
    bash /scripts/install_comfyui_nodes.sh
fi

if [ -f "/scripts/install_comfyui_workflows.sh" ]; then
    chmod +x /scripts/install_comfyui_workflows.sh    
    bash /scripts/install_comfyui_workflows.sh
fi

# Finish
touch /app/.download-complete