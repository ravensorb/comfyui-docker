#!/bin/bash

echo "########################################"
echo "[INFO] Downloading ComfyUI Nodes..."
echo "########################################"

[ -n "${DEBUG}" ] && set -euxo pipefail

export APP_PATH_BASE=/app/ComfyUI

update_repo() {
    local repo_url="$1"
    local local_path="$2"

    if [ ! -d "$local_path" ]; then
        echo "Cloning repository..."
        git clone --recurse-submodules "$repo_url" "$local_path"
        git config --global --add safe.directory $local_path
    else
        echo "Updating existing repository..."
        cd "$local_path" || return
        git pull
        cd - || return
    fi

    if [ -f "$local_path/requirements.txt" ]; then
        echo "Installing Python dependencies..."
        pip install $( [ -z "${DEBUG}" ] && echo "-q" ) -r "$local_path/requirements.txt"
    fi
}

process_repo_file() {
    local config_file="$1"

#     envsubst < "$config_file" > /tmp/nodes.tmp

    while IFS=' ' read -r repo_url local_path || [[ -n "$repo_url" ]]; do
        # Skip lines that start with '#'
        [[ "$repo_url" =~ ^#.*$ ]] || [[ -z "$repo_url" ]] && continue
        local_path_expanded=$(echo "$local_path" | envsubst)
        update_repo "$repo_url" "$local_path_expanded"
    done < $config_file
}

# Insall Required Custom Node: ComfyUI Manager
cd ${APP_PATH_BASE}/custom_nodes
git clone --recurse-submodules \
    https://github.com/ltdrdata/ComfyUI-Manager.git \
    || (cd ${APP_PATH_BASE}/custom_nodes/ComfyUI-Manager && git pull)

git config --global --add safe.directory ${APP_PATH_BASE}/custom_nodes/ComfyUI-Manager

# Install additional custom nodes
if [ -f /config/nodes.txt ]; then
    echo "Processing custom nodes file..."
    process_repo_file /config/nodes.txt
else
    echo "Processing default nodes..."
    update_repo https://github.com/marduk191/ComfyUI-Fluxpromptenhancer ${APP_PATH_BASE}/custom_nodes/comfyui-fluxpromptenhancer
    update_repo https://github.com/pythongosssss/ComfyUI-Custom-Scripts ${APP_PATH_BASE}/custom_nodes/comfyui-custom-scripts
fi

# Install additional video custom nodes
if [ -f /config/nodes_video.txt ] && { [ "${COMFYUI_DOWNLOAD_VIDEO_MODELS}" = "true" ] || [ "${COMFYUI_DOWNLOAD_VIDEO_MODELS}" = "1" ]; }; then
    echo "Processing video nodes file..."
    process_repo_file /config/nodes_video.txt
fi