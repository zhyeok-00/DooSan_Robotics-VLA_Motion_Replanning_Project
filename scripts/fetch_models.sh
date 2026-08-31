#!/usr/bin/env bash
# 재배포하지 않는 Ultralytics 공식 모델을 각 패키지 실행 경로에 내려받는다.
set -euo pipefail

cd "$(dirname "$0")/.."
WS="$PWD"
VENV_PYTHON="$WS/.venv/bin/python3"

if [ ! -x "$VENV_PYTHON" ]; then
  echo "오류: .venv가 없습니다. README의 Python 환경 구성을 먼저 실행하세요." >&2
  exit 1
fi

TMP_DIR=$(mktemp -d)
trap 'rm -rf -- "$TMP_DIR"' EXIT

(
  cd "$TMP_DIR"
  "$VENV_PYTHON" -c 'from ultralytics import YOLO; YOLO("yolo26s-seg.pt"); YOLO("yolo11n-seg.pt")'
)

install -D -m 0644 "$TMP_DIR/yolo26s-seg.pt" \
  "$WS/src/vla_system/models/yolo26s-seg.pt"
install -D -m 0644 "$TMP_DIR/yolo11n-seg.pt" \
  "$WS/src/object_detection/resource/yolo11n-seg.pt"

echo "공식 모델 설치 완료:"
echo "  src/vla_system/models/yolo26s-seg.pt"
echo "  src/object_detection/resource/yolo11n-seg.pt"
