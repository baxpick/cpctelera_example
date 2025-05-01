#!/usr/bin/env bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "$SCRIPT_DIR"

# 1. build
# ########

make
if [[ $? -ne 0 ]]; then
    echo "Error: Build failed."
    exit 1
fi
echo "Build completed successfully."

# 2. deploy
# #########

[[ ! -d /tmp/CPC ]] && mkdir -p /tmp/CPC
cp *.dsk /tmp/CPC
cp obj/*.bin /tmp/CPC
if [[ $? -ne 0 ]]; then
    echo "Error: Deploy failed."
    exit 1
fi
echo "Deploy completed successfully."

# 3. finalize
# ###########

cd -
