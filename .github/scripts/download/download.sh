#!/bin/bash

set -ex

readonly ARCH=amd64
readonly SEALOS=${sealoslatest:-$(
  until curl -sL "https://api.github.com/repos/labring/sealos/releases/latest"; do sleep 3; done | grep tarball_url | awk -F\" '{print $(NF-1)}' | awk -F/ '{print $NF}' | cut -dv -f2
)}

readonly ROOT="/tmp/$(whoami)/bin"
mkdir -p "$ROOT"

sudo apt remove buildah -y || true
docker run --rm -v "$ROOT:/pwd" -w /sealos "ghcr.io/labring-actions/cache:sealos-v$SEALOS-$ARCH" sealos /pwd

cd "$ROOT" && {
    docker run --rm -v "$PWD:/pwd" -w /tools --entrypoint /bin/sh "ghcr.io/labring-actions/cache:tools-$ARCH" -c "cp -auv . /pwd"
    if [[ -n "$sealosPatch" ]]; then
      docker run --rm -v "$PWD:/pwd" -w /usr/bin --entrypoint /bin/sh ghcr.io/labring/sealos:dev -c "cp -auv sealos /pwd"
    else
      docker run --rm -v "$PWD:/pwd" -w /sealos --entrypoint /bin/sh "ghcr.io/labring-actions/cache:sealos-v$SEALOS-$ARCH" -c "cp -auv sealos /pwd"
    fi
    sudo chown $(whoami) *
}

echo "$0"
tree "$ROOT"

{
  chmod a+x "$ROOT"/*
  sudo cp -auv "$ROOT"/* /usr/bin
  sudo sealos version
}
