# CPCtelera Docker Build Environment

## Overview

This repository provides a way to create a Docker-based build environment for [CPCtelera](https://github.com/lronaldo/cpctelera), a C development framework for the Amstrad CPC home computer.

The primary goal is to offer a consistent and isolated build environment that works across different host operating systems, including native support for both x86_64 (amd64) and aarch64 (arm64) architectures via a multi-architecture Docker image.

This example focuses on building the `platformClimber` game, originally found in the CPCtelera examples, but the Docker image can be used to build other CPCtelera projects.

## Prerequisites

*   [Docker](https://www.docker.com/get-started) must be installed and running on your system.
*   Host machine with x86_64 (amd64) or aarch64 (arm64) architecture

## Using the Pre-built Docker Image

A pre-built multi-architecture Docker image is available on [Docker Hub](https://hub.docker.com/r/braxpix/cpctelera-build-cpc):

To build the `platformClimber` example project using the pre-built Docker image, run the following command:

```bash
docker run -it --rm \
    -e GIT_ROOT_CREDS="https://github.com" \
    -e GIT_ROOT="https://github.com" \
    -e GIT_PROJECT_SUFIX="baxpick/cpctelera_example" \
    -e BUILD_SCRIPT=/build/retro/projects/platformClimber/build.sh \
    -v "$(pwd)":/tmp/CPC \
    braxpix/cpctelera-build-cpc:latest
```

Docker will automatically detect your system's architecture (amd64 or arm64) and pull the appropriate image layers.

When container is started, [repo](https://github.com/baxpick/cpctelera_example) is cloned to `/build/retro/projects`. If you need credentials to clone repo, you need to set them in `GIT_ROOT_CREDS` variable. If you don't want to clone your project but build project from local filesystem, make sure you mount the project to container to see it.

Since container already contains pre-built cpctelera in (for example) `/build/retro/projects/mytools/cpctelera-linux-cpc` and all cpctelera environment variables and system PATH are set, we can execute build script provided in `BUILD_SCRIPT` variable.

In the end, you will have final build product `game.dsk` in your current folder since build script copies it to `/tmp/CPC` and this is mounted to your current folder.

## Repository Structure

*   `README.md`: This file.
*   `platformClimber/*`: The example CPCtelera game project.
    *   `build.sh`: Simple script to run `make` and copy the output (`*.dsk`) to `/tmp/CPC`. This script should be executed by the Docker container by providing it's absolute path via `BUILD_SCRIPT` variable.
    *   Other source is copied from [cpctelera example](https://github.com/lronaldo/cpctelera/tree/development/examples/games/platformClimber)
*   `docker/*`: Contains files related to the Docker image creation.
    *   `Dockerfile.cpc`: Instructions to build the multi-architecture Docker image for `cpc` platform, including installing dependencies. All is done in 2 stages: first stage is used to build cpctelera and second stage is used to create final image with pre-build binaries.
    *   `entrypoint.sh`: The script that runs when the container starts. It sets up environment variables, optionally clones a Git repo, and executes the specified `BUILD_SCRIPT`.
    *   `build_and_upload.sh`: Helper script if you don't want to build and push docker image using github action.
*   `.github/workflows/docker-build-push.yml`: GitHub Actions workflow to automatically build and push the multi-architecture Docker image to Docker Hub. Note that we must set repository variables `DOCKERHUB_USERNAME` and `DOCKERHUB_PASSWORD` in your GitHub repository settings for the login and push to Docker Hub to succeed.

## Notes

1. These are runtime packages installed in final image:

```docker
# Install runtime dependencies only
RUN apk add --no-cache \
    bash \
    perl \
    dos2unix \
    grep \
    coreutils \
    make \
    freeimage-dev \
    bc \
    util-linux \
    graphicsmagick \
    xxd \
    python3 \
    jq \
    git \
    file
```

Some of those are needed for cpctelera projects at compile-time but some are just convenient for me. Feel free to update this list to make your image smaller or to add packages needed for building your cpctelera project.

2. `development` branch is used when cloning cpctelera as it contains many useful stuff so if you need other branch (there have been braking changes between branches) you should update this in Dockerfile:

```docker
git clone -b BRANCH_YOU_NEED https://github.com/lronaldo/cpctelera
```
