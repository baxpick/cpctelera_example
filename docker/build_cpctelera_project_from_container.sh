#!/usr/bin/env bash

# Variables
# #########

# mandatory variables
PLATFORM=${BUILD_PLATFORM}
[[ "${PLATFORM}" == "" ]] && { echo "Error: BUILD_PLATFORM is not set."; exit 1; }

DEPLOY_EXTRA=${BUILD_DEPLOY_EXTRA}
[[ "${DEPLOY_EXTRA}" != "true" ]] && [[ "${DEPLOY_EXTRA}" != "false" ]] && { echo "Error: BUILD_DEPLOY_EXTRA is not set."; exit 1; }

# const variables
BUILD_CFG="${FOLDER_PROJECTS}/cfg/build_config.mk"
[[ ! -f "${BUILD_CFG}" ]] && { echo "Error: Build configuration file not found."; exit 1; }

# optional variables (default empty/not used)
PROJNAME=${BUILDCFG_PROJNAME:-""}
Z80CODELOC=${BUILDCFG_Z80CODELOC:-""}
Z80CCFLAGS=${BUILDCFG_Z80CCFLAGS:-""}

# although optional PROJNAME must be set
if [[ "${PROJNAME}" == "" ]]; then
    PROJNAME=$(perl -ne 'print $1 and exit if /^\s*PROJNAME\s*:=\s*(\S+)/' "${BUILD_CFG}")
fi
if [[ "${PROJNAME}" == "" ]]; then
    echo "Error: PROJNAME is not set."
    exit 1
fi

# generated variables
if [[ "${PLATFORM}" == "enterprise" ]]; then
    LOADER_SRC="${FOLDER_PROJECTS}/loader.asm"
    LOADER_BIN="${FOLDER_PROJECTS}/${PROJNAME}.com"
fi

if [[ "${PLATFORM}" == "enterprise" ]]; then
    BIN="${FOLDER_PROJECTS}/obj/${PROJNAME}.bin"
elif [[ "${PLATFORM}" == "cpc" ]]; then
    BIN="${FOLDER_PROJECTS}/${PROJNAME}.dsk"
fi

# Update build configuration
# ##########################

# always comment out CPCT_PATH
perl -i -p -e 's/(.*CPCT_PATH.*:=.*)/#\1/g' ${BUILD_CFG}

# for optional variables, only update if they are set
if [[ "${PROJNAME}" != "" ]]; then
    perl -i -p -e "s/.*PROJNAME.*:=.*/PROJNAME := ${PROJNAME}/g" ${BUILD_CFG}
fi

if [[ "${Z80CODELOC}" != "" ]]; then
    perl -i -p -e "s/.*Z80CODELOC.*:=.*/Z80CODELOC := ${Z80CODELOC}/g" ${BUILD_CFG}
fi

if [[ "${Z80CCFLAGS}" != "" ]]; then
    perl -i -p -e 's|.*Z80CCFLAGS.* :=(.*)|Z80CCFLAGS := '"${Z80CCFLAGS}"'\\\n\1|g' "${BUILD_CFG}"
fi

# build
# #####

cd ${FOLDER_PROJECTS}

# deploy confinguration for debugging
if [[ "${DEPLOY_EXTRA}" == "true" ]]; then
    cp -r "${FOLDER_PROJECTS}/cfg" /tmp/OUT
fi

make
if [[ $? -ne 0 ]]; then
    echo "Error: Build failed."
    exit 1
fi
cd -
echo "Build completed successfully."

RST_MAIN="$(grep -r ' _main::' ${FOLDER_PROJECTS}/obj |grep .rst |cut -d':' -f1)"
[[ "${RST_MAIN}" == "" ]] && { echo "Error: main entry point not found!"; exit 1; }

if [[ "${PLATFORM}" == "enterprise" ]]; then

    # Update loader source
    # ####################

    FILE_START=$(cat ${BUILD_CFG} |grep 'Z80CODELOC.*:=' |perl -p -e 's/ +//g' |cut -d'=' -f2)
    perl -i -p -e "s/file2load.*GENERATED.*/file2load equ ${FILE_START}/g" "${LOADER_SRC}"

    FILE_SIZE="$(stat -c %s "${BIN}")"
    perl -i -p -e "s/file2length.*GENERATED.*/file2length equ ${FILE_SIZE}/g" "${LOADER_SRC}"

    CODE_START="$(cat ${RST_MAIN} |grep main:: |perl -p -e 's/\s+([^\s]+)\s+.*/\1/g')h"
    perl -i -p -e "s/file2start.*GENERATED.*/file2start equ ${CODE_START}/g" "${LOADER_SRC}"

    BIN_NAME=$(basename $BIN)
    BIN_NAME_SIZE=$(echo -n $BIN_NAME |wc -c)
    perl -i -p -e "s/file2:.*GENERATED.*/file2: db ${BIN_NAME_SIZE},\"${BIN_NAME}\"/g" "${LOADER_SRC}"

    # Build loader binary
    # ###################

    sjasmplus --raw="${LOADER_BIN}" "${LOADER_SRC}"
    if [[ $? -ne 0 ]]; then
        echo "Error: Build loader failed."
        exit 1
    fi
    echo "Build loader completed successfully."
fi

# deploy
# ######

[[ ! -d /tmp/OUT ]] && mkdir -p /tmp/OUT

cp "${BIN}" /tmp/OUT

if [[ "${DEPLOY_EXTRA}" == "true" ]]; then
    cp -r "${FOLDER_PROJECTS}/obj" /tmp/OUT
fi

if [[ "${PLATFORM}" == "enterprise" ]]; then

    if [[ "${DEPLOY_EXTRA}" == "true" ]]; then
        cp "${LOADER_SRC}" /tmp/OUT      
    fi
    
    cp "${LOADER_BIN}" /tmp/OUT
fi

if [[ $? -ne 0 ]]; then
    echo "Error: Deploy failed."
    exit 1
fi
echo "Deploy completed successfully."
