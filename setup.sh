#!/bin/bash
set -euo pipefail

ENV_NAME="NucleusHack"
DATA_DIR="./data"
DATA_MARKER="$DATA_DIR/.download_complete"
GDRIVE_ZIP_ID="1LEGZg3Lu6w8_pTpso6RbZYEzGbOOrSTx"

# Make `conda activate` work inside a script
source "$(conda info --base)/etc/profile.d/conda.sh"

# --- Create environment (skip if it already exists) ---
if conda env list | grep -qE "^${ENV_NAME}\s"; then
    echo "Environment $ENV_NAME already exists; skipping creation."
else
    conda create -n "$ENV_NAME" python=3.12 -y
fi

conda activate "$ENV_NAME"

if [[ "$CONDA_DEFAULT_ENV" == "$ENV_NAME" ]]; then
    echo "Environment activated; installing dependencies"
    pip install -r requirements.txt
    python -m ipykernel install --user --name "$ENV_NAME"
else
    echo "Failed to activate $ENV_NAME. Dependencies not installed!"
    exit 1
fi

# --- Data download from Google Drive (skip if already present) ---
if [[ -f "$DATA_MARKER" ]]; then
    echo "Data already present; skipping download."
else
    echo "Downloading data from Google Drive..."
    mkdir -p "$DATA_DIR"

    # Biowulf already exports http_proxy/https_proxy on compute nodes.
    # Only warn if they're somehow unset, rather than hardcoding a node.
    if [[ -z "${http_proxy:-}" ]]; then
        echo "WARNING: http_proxy not set — download may fail on this node." >&2
    fi

    gdown "$GDRIVE_ZIP_ID" -O "$DATA_DIR/images.zip"
    unzip -qo "$DATA_DIR/images.zip" -d "$DATA_DIR"
    rm "$DATA_DIR/images.zip"
    rm -rf "$DATA_DIR/__MACOSX"   # strip macOS metadata junk

    # Verify expected number of images before marking complete
    count=$(find "$DATA_DIR" \( -name '*.tiff' -o -name '*.tif' \) | wc -l)
    if [[ "$count" -ne 50 ]]; then
        echo "ERROR: expected 50 images, found $count. Not marking complete." >&2
        exit 1
    fi

    touch "$DATA_MARKER"
    echo "Download complete ($count images)."
fi

conda deactivate
conda activate base