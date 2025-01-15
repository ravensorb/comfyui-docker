#!/bin/bash

[ -n "${DEBUG}" ] && set -e

export APP_PATH_BASE=/app/ComfyUI

# Ensure correct permissions for /app directory
if [ ! -w "/app" ]; then
    echo "Warning: Cannot write to /app. Attempting to fix permissions..."
    sudo chown -R $(id -u):$(id -g) /app
fi

mkdir -p /data/output /data/input /data/user /data/temp /data/models /data/custom_nodes
sudo chown -R $(id -u):$(id -g) /data
chmod +x /scripts/*.sh

# Install or update ComfyUI
bash /scripts/install_comfyui.sh

# Download ComfyUI models
bash /scripts/download_comfyui_models.sh

# Install  ComfyUI custom nodes
bash /scripts/download_comfyui_nodes.sh

# Install ComfyUI custom workflows
bash /scripts/install_comfyui_workflows.sh

echo "########################################"
echo "[INFO] Starting ComfyUI..."
echo "########################################"

export PATH="${PATH}:/app/.local/bin"
export PYTHONPYCACHEPREFIX="/app/.cache/pycache"

cd /app

app_args=(
    --listen
    --port 8188
    --output-directory /data/output
    --input-directory /data/input
    --user-directory /data/user
    --temp-directory /data
)

if [ -f "/app/extra_models_path.yaml" ]; then
    app_args+=("--extra-model-paths-config /app/extra_models_path.yaml")
elif [ -f "/config/extra_models_path.yaml" ]; then
    app_args+=("--extra-model-paths-config /config/extra_models_path.yaml")
fi

if [ -n "${CLI_ARGS}" ]; then
    # Split CLI_ARGS into an array
    IFS=' ' read -r -a cli_args_array <<< "$CLI_ARGS"
    
    # Add each argument from cli_args_array to app_args if not already present
    for arg in "${cli_args_array[@]}"; do
        if [[ ! " ${app_args[@]} " =~ " ${arg} " ]]; then
            app_args+=("$arg")
        fi
    done
fi

[ -n "${DEBUG}" ] && echo "Starting ComfyUI with arguments: ${app_args[*]}"
python3 ./ComfyUI/main.py "${app_args[@]}"
