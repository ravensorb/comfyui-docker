#!/bin/bash

echo "########################################"
echo "[INFO] Installing/Updating ComfyUI Custom Nodes..."
echo "########################################"

[ -n "${DEBUG}" ] && set -euxo pipefail

export APP_PATH_BASE=/app/ComfyUI

# Import utils
. /scripts/utils

process_repo_file() {
    local config_file="$1"

#     envsubst < "$config_file" > /tmp/nodes.tmp

    while IFS=' ' read -r repo_url local_path || [[ -n "$repo_url" ]]; do
        # Skip lines that start with '#'
        [[ "$repo_url" =~ ^#.*$ ]] || [[ -z "$repo_url" ]] && continue
        local_path_expanded=$(echo "$local_path" | envsubst)
        get_or_update_repo "$repo_url" "$local_path_expanded"
    done < $config_file
}

# get_or_update_repo https://github.com/ltdrdata/ComfyUI-Manager.git ${APP_PATH_BASE}/custom_nodes/ComfyUI-Manager

# Install additional custom nodes
if [ -f /config/nodes.txt ]; then
    echo "Processing custom nodes file..."
    process_repo_file /config/nodes.txt
else
    echo "Processing default nodes..."
    get_or_update_repo https://github.com/marduk191/ComfyUI-Fluxpromptenhancer ${APP_PATH_BASE}/custom_nodes/comfyui-fluxpromptenhancer
    get_or_update_repo https://github.com/pythongosssss/ComfyUI-Custom-Scripts ${APP_PATH_BASE}/custom_nodes/comfyui-custom-scripts
fi

# Install additional video custom nodes
if [ -f /config/nodes_video.txt ] && { [ "${COMFYUI_DOWNLOAD_VIDEO_MODELS}" = "true" ] || [ "${COMFYUI_DOWNLOAD_VIDEO_MODELS}" = "1" ]; }; then
    echo "Processing video nodes file..."
    process_repo_file /config/nodes_video.txt
fi