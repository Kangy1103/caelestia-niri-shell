#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "${SCRIPT_DIR}")"
BUILD_DIR="${ROOT_DIR}/build"

cmake -S "${ROOT_DIR}" -B "${BUILD_DIR}" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/usr

cmake --build "${BUILD_DIR}" -j "$(nproc)"

echo "Build complete. Run the following to install:"
echo "  sudo cmake --install ${BUILD_DIR}"
