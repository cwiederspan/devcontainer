# Devcontainer

A project for creating a dev container that can be used with VS Code's remote development functionality.

## Setup

```bash

docker build -t ateamsw/devcontainer:latest .

docker push ateamsw/devcontainer:latest

```

## Publish

This project uses GitHub Actions and the [`pipeline.yml`](.github/workflows/pipeline.yml) file to build and push
this image to [Docker Hub](https://hub.docker.com/r/ateamsw/devcontainer).
