# Dev Container

![Build Dev Container](https://github.com/ateamsw/devcontainer/workflows/Build%20Dev%20Container/badge.svg)

A project for creating a dev container that can be used with VS Code's remote development functionality.

## Build Locally

```bash

docker build -t ateamsw/devcontainer:latest .

docker push ateamsw/devcontainer:latest

docker run -it --rm ateamsw/devcontainer:latest

```

## Test Locally

```bash

docker build -t ateamsw/devcontainer:local .

docker run -it --rm ateamsw/devcontainer:local

```

## GitHub Actions

This project uses GitHub Actions and the [`pipeline.yml`](.github/workflows/pipeline.yml) file to build and push
this image to [Docker Hub](https://hub.docker.com/r/ateamsw/devcontainer).

## Follow Up

Email chwieder@microsoft.com for more information on this container and scenarios for usage.
