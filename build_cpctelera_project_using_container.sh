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
    echo "Build cpctelera project in a Docker container."
    echo "  --folder-src            Path to source folder (where cpctelera project is: with Makefile, src/cfg folders, ...)"
    echo "  --folder-output         Path to output folder (where you want the build output to be placed)"
    echo "  --platform              Platform (cpc|enterprise)"
    echo "  --buildcfg-projname     (optional) Name of the project binary (sets build_config.mk variable PROJNAME)"
    echo "  --buildcfg-z80codeloc   (optional) Memory location where binary should start (sets build_config.mk variable Z80CODELOC)"
    echo "  --buildcfg-z80ccflags   (optional) Additional CFLAGS (appends to build_config.mk variable Z80CCFLAGS)"
    exit 1
}

while [[ $# -gt 0 ]]; do
    case "$1" in
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
echo "  Source folder: '${FOLDER_SRC}'"
echo "  Output folder: '${FOLDER_OUTPUT}'"
echo "  Platform: '${PLATFORM}'"
echo "  Project name: '${BUILDCFG_PROJNAME}'"
echo "  Z80 code location: '${BUILDCFG_Z80CODELOC}'"
echo "  Z80 CFLAGS: '${BUILDCFG_Z80CCFLAGS}'"
echo "  Docker image: 'braxpix/cpctelera-build-${PLATFORM}:latest'"

# Validate
# ########

# parameters
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

IMAGE="braxpix/cpctelera-build-${PLATFORM}:latest"

if ! command -v docker >/dev/null 2>&1; then
    echo "ERROR: Docker is not installed or not in PATH."
    exit 1
fi

echo "Pulling Docker image '${IMAGE}'..."
docker pull "${IMAGE}" >/dev/null 2>&1 || {
    echo "ERROR: Failed to pull Docker image '${IMAGE}'."
    exit 1
}
echo "Pulling Docker image '${IMAGE}' done successfully."

docker run -it --rm \
    -v "${FOLDER_SRC}":/mounted_project \
    -v "${FOLDER_OUTPUT}":/tmp/OUT:rw \
    \
    -e PROJECT_IS_ALREADY_HERE="/mounted_project" \
    -e BUILD_SCRIPT="/build/retro/projects/build_cpctelera_project_from_container.sh" \
    \
    -e BUILD_PLATFORM="${PLATFORM}" \
    -e BUILDCFG_PROJNAME="${BUILDCFG_PROJNAME}" \
    -e BUILDCFG_Z80CODELOC="${BUILDCFG_Z80CODELOC}" \
    -e BUILDCFG_Z80CCFLAGS="${BUILDCFG_Z80CCFLAGS:-}" \
    \
    "${IMAGE}"
