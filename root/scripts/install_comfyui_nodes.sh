#!/bin/bash

echo "########################################"
echo "[INFO] Downloading ComfyUI Nodes..."
echo "########################################"

[ -n "${DEBUG}" ] && set -euxo pipefail

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
        pip install -q -r "$local_path/requirements.txt"
    fi
}

process_repo_file() {
    local config_file="$1"

    while IFS=' ' read -r repo_url local_path || [[ -n "$repo_url" ]]; do
        update_repo "$repo_url" "$local_path"
    done < "$config_file"
}

if [ -f /config/nodes.txt ]; then
    echo "Processing custom nodes file..."
    process_repo_file /config/nodes.txt
else
    echo "Processing default nodes..."
    update_repo https://github.com/marduk191/ComfyUI-Fluxpromptenhancer /app/ComfyUI/custom_nodes/comfyui-fluxpromptenhancer
    update_repo https://github.com/pythongosssss/ComfyUI-Custom-Scripts /app/ComfyUI/custom_nodes/comfyui-custom-scripts
fi

if [ -f /config/nodes_video.txt ] && { [ "${COMFYUI_DOWNLOAD_VIDEO_MODELS}" = "true" ] || [ "${COMFYUI_DOWNLOAD_VIDEO_MODELS}" = "1" ]; }; then
    echo "Processing video nodes file..."
    process_repo_file /config/nodes_video.txt
fi