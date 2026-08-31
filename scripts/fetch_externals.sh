#!/usr/bin/env bash
# 이 저장소에 안 들어간 외부 의존물을 받아온다. 새 PC 에서 **한 번** 실행한다.
#
#   ./scripts/fetch_externals.sh
#
# 왜 저장소에 안 넣었나 — 전부 남의 코드이고 합쳐서 20GB 가 넘는다.
#   GraspGenX      11G  (그 중 .venv 6.6G · ext 3.8G 는 uv 가 다시 만든다)
#   isaac_ros_*    4.8G
#   doosan-robot2  273M
# 우리가 쓴 코드는 40MB 뿐이라, 받아오는 쪽이 훨씬 싸다.
#
# 🔴 GPU·CUDA 가 있는 PC 여야 한다. GraspGenX 와 cuMotion 은 CPU 로 안 돈다.

set -euo pipefail
cd "$(dirname "$0")/.."
WS="$PWD"

say()  { printf '\n\033[1;36m== %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m!! %s\033[0m\n' "$*" >&2; }

clone_pinned() {              # <경로> <URL> <commit SHA>
  local dest="$1" url="$2" revision="$3" current
  if [ -d "$dest/.git" ]; then
    current=$(git -C "$dest" rev-parse HEAD)
    if [ "$current" != "$revision" ]; then
      warn "$dest 버전 불일치: 현재 $current, 요구 $revision"
      return 1
    fi
    echo "  이미 있음  $dest ($revision)"
    return 0
  fi
  mkdir -p "$(dirname "$dest")"
  git init -q "$dest"
  git -C "$dest" remote add origin "$url"
  git -C "$dest" fetch --depth 1 origin "$revision"
  git -C "$dest" checkout -q --detach FETCH_HEAD
}

# 2026-08-31에 고정한 재현 가능한 외부 버전. 변경할 때는 GPU/실기 검증 후 SHA를 함께 갱신한다.
DOOSAN_REV=ec9242546ec6202835900dbcd8498e2daabfa6a6
ONROBOT_REV=c6e390313e831a2e54a0ad5894b2911cc360a16a
GRASPGENX_REV=b9429097728cb1c430dd78b92edf17ba318aad03
ISAAC_COMMON_REV=d068d425efbb285fb0e6c0a82203910503fe1957
ISAAC_CUMOTION_REV=6baafc276225742ce04755531c8587ecc3c2089c
ISAAC_NVBLOX_REV=4e5732317ff10bb875b7c2f812ad9452f122bbab
ISAAC_NITROS_REV=746f53fee9bee4e34258299dbe40871e50b79ded

# ── 1. 로봇 드라이버 ─────────────────────────────────────────────────────
# ⚠️ 개발 당시에는 팀 개인 저장소 안에 들어 있던 것을 썼다. 아래는 공개 upstream 이라
#    **버전이 다르면 서비스 이름·메시지(dsr_msgs2)가 갈릴 수 있다.**
say "1/3  로봇 드라이버 (Doosan M0609 · OnRobot RG2)"
clone_pinned "$WS/src/cobot_rg2/doosan-robot2" \
  "https://github.com/DoosanRobotics/doosan-robot2.git" "$DOOSAN_REV"
clone_pinned "$WS/src/cobot_rg2/onrobot-ros2" \
  "https://github.com/ABC-iRobotics/onrobot-ros2.git" "$ONROBOT_REV" \
  || warn "onrobot-ros2 실패 — 그리퍼 없이도 MoveIt 검증까지는 된다"

# ── 2. GraspGenX ────────────────────────────────────────────────────────
say "2/3  GraspGenX (NVlabs)"
clone_pinned "$WS/isaac_ros-dev/src/GraspGenX" \
  "https://github.com/NVlabs/GraspGenX.git" "$GRASPGENX_REV"
echo "  의존성은 GraspGenX 자체 절차(uv sync)를 따른다."
echo "  그리퍼 메시(assets/, 158M)도 그 저장소가 갖고 있다."

# ── 3. Isaac ROS ────────────────────────────────────────────────────────
# 호스트에 직접 설치하지 않는다 — isaac_ros_common 의 run_dev.sh 가 컨테이너를 띄우고
# 그 안에서 빌드한다.
say "3/3  Isaac ROS (cuMotion · nvblox)"
clone_pinned "$WS/isaac_ros-dev/src/isaac_ros_common" \
  "https://github.com/NVIDIA-ISAAC-ROS/isaac_ros_common.git" "$ISAAC_COMMON_REV"
clone_pinned "$WS/isaac_ros-dev/src/isaac_ros_cumotion" \
  "https://github.com/NVIDIA-ISAAC-ROS/isaac_ros_cumotion.git" "$ISAAC_CUMOTION_REV"
clone_pinned "$WS/isaac_ros-dev/src/isaac_ros_nvblox" \
  "https://github.com/NVIDIA-ISAAC-ROS/isaac_ros_nvblox.git" "$ISAAC_NVBLOX_REV"
clone_pinned "$WS/isaac_ros-dev/src/isaac_ros_nitros" \
  "https://github.com/NVIDIA-ISAAC-ROS/isaac_ros_nitros.git" "$ISAAC_NITROS_REV"

# ── 확인 ────────────────────────────────────────────────────────────────
say "확인"
missing=0
for p in src/cobot_rg2/doosan-robot2 isaac_ros-dev/src/GraspGenX \
         isaac_ros-dev/src/isaac_ros_common isaac_ros-dev/src/isaac_ros_cumotion; do
  if [ -d "$WS/$p" ]; then echo "  OK    $p"; else echo "  없음  $p"; missing=1; fi
done
[ "$missing" = 1 ] && { warn "빠진 게 있다. 손으로 채운 뒤 다시 실행할 것."; exit 1; }
say "완료 — 다음은 README의 다음 설치 단계"
