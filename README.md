# CPCtelera Docker Build Environment

## Overview

This repository provides a way to create a Docker-based build environment for [CPCtelera](https://github.com/lronaldo/cpctelera), a C development framework for the Amstrad CPC home computer.

The primary goal is to offer a consistent, isolated and minimal build environment that works across different host operating systems, including native support for both x86_64 (amd64) and aarch64 (arm64) architectures via a multi-architecture Docker image.

## Thanks

Everyone mentioned in [AUTHORS.md](AUTHORS.md) - thank you!

Special thanks go to Geco for providing Enterprise [port](https://github.com/baxpick/cpctelera-enterprise/tree/enterprise-port) of cpctelera, [loader.asm](docker/enterprise/loader.asm) and support.

## Prerequisites

*   [Docker](https://www.docker.com/get-started) must be installed and running on your system.
*   Host machine with x86_64 (amd64) or aarch64 (arm64) architecture

## Using the Pre-built Docker Image

A pre-built multi-architecture Docker image is available on DockerHub for [CPC](https://hub.docker.com/r/braxpix/cpctelera-build-cpc) and [Enterprise](https://hub.docker.com/r/braxpix/cpctelera-build-enterprise)

### 1️⃣ Build project (from local folder) using default build script

Fetch example projects and default build script:

```bash
git clone -b development https://github.com/lronaldo/cpctelera.git

curl -L -o build.sh \
  https://raw.githubusercontent.com/baxpick/cpctelera_example/main/build_cpctelera_project_using_container.sh
chmod +x build.sh

mkdir -p OUTPUT/CPC
mkdir -p OUTPUT/ENTERPRISE
```

You can customize/override some build parameters like changing project name, compiled binary location or adding C compiler flags.

```
./build.sh --help
Build cpctelera project in a Docker container.
  --folder-src                Path to source folder (where cpctelera project is: with Makefile, src/cfg folders, ...)
  --folder-output             Path to output folder (where you want the build output to be placed)
  --platform                  Platform (cpc|enterprise)
  --build-deploy-extra ARG    (optional) (true|false - default: false) If set, deploy additional files for debug purpose mainly (e.g. object files)
  --buildcfg-z80ccflags ARG   (optional) Additional CFLAGS (appends to build_config.mk variable Z80CCFLAGS)
  --buildcfg-z80codeloc ARG   (optional) Memory location where binary should start (sets build_config.mk variable Z80CODELOC)
  --buildcfg-z80ccflags ARG   (optional) Additional CFLAGS (appends to build_config.mk variable Z80CCFLAGS)
```

**Example 1: Amstrad CPC**

Execute this to build `platformClimber` example for `Amstrad CPC` computer:

```bash
./build.sh \
    --folder-src ./cpctelera/examples/games/platformClimber \
    --folder-output OUTPUT/CPC \
    --platform cpc
```

Now, result binaries should be created in `OUTPUT/CPC` folder:

```bash
game.dsk
```

Use your favorite emulator or check out one included here [emulator/README.md](emulator/README.md).

```bash
RUN "PCLIMBER"
```

![Platform Climber Screenshot](res/example_output_cpc_platformClimber.png)


**Example 2: Enterprise**

Execute this to build `sprites` example for `Enterprise` computer:

```bash
./build.sh \
    --folder-src ./cpctelera/examples/easy/sprites \
    --folder-output OUTPUT/ENTERPRISE \
    --platform enterprise
```

Now, result binaries should be created in `OUTPUT/ENTERPRISE` folder:

```bash
sprites.com
sprites.bin
```

Open Enterprise emulator and:

```bash
RUN "SPRITES.COM"
```

![SpritesExampleOnEnterprise](res/example_output_enterprise_sprites.gif)

**With no changes at all to the code - it runs on Enterprise computer!**

This is quite simple example, but can a complete game work?

Try this:

```bash
./build.sh --folder-src ./cpctelera/examples/games/platformClimber --folder-output OUTPUT/ENTERPRISE --platform enterprise
```

```bash
RUN "GAME.COM"
```

and result is here - enjoy:

![PlatformClimberExampleOnEnterprise](res/example_output_enterprise_platformClimber.gif)

Another example of "full" game which can be built for both platforms (CPC and Enterprise) is here: https://github.com/baxpick/ludic-break-the-loop

Do this:

```bash
git clone https://github.com/baxpick/ludic-break-the-loop
cd ludic-break-the-loop
./build_all.sh
```

And you can see side by side both versions:

![SpritesExampleOnEnterprise](res/ludic_cpc_ep.gif)

Of course, porting cpctelera project to Enterprise can be tricky.

Important things to consider when porting to Enterprise:

- you don't have Amstrad CPC specific stuff like firmware or ROMS
- you need to map colors to match yours
- some (gfx related?) code/data should be below 0xC000, like setBorder and setPalette
- list of not ported (or not working) cpctelera functions: TODO...
- ... TODO

### 2️⃣ Build project (from https git repo) using custom build script

In this example we assume:

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

### 3️⃣ Build project (from local folder) using custom build script

In this example we assume:

- cpctelera project is located in current folder
- build script here: `myProject/build.sh`
- build script copies build results to container folder `/tmp/CPC`
- you want build results in folder `./OUTPUT`

Example docker command to execute is:

```bash
docker run -it --rm \
    -v "$(pwd)/OUTPUT":/tmp/CPC:rw \
    \
    -v "$(pwd)":/mounted_project \
    -e PROJECT_IS_ALREADY_HERE="/mounted_project" \
    -e BUILD_SCRIPT="/build/retro/projects/myProject/build.sh" \
    \
    braxpix/cpctelera-build-cpc:latest
```

### 4️⃣ Execute cpctelera commands locally

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

## Notes

1. Some of runtime packages in docker image are needed for cpctelera projects but some are just convenient for me. Feel free to update this list to make your image smaller or to add packages needed for building your cpctelera project.

2. `development` branch (at specific point in time) is used when cloning cpctelera (even different [repo](https://github.com/baxpick/cpctelera-enterprise/tree/enterprise-port) is used in case of Enterprise port) so if you need any other cpctelera repo/branch/commit do update Dockerfiles and re-create Docker images.

3. During building final image folder `cpctelera/tools/android` is removed to save space. If you need it, you must update Dockerfile and create your own image.