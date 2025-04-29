# CPCtelera Docker Build Environment

## Overview

This repository provides a Docker-based build environment for [CPCtelera](https://github.com/lronaldo/cpctelera), a C development framework for the Amstrad CPC home computer.

The primary goal is to offer a consistent and isolated build environment that works across different host operating systems, specifically addressing potential build issues encountered on platforms like macOS with Apple Silicon.

This example focuses on building the `platformClimber` game, originally found in the CPCtelera examples, but the Docker image can be used to build other CPCtelera projects.

## Prerequisites

*   [Docker](https://www.docker.com/get-started) must be installed and running on your system.

## Using the Pre-built Docker Image

A pre-built Docker image (`braxpix/cpctelera-build-arm64-cpc:1.0`) is available on Docker Hub, supporting arm64 architecture but the build script (`docker/build_and_upload.sh`) can be used to build and deploy for any other supported architecture.

## Running a Build

To build the `platformClimber` example project using the pre-built Docker image, on macOS with silicon chip, run the following command:

```bash
docker run -it --rm \
    -e GIT_ROOT_CREDS="https://github.com" \
    -e GIT_ROOT="https://github.com" \
    -e GIT_PROJECT_SUFIX="baxpick/cpctelera_example" \
    -e BUILD_SCRIPT=/build/retro/projects/platformClimber/build.sh \
    -e BUILD_PLATFORM=cpc \
    -v "$(pwd)":/tmp/CPC \
    braxpix/cpctelera-build-arm64-cpc:1.0
```

**Explanation of the `docker run` command:**

*   Environment variables used by the `docker/entrypoint.sh` script:
    *   `GIT_ROOT`, `GIT_ROOT_CREDS`, `GIT_PROJECT_SUFIX`: Used to clone the specified Git repository *into* the container's `/build/retro/projects` directory if needed but you can also mount the local code instead. Note that in case credentials are needed to clone the repo, you need to enter them as part of `GIT_ROOT_CREDS` variable, otherwise this variable is the same as `GIT_ROOT`.
    *   `BUILD_SCRIPT`: The absolute path *inside the container* to the build script that should be executed.
    *   `BUILD_PLATFORM`: Specifies the target platform for CPCtelera (e.g., `cpc`). Defaults to `cpc` if not set. Currently only `cpc` platform is supported but there are plans to support other Z80 platforms. This variable is used to export `CPCT_PATH` variable to point to correct path with pre-built cpctelera and to extend `PATH` to make correct cpctelera tools visible.

*   Build Output:
    *   After the container runs successfully, the compiled game disk image (`.dsk` file) will be available in the current folder since docker mounts `/tmp/CPC` here and this is also where build script will copy the build result to.

## Repository Structure

*   `README.md`: This file.
*   `platformClimber/`: The example CPCtelera game project.
    *   `build.sh`: Simple script to run `make` and copy the output (`.dsk`) to `/tmp/CPC`. This is executed by the Docker container.
    *   Other source is copied from [cpctelera example](https://github.com/lronaldo/cpctelera/tree/development/examples/games/platformClimber)
*   `docker/`: Contains files related to the Docker image creation.
    *   `Dockerfile.cpc`: Instructions to build the Docker image for `cpc` platform, including installing dependencies. All is done in 2 stages: build (used to build cpctelera) and run stage (used to actually build your own cpctelera project).
    *   `entrypoint.sh`: The script that runs when the container starts. It sets up environment variables, optionally clones a Git repo, and executes the specified `BUILD_SCRIPT`.
    *   `build_and_upload.sh`: A helper script to build the Docker image and push it to Docker Hub.



