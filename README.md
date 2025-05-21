# CPCtelera Docker Build Environment

## Overview

This repository provides a way to create a Docker-based build environment for [CPCtelera](https://github.com/lronaldo/cpctelera), a C development framework for the Amstrad CPC home computer.

The primary goal is to offer a consistent and isolated build environment that works across different host operating systems, including native support for both x86_64 (amd64) and aarch64 (arm64) architectures via a multi-architecture Docker image.

This example focuses on building the `platformClimber` game, originally found in the CPCtelera examples, but the Docker image can be used to build other CPCtelera projects.

## Prerequisites

*   [Docker](https://www.docker.com/get-started) must be installed and running on your system.
*   Host machine with x86_64 (amd64) or aarch64 (arm64) architecture

## Using the Pre-built Docker Image

A pre-built multi-architecture Docker image is available on DockerHub for [CPC](https://hub.docker.com/r/braxpix/cpctelera-build-cpc) and [Enterprise](https://hub.docker.com/r/braxpix/cpctelera-build-enterprise)

### 1. Clone and build project from https git repo

In this example we assume:

- you are building for Amstrad CPC platform
- cpctelera project is located on private git repo in this format: https://USER:TOKEN@DOMAIN/SUFFIX
- build script is located on that repo here: `myProject/build_from_container.sh`
- build script copies build results to container folder `/output`
- you want build results in your current folder
- build script needs environment variable `VAR1` with value `VALUE1`

Example docker command to execute is:

```bash
docker run -it --rm \
    -v $(pwd):/output:rw \
    \
    -e VAR1="VALUE1" \
    -e PROJECT_GIT_REPO="https://USER:TOKEN@DOMAIN/SUFFIX" \
    -e BUILD_SCRIPT="/build/retro/projects/myProject/build_from_container.sh" \
    \
    braxpix/cpctelera-build-cpc:latest
```

Working example using public repo: (note that you must provide dummy credentials to match the format)

```bash
docker run -it --rm \
    -v "$(pwd)":/tmp/CPC \
    \
    -e PROJECT_GIT_REPO="https://USER:TOKEN@github.com/baxpick/cpctelera_example.git" \
    -e BUILD_SCRIPT="/build/retro/projects/platformClimber/build.sh" \
    \
    braxpix/cpctelera-build-cpc:latest
```

And now, in current folder you have build results:

```bash
ls -la
-rw-r--r--@  1 user  staff   13209 May 21 14:52 game.bin
-rw-r--r--@  1 user  staff  204544 May 21 14:52 game.dsk
```

To run the generated `game.dsk` file in a web-based emulator, see the instructions in [emulator/README.md](emulator/README.md).

Result is here:

![Platform Climber Screenshot](res/platformClimber.png)

### 2. Clone and build project from local folder

In this example we assume:

- you are building for Amstrad CPC platform
- cpctelera project is located in current folder
- build script here: `platformClimber/build.sh`
- build script copies build results to container folder `/tmp/CPC`
- you want build results in folder `./OUTPUT`

Example docker command to execute is:

```bash
docker run -it --rm \
    -v "$(pwd)/OUTPUT":/tmp/CPC:rw \
    \
    -v "$(pwd)":/mounted_project \
    -e PROJECT_IS_ALREADY_HERE="/mounted_project" \
    -e BUILD_SCRIPT="/build/retro/projects/platformClimber/build.sh" \
    \
    braxpix/cpctelera-build-cpc:latest
```



### 3. Execute cpctelera commands locally

Create alias like this:

```bash
alias cpct='docker run --rm -v $(pwd):/hostMachine -w /hostMachine braxpix/cpctelera-build-cpc:latest'
```

Then, you can for example create cpctelera project:

```bash
cpct cpct_mkproject myGame
```

and then compile it manually:

```bash
cd myGame
cpct make
```

Note that you might need to adjust build config to comment out android part since support for it is removed to save space.

### 4. Port game to ENTERPRISE

NOTE: All credits for porting cpctelera to match Enterprise specifics, creating loader code and providing support in general go to Geco! Thanks again!

Porting cpctelera game can be tricky, but this simple example found in `box` folder is a good way to see how it works.

1. Update [build configuration](box/cfg/build_config.mk) so that CPCT_PATH is not set (docker image will setup this for you)

```bash
#CPCT_PATH      := $(THIS_FILE_PATH)../../../../cpctelera/
```

2. Update [build configuration](box/cfg/build_config.mk) so that code location is set to, for example, `0x4000` since this memory is safe to use having in mind that we will have a [loader](docker/enterprise/loader.asm) to prepare, load program binary and jump to correct program start location.

```bash
Z80CODELOC := 0x4000
```

3. From any folder execute

```
docker run -it --rm \
    -e PROJECT_GIT_REPO="https://USER:TOKEN@github.com/baxpick/cpctelera_example.git" \
    -e BUILD_SCRIPT=/build/retro/projects/box/build_enterprise.sh \
    -v "$(pwd)":/tmp/OUT \
    braxpix/cpctelera-build-enterprise:latest
```

and you will get: `loader.com` and `box.bin` files which you can copy to Enterprise emulator and when executed:

```
RUN "loader.com"
```

result can be seen here:

![Left: CPC, Right: Enterprise](res/box_CPC_vs_EP.png)

Important things to consider when porting to Enterprise:
- you need to map colors to match yours
- FIXXXME: ...

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

3. During building final image folder `cpctelera/tools/android` is removed to save space. If you need it, you must update Dockerfile and create your own image.