#!/usr/bin/bash

# 开启严格模式
set -euo pipefail

VERSION=$1
if [ -z "$VERSION" ]; then
    echo "Error: Version argument is required."
    exit 1
fi

# 全局配置
ARCH="loong64"
GO_VERSION="1.25"
DISTS="dists"
SRCS="srcs"
REGISTRY="lcr.loongnix.cn"

# 创建必要的输出目录
mkdir -p "$DISTS" "$SRCS"

# 定义构建函数
build_target() {
    local TARGET=$1
    echo "------------------------------------------"
    echo "Building Target: $TARGET for Version: $VERSION"
    echo "------------------------------------------"

    pushd docker-ce-packaging > /dev/null
    
    SPEC_FILES="docker-ce.spec docker-ce-cli.spec" \
    ARCH=$ARCH \
    ARCHES=$ARCH \
    VERSION=${VERSION} \
    REF=v${VERSION} \
    DOCKER_ENGINE_REF=docker-v${VERSION} \
    GO_VERSION=$GO_VERSION \
    GO_IMAGE=golang:$GO_VERSION \
    REGISTRY=$REGISTRY \
    make "$TARGET"
    
    popd > /dev/null

    # 拷贝产物：根据不同的 TARGET 查找对应的 RPM 目录
    local RPM_SOURCE_DIR="docker-ce-packaging/rpm/rpmbuild/${TARGET}/RPMS/loongarch64"
    
    if [ -d "$RPM_SOURCE_DIR" ]; then
        echo "Copying $TARGET RPMs to $DISTS..."
        cp "$RPM_SOURCE_DIR"/*"$VERSION"*.rpm "$DISTS"/
    else
        echo "Warning: Build output directory $RPM_SOURCE_DIR not found for $TARGET"
        return 1
    fi
}

# --- 执行构建逻辑 ---

TARGETS=("anolis-23") 

for T in "${TARGETS[@]}"; do
    build_target "$T"
done

echo "All builds completed successfully."
