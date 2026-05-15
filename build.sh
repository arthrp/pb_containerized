#!/usr/bin/env bash
set -euo pipefail

IMAGE="${IMAGE:-localhost/pbdev:latest}"
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SRC_FILE="${1:-${SRC_DIR}/src/demo.cpp}"
if [[ ! -f "$SRC_FILE" ]]; then
    echo "Error: source file not found: $SRC_FILE" >&2
    exit 1
fi

NAME="$(basename "${SRC_FILE}" .cpp)"
OUT_DIR="${SRC_DIR}/out"
mkdir -p "${OUT_DIR}"
OUT="${OUT_DIR}/${NAME}"

cid=$(podman create \
    --name "pbdev-build-$$" \
    --platform=linux/amd64 \
    "$IMAGE" \
    -c "cmake -DCMAKE_TOOLCHAIN_FILE=\"\${SDK_BASE}/SDK-\${SDK_ARCH}/share/cmake/arm_conf.cmake\" -DTARGET_NAME=${NAME} . && cmake --build .")

cleanup() { podman rm -f "${cid:-}" >/dev/null 2>&1 || true; }
trap cleanup EXIT

podman cp "$SRC_FILE"               "$cid:/project/${NAME}.cpp"
podman cp "$SRC_DIR/CMakeLists.txt" "$cid:/project/CMakeLists.txt"

podman start -a "$cid"

podman cp "$cid:/project/build/${NAME}" "$OUT"

echo "Built: $OUT"
