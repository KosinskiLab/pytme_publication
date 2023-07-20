#!/bin/bash

PYTHON_VERSION=3.11
SITUS_VERSION=3.1
BUILD_PLATFORM=arm64

WORKDIR=$(pwd)
cp -r $HOME/src/edm_simulation $WORKDIR/edm_simulation
rm -rf $WORKDIR/edm_simulation/build
rm -rf $WORKDIR/edm_simulation/*egg-info

docker build \
  -t template_matching \
  --platform ${BUILD_PLATFORM} \
  --build-arg PYTHON_VERSION=${PYTHON_VERSION} \
  --build-arg SITUS_VERSION=${SITUS_VERSION} \
  -f Dockerfile \
  .
rm -rf $WORKDIR/edm_simulation
docker image tag template_matching dquz/template_matching:latest
docker image push dquz/template_matching:latest

docker build \
  -t powerfit \
  --platform ${BUILD_PLATFORM} \
  -f powerfitDockerfile \
  .

docker image tag powerfit dquz/powerfit:latest
docker image push dquz/powerfit:latest
docker rmi $(docker images -f "dangling=true" -q)

git clone https://github.com/FridoF/PyTom.git && cd PyTom
docker build \
  -t pytom \
  --platform ${BUILD_PLATFORM} \
  .
docker image tag pytom dquz/pytom:latest
docker image push dquz/pytom:latest
rm -rf PyTom