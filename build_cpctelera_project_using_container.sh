#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ "$PWD" != "$SCRIPT_DIR" ]]; then
  echo "ERROR: Please run this script from its directory: $SCRIPT_DIR"
  exit 1
fi

# Functions
# #########

abs_path() {
  local p="$1"
  if command -v realpath >/dev/null 2>&1; then
    realpath "$p" 2>/dev/null
  else
    # fallback for macOS / systems without realpath
    echo "$(cd "$(dirname "$p")" && pwd -P)/$(basename "$p")"
  fi
}

# MAIN
# ####

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Build cpctelera project in a container."
    echo "  --container                 Container type (docker|container - default: docker)"
    echo "  --folder-src                Path to source folder (where cpctelera project is: with Makefile, src/cfg folders, ...)"
    echo "  --folder-output             Path to output folder (where you want the build output to be placed)"
    echo "  --platform                  Platform (cpc|enterprise)"
    echo "  --image-version             Image version tag (development-latest|master-latest|...)"
    echo "  --build-deploy-extra ARG    (optional) (true|false - default: false) If set, deploy additional files for debug purpose mainly (e.g. object files)"
    echo "  --buildcfg-z80ccflags ARG   (optional) Additional CFLAGS (appends to build_config.mk variable Z80CCFLAGS)"
    echo "  --buildcfg-z80codeloc ARG   (optional) Memory location where binary should start (sets build_config.mk variable Z80CODELOC)"
    echo "  --buildcfg-z80ccflags ARG   (optional) Additional CFLAGS (appends to build_config.mk variable Z80CCFLAGS)"
    exit 1
}

# default values for arguments
BUILD_DEPLOY_EXTRA="false"
CONTAINER="docker"
IMAGE_VERSION="development-latest"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --container)
            CONTAINER="$2"
            shift 2
            ;;    
        --folder-src)
            FOLDER_SRC="$(abs_path "$2")"
            shift 2
            ;;
        --folder-output)
            FOLDER_OUTPUT="$(abs_path "$2")"
            shift 2
            ;;
        --platform)
            PLATFORM="$2"
            shift 2
            ;;
        --image-version)
            IMAGE_VERSION="$2"
            shift 2
            ;;
        --build-deploy-extra)
            BUILD_DEPLOY_EXTRA="$2"
            shift 2
            ;;
        --buildcfg-projname)
            BUILDCFG_PROJNAME="$2"
            shift 2
            ;;
        --buildcfg-z80codeloc)
            BUILDCFG_Z80CODELOC="$2"
            shift 2
            ;;
        --buildcfg-z80ccflags)
            BUILDCFG_Z80CCFLAGS="$2"
            shift 2
            ;;
        --help)
            usage
            ;;
        *)
            echo "ERROR: Unknown option: $1"
            usage
            ;;
    esac
done

# Log
# ###

echo "Building cpctelera project with the following parameters:"
echo "  Container: '${CONTAINER}'"
echo "  Source folder: '${FOLDER_SRC}'"
echo "  Output folder: '${FOLDER_OUTPUT}'"
echo "  Platform: '${PLATFORM}'"
echo "  Image version: '${IMAGE_VERSION}'"
echo "  Build deploy extra: '${BUILD_DEPLOY_EXTRA}'"
echo "  Project name: '${BUILDCFG_PROJNAME}'"
echo "  Z80 code location: '${BUILDCFG_Z80CODELOC}'"
echo "  Z80 CFLAGS: '${BUILDCFG_Z80CCFLAGS}'"
echo "  Image: 'braxpix/cpctelera-build-${PLATFORM}:${IMAGE_VERSION}'"

# Validate
# ########

# parameters
if [[ "${CONTAINER}" != "docker" && "${CONTAINER}" != "container" ]]; then
    echo "ERROR: Container parameter is wrong: '${CONTAINER}'"
    exit 1
fi

if [[ ! -d "${FOLDER_SRC}" ]]; then
    echo "ERROR: Source folder does not exist: '${FOLDER_SRC}'"
    exit 1
fi

if [[ ! -d "${FOLDER_OUTPUT}" ]]; then
    echo "ERROR: Output folder does not exist: '${FOLDER_OUTPUT}'"
    exit 1
fi

if [[ -z "${FOLDER_SRC}" || -z "${FOLDER_OUTPUT}" || -z "${PLATFORM}" ]]; then
    echo "ERROR: Missing required arguments"
    usage
fi

if [[ "${BUILD_DEPLOY_EXTRA}" != "true" && "${BUILD_DEPLOY_EXTRA}" != "false" ]]; then
    echo "ERROR: Invalid build deploy extra specified. Use 'true' or 'false'."
    exit 1
fi

if [[ "${PLATFORM}" != "cpc" && "${PLATFORM}" != "enterprise" ]]; then
    echo "ERROR: Invalid platform specified. Use 'cpc' or 'enterprise'."
    exit 1
fi

# other
if [[ ! -f "${FOLDER_SRC}/Makefile" ]] || [[ ! -d "${FOLDER_SRC}/src" ]] || [[ ! -d "${FOLDER_SRC}/cfg" ]] || [[ ! -f "${FOLDER_SRC}/cfg/build_config.mk" ]]; then
    echo "ERROR: Cpctelera project not found in source folder: '${FOLDER_SRC}'"
    exit 1
fi

# Build
# #####

IMAGE="braxpix/cpctelera-build-${PLATFORM}:${IMAGE_VERSION}"

if ! command -v "${CONTAINER}" >/dev/null 2>&1; then
    echo "ERROR: Container CLI '${CONTAINER}' is not installed or not in PATH."
    exit 1
fi

if [[ "${CONTAINER}" == "docker" ]]; then
    echo "Pulling image '${IMAGE}'..."
    docker pull "${IMAGE}" >/dev/null 2>&1 || {
        echo "ERROR: Failed to pull image '${IMAGE}'."
        exit 1
    }
    echo "Pulling image '${IMAGE}' done successfully."
fi

${CONTAINER} run -it --rm \
    -v "${FOLDER_SRC}":/mounted_project \
    -v "${FOLDER_OUTPUT}":/tmp/OUT:rw \
    \
    -e PROJECT_IS_ALREADY_HERE="/mounted_project" \
    -e BUILD_SCRIPT="/build/retro/projects/build_cpctelera_project_from_container.sh" \
    \
    -e BUILD_DEPLOY_EXTRA="${BUILD_DEPLOY_EXTRA}" \
    -e BUILD_PLATFORM="${PLATFORM}" \
    -e BUILDCFG_PROJNAME="${BUILDCFG_PROJNAME}" \
    -e BUILDCFG_Z80CODELOC="${BUILDCFG_Z80CODELOC}" \
    -e BUILDCFG_Z80CCFLAGS="${BUILDCFG_Z80CCFLAGS}" \
    \
    "${IMAGE}"
