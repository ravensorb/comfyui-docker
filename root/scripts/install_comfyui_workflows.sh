#!/bin/bash

echo "########################################"
echo "[INFO] Custom workflows..."
echo "########################################"

[ -n "${DEBUG}" ] && set -euxo pipefail

# Copy workflows
WORKFLOWS_DIR="/app/ComfyUI/user/default/workflows"
mkdir -p "$WORKFLOWS_DIR"

if [ -d "/workflows" ]; then
    cp -Rv /workflows/* "$WORKFLOWS_DIR/" || true
    echo "[INFO] Workflows copied successfully."
else
    echo "[WARNING] /workflows directory not found. Skipping workflow copy."
fi

