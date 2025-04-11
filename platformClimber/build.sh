#!/usr/bin/env bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

export MYTOOLS="/build/retro/projects/mytools"

export CPCT_PATH="${MYTOOLS}/cpctelera-linux-cpc/cpctelera"
export PATH=${PATH}:${CPCT_PATH}/tools/sdcc-3.6.8-r9946/bin
export PATH=${PATH}:${CPCT_PATH}/tools/2cdt/bin
export PATH=${PATH}:${CPCT_PATH}/tools/cpc2cdt/bin
export PATH=${PATH}:${CPCT_PATH}/tools/dskgen/bin
export PATH=${PATH}:${CPCT_PATH}/tools/hex2bin-2.0/bin
export PATH=${PATH}:${CPCT_PATH}/tools/iDSK-0.13/bin
export PATH=${PATH}:${CPCT_PATH}/tools/img2cpc/bin
export PATH=${PATH}:${CPCT_PATH}/tools/rgas-1.2.2
export PATH=${PATH}:${CPCT_PATH}/tools/winape
export PATH=${PATH}:${CPCT_PATH}/tools/zx7b/bin
export PATH=${PATH}:${CPCT_PATH}/tools/scripts

cd "$SCRIPT_DIR"
make