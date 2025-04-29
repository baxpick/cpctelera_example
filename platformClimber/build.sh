#!/usr/bin/env bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


cd "$SCRIPT_DIR"
make

if [[ $? -ne 0 ]]; then
    echo "Error: Build failed."
    exit 1
fi
echo "Build completed successfully."
