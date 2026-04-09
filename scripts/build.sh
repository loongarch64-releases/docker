#!/bin/bash
set -euo pipefail

UPSTREAM_OWNER=moby
UPSTREAM_REPO=moby
VERSION="${1}"
echo "   🏢 Org:   ${UPSTREAM_OWNER}"
echo "   📦 Proj:  ${UPSTREAM_REPO}"
echo "   🏷️  Ver:   ${VERSION}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
DISTS="${ROOT_DIR}/dists"
SRCS="${ROOT_DIR}/srcs"

ARCH="loong64"
GO_VERSION="1.25"
DISTS="dists"
SRCS="srcs"
REGISTRY="lcr.loongnix.cn"
TARGET="anolis-23"


mkdir -p "${DISTS}/${VERSION}"

# ==========================================
# 👇 用户自定义构建逻辑 (示例)
# ==========================================

echo "🔧 Compiling ${UPSTREAM_OWNER}/${UPSTREAM_REPO} ${VERSION}..."

PACKAGE_DIR="$(mktemp -d)"
# 1. 准备阶段：安装依赖、下载代码、应用补丁等
prepare()
{
    echo "📦 [Prepare] Setting up build environment..."
    
    # TODO: 在此处添加准备命令
    # 例如：apt-get update && apt-get install -y build-essential
    # 例如：git clone -b ${VERSION} --depth=1 https://github.com/moby/moby ${SRCS}/${VERSION}
    # 例如：patch -p1 < patches/loongarch-fix.patch
    echo "下载 docker-ce-packaging ..."
    git clone -b loongarch64 --depth=1 https://github.com/loongarch64-releases/docker-ce-packaging.git ${PACKAGE_DIR}

    # 获取组建版本信息
    ${SCRIPT_DIR}/get_components_version.sh ${VERSION}
    echo "加载版本信息 "
    source "${ROOT_DIR}/docker_components.txt"
    
    echo "✅ [Prepare] Environment ready."
}

# 2. 编译阶段：核心构建命令
build()
{
    echo "🔨 [Build] Compiling source code..."
    
    # TODO: 在此处添加编译命令
    # 例如：make -j$(nproc) ARCH=loongarch64
    # 例如：cmake -DCMAKE_BUILD_TYPE=Release .. && make
    
    pushd ${PACKAGE_DIR} > /dev/null

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


    echo "✅ [Build] Compilation finished."
}

# 3. 后处理阶段：整理产物、清理临时文件、验证版本
post_build()
{
    echo "📦 [Post-Build] Organizing artifacts..."
    
    # TODO: 在此处添加整理命令
    # 例如：mkdir -p dists && cp binary dist/
    # 例如：strip dist/binary
    
    # 拷贝产物：根据不同的 TARGET 查找对应的 RPM 目录
    local RPM_SOURCE_DIR="${PACKAGE_DIR}/rpm/rpmbuild/${TARGET}/RPMS/loongarch64"
    
    if [ -d "$RPM_SOURCE_DIR" ]; then
        echo "Copying $TARGET RPMs to $DISTS..."
        cp ${RPM_SOURCE_DIR}/*.rpm ${DISTS}/${VERSION}
    else
        echo "Warning: Build output directory ${RPM_SOURCE_DIR} not found for ${TARGET}"
        return 1
    fi
    echo "✅ [Post-Build] Artifacts ready in ./dists."
}

# 主入口
main()
{
    prepare
    build
    post_build
}

main

# ==========================================
# 👆 自定义逻辑结束
# ==========================================

cat > "${DISTS}/${VERSION}/release.txt" <<EOF
Project: ${UPSTREAM_REPO}
Organization: ${UPSTREAM_OWNER}
Version: ${VERSION}
Build Time: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
EOF

echo "✅ Compilation finished."
ls -lh "${DISTS}/${VERSION}"
