#!/bin/bash

[ -n "${DEBUG}" ] && set -e

# Ensure correct permissions for /app directory
if [ ! -w "/app" ]; then
    echo "Warning: Cannot write to /app. Attempting to fix permissions..."
    sudo chown -R $(id -u):$(id -g) /app
fi

# Install or update ComfyUI
cd /app
if [ ! -d "/app/ComfyUI" ]; then
    echo "ComfyUI not found. Installing..."
    chmod +x /scripts/install_comfyui.sh
    bash /scripts/install_comfyui.sh
else
    echo "Adding /app/ComfyUI/* to git safe.directory..."  

    echo "Updating ComfyUI..."
    git config --global --add safe.directory /app/ComfyUI
    cd /app/ComfyUI
    git pull
    echo "Updating ComfyUI-Manager..."
    cd /app/ComfyUI/custom_nodes/ComfyUI-Manager
    git config --global --add safe.directory /app/ComfyUI/custom_nodes/ComfyUI-Manager
    git pull
    cd /app
fi

# TODO: Handle all of the folders being linked into /config

# Download ComfyUI models
if [ "${COMFYUI_DOWNLOAD_STD_MODELS}" = "true" ] || [ "${COMFYUI_DOWNLOAD_STD_MODELSs}" = "1" ]; then
    [ -f /scripts/download_comfyui_models.sh ] && bash /scripts/download_comfyui_models.sh
fi 

if [ "${COMFYUI_DOWNLOAD_VIDEO_MODELS}" = "true" ] || [ "${COMFYUI_DOWNLOAD_VIDEO_MODELS}" = "1" ]; then
    [ -f /scripts/download_comfyui_models_video.sh ] && bash /scripts/download_comfyui_models_video.sh
fi

echo "########################################"
echo "[INFO] Starting ComfyUI..."
echo "########################################"

export PATH="${PATH}:/app/.local/bin"
export PYTHONPYCACHEPREFIX="/app/.cache/pycache"

cd /app

python3 ./ComfyUI/main.py --listen --port 8188 ${CLI_ARGS}
