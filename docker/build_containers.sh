#!/bin/bash

PYTHON_VERSION=3.11
SITUS_VERSION=3.1

PLATFORM=$(uname -m)

if [ "$PLATFORM" == "x86_64" ]; then
  BUILD_PLATFORM="linux/amd64"
else
  BUILD_PLATFORM="arm64"
fi
echo "BUILD_PLATFORM is set to $BUILD_PLATFORM"

WORKDIR=$(pwd)
cp -r $HOME/src/pytme $WORKDIR/pytme
rm -rf $WORKDIR/pytme/build
rm -rf $WORKDIR/pytme/*egg-info

docker build \
  -t template_matching \
  --platform ${BUILD_PLATFORM} \
  --build-arg PYTHON_VERSION=${PYTHON_VERSION} \
  --build-arg SITUS_VERSION=${SITUS_VERSION} \
  -f Dockerfile \
  .
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

git clone https://github.com/FridoF/PyTom.git && \
  cd PyTom && \
  echo "RUN apt-get update --fix-missing && apt-get install -y time" >> Dockerfile
docker build \
  -t pytom \
  --platform ${BUILD_PLATFORM} \
  .
docker image tag pytom dquz/pytom:latest
docker image push dquz/pytom:latest

rm -rf $WORKDIR/pytme
rm -rf PyTom
