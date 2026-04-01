#!/bin/bash
set -euo pipefail

DOCKER_VERSION="${1}" # 提供默认版本以防未传参

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
OUTPUT_FILE="${ROOT_DIR}/docker_components.txt"

echo "正在获取 Docker ${DOCKER_VERSION} 的组件版本信息..."

# 创建临时目录
TMP_DIR=$(mktemp -d)
echo "使用临时目录: ${TMP_DIR}"
trap 'rm -rf ${TMP_DIR}' EXIT # 确保脚本退出时清理临时文件

pushd ${TMP_DIR} > /dev/null

# 1. 下载通用配置文件 (获取 Go 版本)
wget -q https://github.com/docker/docker-ce-packaging/raw/master/common.mk

# 2. 下载并解压 Docker 静态包
wget -q https://download.docker.com/linux/static/stable/$(uname -m)/docker-${DOCKER_VERSION#*v}.tgz
tar -xf docker-${DOCKER_VERSION#*v}.tgz

# 3. 提取各组件版本
GO_VERSION=$(grep '^GO_VERSION' common.mk | awk -F ":=" '{print $2}' | xargs)
RUNC_VERSION=$(./docker/runc --version | grep "runc version" | awk '{print $3}')
[[ $RUNC_VERSION != v* ]] && RUNC_VERSION="v$RUNC_VERSION"

CONTAINERD_VERSION=$(./docker/containerd --version | awk '{print $3}')
[[ $CONTAINERD_VERSION != v* ]] && CONTAINERD_VERSION="v$CONTAINERD_VERSION"

TINI_VERSION=$(./docker/docker-init --version | awk '{print $3}')
[[ $TINI_VERSION != v* ]] && TINI_VERSION="v$TINI_VERSION"

popd > /dev/null

# 4. 将结果写入当前目录文件
cat > ${OUTPUT_FILE} << EOF
# Docker Component Versions for ${DOCKER_VERSION}
# Auto-generated. Source this file in your bash script.
# Usage: source ./docker_versions.env

DOCKER_VERSION="${DOCKER_VERSION}"
GO_VERSION="${GO_VERSION}"
RUNC_VERSION="${RUNC_VERSION}"
CONTAINERD_VERSION="${CONTAINERD_VERSION}"
TINI_VERSION="${TINI_VERSION}"
EOF

echo "完成！版本信息已保存至: ${OUTPUT_FILE}"
echo ""
cat ${OUTPUT_FILE}
