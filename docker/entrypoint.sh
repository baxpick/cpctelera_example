#!/usr/bin/env bash

# WHAT: Entrypoint script for fetching, configuring environment and building cpctelera projects
# WHY: To automate this process for usage in local and remote (from docker containers) builds
# HOW: Dockerfile should execute it as the entrypoint

# Clone repository (which has creds) ?
if [[ -n "${PROJECT_GIT_REPO}" ]]; then

    # 1) In case of this git repo format: https://USER:TOKEN@DOMAIN/SUFFIX
    if [[ "${PROJECT_GIT_REPO}" =~ ^https://([^:]+):([^@]+)@([^/]+)/.+$ ]]; then
        user=${BASH_REMATCH[1]}
        token=${BASH_REMATCH[2]}
        domain=${BASH_REMATCH[3]}

        GIT_ROOT="https://${user}@${domain}"
        GIT_ROOT_CREDS="https://${user}:${token}@${domain}"

        # setup git credentials, even works for submodules
        git config --global credential.helper store
        echo "${GIT_ROOT_CREDS}" > ~/.git-credentials
        git config --global url."${GIT_ROOT_CREDS}".insteadOf "${GIT_ROOT}" >/dev/null 2>&1

        echo "Cloning project repository..."
        
        # Create a temporary directory for cloning
        TMP_CLONE_DIR=$(mktemp -d)
        
        # Clone the repository with submodules
        git clone --recurse-submodules "${PROJECT_GIT_REPO}" "${TMP_CLONE_DIR}" >/dev/null 2>&1
        
        if [[ $? -ne 0 ]]; then
            echo "ERROR: Failed to clone repository"
            exit 1
        else
            echo "Cloning project repository finished successfully"
        fi

        # Copy files while preserving directory structure
        echo "Copying project files to ${FOLDER_PROJECTS}..."
        
        # Use rsync-like behavior with cp to merge directories
        # This ensures files from the repo are merged with existing directories
        cp -a "${TMP_CLONE_DIR}/." "${FOLDER_PROJECTS}/"
        
        echo "Copying project files to ${FOLDER_PROJECTS} finished successfully"

        # Clean up
        rm -rf "${TMP_CLONE_DIR}"
        rm  ~/.git-credentials

    else
        echo "ERROR: Unsupported git repo format"
        exit 1
    fi

# Use the existing repository if it's already cloned
elif [[ -n "${PROJECT_IS_ALREADY_HERE}" ]]; then

    if [[ ! -d "${PROJECT_IS_ALREADY_HERE}" ]]; then
        echo "ERROR: Folder '${PROJECT_IS_ALREADY_HERE}' not found"
        exit 1
    fi

    echo "Copying project files to ${FOLDER_PROJECTS}"
    cp -a "${PROJECT_IS_ALREADY_HERE}/." "${FOLDER_PROJECTS}/"
    echo "Copying project files to ${FOLDER_PROJECTS} finished successfully"
fi

# Set up environment variables
# ############################

if [[ "${BUILD_PLATFORM}" == "" ]]; then
    echo "ERROR: BUILD_PLATFORM not set"
    exit 1
fi
export MYTOOLS="/build/retro/projects/mytools"
export CPCT_PATH="${MYTOOLS}/cpctelera-linux-${BUILD_PLATFORM}/cpctelera"
if [[ ! -d "${CPCT_PATH}" ]]; then
    echo "ERROR: cpctelera path not found: ${CPCT_PATH}"
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

# MAIN
# ####

if [[ $# -gt 0 ]]; then
    # If arguments are passed to the entrypoint, execute them
    echo "Executing command: $@"
    exec "$@"
elif [[ -n "${BUILD_SCRIPT}" ]]; then

    if [[ ! -f "${BUILD_SCRIPT}" ]]; then
        echo "ERROR: build script not found: '${BUILD_SCRIPT}'"
        exit 1
    fi

    # If no arguments, but BUILD_SCRIPT is set, run it
    echo "Running custom build script: ${BUILD_SCRIPT}"
    # Note: This assumes BUILD_SCRIPT does not require arguments from docker run
    exec "${BUILD_SCRIPT}"
else
    # If no arguments and no BUILD_SCRIPT, start interactive shell
    echo "No command or custom build script provided. Starting interactive shell."
    exec bash
fi

