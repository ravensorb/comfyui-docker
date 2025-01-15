#!/bin/bash

echo "########################################"
echo "[INFO] Installing/Updating ComfyUI Workflows..."
echo "########################################"

[ -n "${DEBUG}" ] && set -euxo pipefail

# Copy workflows
WORKFLOWS_TEMPLATE_DIR="/defaults/workflows"
WORKFLOWS_DIR="/data/user/default/workflows"

[ ! -d "${WORKFLOWS_DIR}" ] && mkdir -p "$WORKFLOWS_DIR"
[ -d "${WORKFLOWS_TEMPLATE_DIR}" ] && cp -Ruv ${WORKFLOWS_TEMPLATE_DIR}/* "$WORKFLOWS_DIR/" 
