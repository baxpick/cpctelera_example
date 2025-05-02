#!/usr/bin/env bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "$SCRIPT_DIR"

# build
# #####

make
if [[ $? -ne 0 ]]; then
    echo "Error: Build failed."
    exit 1
fi
echo "Build completed successfully."

# Variables
# #########

LOADER_SRC="${FOLDER_PROJECTS}/loader.asm"
LOADER_BIN="${FOLDER_PROJECTS}/loader.com"
BIN="obj/box.bin"
RST_MAIN="obj/main.rst"
BUILD_CFG="cfg/build_config.mk"

# Update loader source
# ####################

FILE_START=$(cat ${BUILD_CFG} |grep 'Z80CODELOC.*:=' |perl -p -e 's/ +//g' |cut -d'=' -f2)
perl -i -p -e "s/file2load.*GENERATED.*/file2load equ ${FILE_START}/g" "${LOADER_SRC}"

FILE_SIZE="$(stat -c %s "${BIN}")"
perl -i -p -e "s/file2length.*GENERATED.*/file2length equ ${FILE_SIZE}/g" "${LOADER_SRC}"

CODE_START="$(cat ${RST_MAIN} |grep main:: |perl -p -e 's/\s+([^\s]+)\s+.*/\1/g')h"
perl -i -p -e "s/file2start.*GENERATED.*/file2start equ ${CODE_START}/g" "${LOADER_SRC}"

BIN_NAME=$(basename $BIN)
BIN_NAME_SIZE=$(echo $BIN_NAME |wc -c)
perl -i -p -e "s/file2:.*GENERATED.*/file2: db ${BIN_NAME_SIZE},\"${BIN_NAME}\"/g" "${LOADER_SRC}"

# Build loader binary
# ###################

sjasmplus --raw="${LOADER_BIN}" "${LOADER_SRC}"
if [[ $? -ne 0 ]]; then
    echo "Error: Build loader failed."
    exit 1
fi
echo "Build loader completed successfully."

# deploy
# ######

[[ ! -d /tmp/OUT ]] && mkdir -p /tmp/OUT

cp "${BIN}" /tmp/OUT && cp "${LOADER_BIN}" /tmp/OUT
if [[ $? -ne 0 ]]; then
    echo "Error: Deploy failed."
    exit 1
fi
echo "Deploy completed successfully."

# finalize
# ########

cd -
