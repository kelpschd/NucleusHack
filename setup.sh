#!/bin/bash
set -euo pipefail

ENV_NAME="NucleusHack"

# Make `conda activate` work inside a script
source "$(conda info --base)/etc/profile.d/conda.sh"

conda create -n "$ENV_NAME" python=3.12 -y
conda activate "$ENV_NAME"

if [[ "$CONDA_DEFAULT_ENV" == "$ENV_NAME" ]]; then
    echo "Environment activated; installing dependencies"
    pip install -r requirements.txt
    python -m ipykernel install --user --name "$ENV_NAME"
else
    echo "Failed to activate $ENV_NAME. Dependencies not installed!"
    exit 1
fi

conda deactivate
conda activate base