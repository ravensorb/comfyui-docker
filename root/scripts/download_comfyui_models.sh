#!/bin/bash

# Download models
echo "########################################"
echo "[INFO] Downloading ComfyUI Models..."
echo "########################################"

[ -n "${DEBUG}" ] && set -euxo pipefail

# Determine model list file based on LOW_VRAM
if [ "$LOW_VRAM" == "true" ]; then
    echo "[INFO] LOW_VRAM is set to true. Downloading FP8 models..."
    MODEL_LIST_FILE="/config/models_fp8.txt"
else
    echo "[INFO] LOW_VRAM is not set or false. Downloading non-FP8 models..."
    MODEL_LIST_FILE="/config/models.txt"
fi

if [ -z "${HF_TOKEN}" ]; then
    echo "[INFO] HF_TOKEN not provided. Skipping models that require authentication..."
    sed '/# Requires HF_TOKEN/,/^$/d' $MODEL_LIST_FILE > /config/models_filtered.txt
    DOWNLOAD_LIST_FILE="/config/models_filtered.txt"
else
    DOWNLOAD_LIST_FILE="$MODEL_LIST_FILE"
fi

aria2c --input-file="$DOWNLOAD_LIST_FILE" \
    --allow-overwrite=false --auto-file-renaming=false --continue=true \
    --max-connection-per-server=5 --conditional-get=true --log-level=notice \
    --save-session=/tmp/aria2-models.session --save-session-interval=2 \
    ${HF_TOKEN:+--header="Authorization: Bearer ${HF_TOKEN}"}
