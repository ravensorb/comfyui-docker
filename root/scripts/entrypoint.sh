#!/bin/bash

[ -n "${DEBUG}" ] && set -e

# Ensure correct permissions for /app directory
if [ ! -w "/app" ]; then
    echo "Warning: Cannot write to /app. Attempting to fix permissions..."
    sudo chown -R $(id -u):$(id -g) /app
fi

mkdir -p /data/output /data/input /data/user /data/temp /data/models /data/custom_nodes
sudo chown -R $(id -u):$(id -g) /data

echo "########################################"
echo "[INFO] Installing/Updating ComfyUI..."
echo "########################################"

# Install or update ComfyUI
cd /app
if [ ! -d "/app/ComfyUI" ]; then
    echo "ComfyUI not found. Installing..."
    chmod +x /scripts/install_comfyui.sh
    bash /scripts/install_comfyui.sh
elif [ "${COMFYUI_AUTO_UPDATE}" = "true" ] || [ "${COMFYUI_AUTO_UPDATE}" = "1" ]; then
    echo "Adding /app/ComfyUI/* to git safe.directory..."  

    echo "Updating ComfyUI..."
    cd /app/ComfyUI
    git config --global --get-all safe.directory | grep -q "/app/ComfyUI" || git config --global --add safe.directory /app/ComfyUI
    git pull

    echo "Updating ComfyUI-Manager..."
    cd /app/ComfyUI/custom_nodes/ComfyUI-Manager
    git config --global --get-all safe.directory | grep -q "/app/ComfyUI/custom_nodes/ComfyUI-Manager" || git config --global --add safe.directory /app/ComfyUI/custom_nodes/ComfyUI-Manager
    git pull

    cd /app
else
    echo "ComfyUI already installed. Skipping install/update..."
fi

# Download ComfyUI models
[ -f /scripts/download_comfyui_models.sh ] && bash /scripts/download_comfyui_models.sh

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
    --temp-directory /data/temp
    --extra-model-paths-config /config/extra_models_path.yaml
)

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
