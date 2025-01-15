#!/bin/bash

echo "########################################"
echo "[INFO] Installing/Updating ComfyUI Custom Models..."
echo "########################################"

[ -n "${DEBUG}" ] && set -euxo pipefail

download_models() {
    local model_list_fp8="$1"
    local model_list_non_fp8="$2"
    local low_vram="$3"

    # Determine model list file based on LOW_VRAM
    if [ "$model_list_fp8" == "$model_list_non_fp8" ]; then
        echo "[INFO] Model list files are the same. Ignoring LOW_VRAM argument..."
        MODEL_LIST_FILE="$model_list_fp8"
    else
        if [ "$low_vram" == "true" ]; then
            echo "[INFO] LOW_VRAM is set to true. Downloading FP8 models..."
            MODEL_LIST_FILE="$model_list_fp8"
        else
            echo "[INFO] LOW_VRAM is not set or false. Downloading non-FP8 models..."
            MODEL_LIST_FILE="$model_list_non_fp8"
        fi
    fi

    if [ -z "${HF_TOKEN}" ]; then
        echo "[INFO] HF_TOKEN not provided. Skipping models that require authentication..."
        sed '/# Requires HF_TOKEN/,/^$/d' $MODEL_LIST_FILE > /config/models_filtered.txt
        DOWNLOAD_LIST_FILE="/config/models_filtered.txt"
    else
        DOWNLOAD_LIST_FILE="$MODEL_LIST_FILE"
    fi

    [ -n "${DEBUG}" ] && LOG_LEVEL="info" || LOG_LEVEL="notice"
    [ -n "${DEBUG}" ] && LOG_LEVEL_CONSOLE="info" || LOG_LEVEL_CONSOLE="notice"

    aria2c --input-file="$DOWNLOAD_LIST_FILE" \
        --log="/data/temp/aria2c.log" --log-level=${LOG_LEVEL} --console-log-level=${LOG_LEVEL_CONSOLE} \
        --allow-overwrite=false --auto-file-renaming=false --continue=true \
        --max-connection-per-server=5 --conditional-get=true \
        --save-session=/data/aria2-models.session --save-session-interval=2 \
        ${HF_TOKEN:+--header="Authorization: Bearer ${HF_TOKEN}"} || true
}

[ -f /data/temp/aria2c.log ] && rm -f /data/temp/aria2c.log
[ ! -d /data/temp ] && mkdir -p /data/temp

# Example usage
if [ -f "/config/models.txt" ] && { [ "${COMFYUI_DOWNLOAD_STD_MODELS}" = "true" ] || [ "${COMFYUI_DOWNLOAD_STD_MODELS}" = "1" ]; }; then
    echo "[INFO] Downloading models..."
    download_models "/config/models_fp8.txt" "/config/models.txt" "$LOW_VRAM"
fi 

if [ -f "/config/models_video.txt" ] && { [ "${COMFYUI_DOWNLOAD_VIDEO_MODELS}" = "true" ] || [ "${COMFYUI_DOWNLOAD_VIDEO_MODELS}" = "1" ]; }; then
    echo "[INFO] Downloading video models..."
    download_models "/config/models_video_fp8.txt" "/config/models_video.txt" "$LOW_VRAM"
fi