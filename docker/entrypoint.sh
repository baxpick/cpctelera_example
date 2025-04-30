#!/usr/bin/env bash

# WHAT: FIXXXME: !!! ...
# WHY: To build any cpctelera project from within a container
# HOW: ... FIXXXME: !!! ...

# Clone repository if variables are set
if [[ -n "${GIT_ROOT}" ]] && [[ -n "${GIT_ROOT_CREDS}" ]] && [[ -n "${GIT_PROJECT_SUFIX}" ]]; then
    
    # setup git credentials, even works for submodules
    git config --global credential.helper store
    echo "${GIT_ROOT_CREDS}" > ~/.git-credentials
    git config --global url."${GIT_ROOT_CREDS}".insteadOf "${GIT_ROOT}"

    GIT_PROJECT_TO_BUILD_REPO="${GIT_ROOT_CREDS}/${GIT_PROJECT_SUFIX}"
    echo "Cloning project repository: ${GIT_PROJECT_TO_BUILD_REPO}"
    
    # Create a temporary directory for cloning
    TMP_CLONE_DIR=$(mktemp -d)
    
    # Clone the repository with submodules
    git clone --recurse-submodules "${GIT_PROJECT_TO_BUILD_REPO}" "${TMP_CLONE_DIR}"
    
    # Copy files to FOLDER_PROJECTS while preserving directory structure
    echo "Copying project files to ${FOLDER_PROJECTS}"
    
    # Use rsync-like behavior with cp to merge directories
    # This ensures files from the repo are merged with existing directories
    cp -a "${TMP_CLONE_DIR}/." "${FOLDER_PROJECTS}/"
    
    # Clean up the temporary directory
    rm -rf "${TMP_CLONE_DIR}"
    
    echo "Repository cloned and files copied successfully"
fi

# Set up environment variables
if [[ "${BUILD_PLATFORM}" == "" ]]; then
    echo "ERROR: BUILD_PLATFORM not set"
    exit 1
fi
export MYTOOLS="/build/retro/projects/mytools"
export CPCT_PATH="${MYTOOLS}/cpctelera-linux-${BUILD_PLATFORM}/cpctelera"
if [[ ! -d "${CPCT_PATH}" ]]; then
    echo "Error: cpctelera path not found: ${CPCT_PATH}"
    exit 1
fi
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

# Run build script if provided
if [[ -n "${BUILD_SCRIPT}" && -f "${BUILD_SCRIPT}" ]]; then
    echo "Running custom build script: ${BUILD_SCRIPT}"
    exec "${BUILD_SCRIPT}" "$@"
else
    echo "No custom build script provided. Starting interactive shell."
    exec bash
fi
