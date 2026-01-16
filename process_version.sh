#!/usr/bin/bash

VERSION=$1

ARCH=loong64
GO_VERSION=1.25

DISTS="dists"
SRCS="srcs"
pushd docker-ce-packaging

SPEC_FILES="docker-ce.spec docker-ce-cli.spec" \
    ARCH=loong64 ARCHES=loong64 \
    VERSION=${VERSION} \
    REF=v${VERSION} \
    DOCKER_ENGINE_REF=docker-v${VERSION} \
    GO_VERSION=1.25 \
    GO_IMAGE=golang:1.25 \
    make anolis-23
popd

## Copy release to dists.
if [ -d dists ];
    mkdir dists
fi

if [ -d $SRCS ];
    mkdir $SRCS
fi
cp -R docker-ce-packaging/rpm/rpmbuild/anolis-23/RPMS/loongarch64/docker-ce*$VERSION*.rpm "$DISTS"/
