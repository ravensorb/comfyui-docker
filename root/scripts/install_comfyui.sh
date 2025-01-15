#!/bin/bash

echo "[INFO] Downloading ComfyUI & Manager..."

[ -n "${DEBUG}" ] && set -euxo pipefail

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
cd /app
git clone --recurse-submodules \
    https://github.com/comfyanonymous/ComfyUI.git \
    || (cd /app/ComfyUI && git pull)

echo "Adding /app/ComfyUI/* to git safe.directory..." && \
    git config --global --add safe.directory /app/ComfyUI  

# Install  ComfyUI custom nodes
if [ -f "/scripts/install_comfyui_nodes.sh" ]; then
    chmod +x /scripts/install_comfyui_nodes.sh    
    bash /scripts/install_comfyui_nodes.sh
fi

# Install ComfyUI custom workflows
if [ -f "/scripts/install_comfyui_workflows.sh" ]; then
    chmod +x /scripts/install_comfyui_workflows.sh    
    bash /scripts/install_comfyui_workflows.sh
fi

# Finish
touch /app/.download-complete