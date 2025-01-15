#!/bin/bash

echo "########################################"
echo "[INFO] Custom workflows..."
echo "########################################"

[ -n "${DEBUG}" ] && set -euxo pipefail

# Copy workflows
WORKFLOWS_TEMPLATE_DIR="/defaults/workflows"
WORKFLOWS_DIR="/data/user/default/workflows"
mkdir -p "$WORKFLOWS_DIR"

if [ -d "${WORKFLOWS_TEMPLATE_DIR}" ]; then
    cp -Ruv ${WORKFLOWS_TEMPLATE_DIR}/* "$WORKFLOWS_DIR/" || true
    echo "[INFO] Workflows copied successfully."
else
    echo "[WARNING] No custom workflows found. Skipping workflow copy."
fi

