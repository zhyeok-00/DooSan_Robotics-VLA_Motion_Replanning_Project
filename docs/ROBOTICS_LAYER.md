# 로봇 인식·모션 계층

[README로 돌아가기](../README.md)

이 문서는 VLA 판단과 독립적으로 동작하는 로봇 계층의 책임과 검증 범위를 요약합니다.
세부 인터페이스와 파라미터의 단일 참조 문서는 [`src/PACKAGES.md`](../src/PACKAGES.md)입니다.

## 파이프라인

```text
D435i
  ├─ YOLO segmentation ── GraspGenX ── 6-DoF grasp candidates
  └─ octomap / nvblox ───────────────────────────────┐
                                                     ▼
VLA JSON 또는 rqt ── pick_fsm ── MoveIt OMPL / cuMotion ── M0609 + RG2
```

VLA는 대상 클래스와 목적지만 전달합니다. 카메라 좌표, 파지 자세, IK, 궤적, 그리퍼와 안전 상태는
로봇 계층이 소유합니다. 따라서 LLM 지연이나 잘못된 응답이 직접 관절 명령으로 이어지지 않습니다.

## 핵심 패키지

| 패키지 | 책임 |
| --- | --- |
| `cobot_rg2/rg2` | M0609·RG2 bringup, eye-to-hand TF, MoveIt 설정 |
| `graspgenx_perception` | YOLO mask와 depth에서 6-DoF 파지 후보 생성 |
| `pick_fsm` | 승인, 계획, 접근, 파지, 검증, 배치와 복구 상태머신 |
| `cumotion` | cuMotion 요청, nvblox ESDF와 반복 재계획 프로토타입 |
| `voice_processing` | VLA JSON을 로봇 명령으로 변환하는 경계 수신부 |

## 좌표계와 파지

카메라는 D435i 한 대를 eye-to-hand 방식으로 사용합니다. 캘리브레이션 결과 `T_cam2base.npy`에서
`base_link → camera_link` 정적 TF를 생성하며, 플래닝·장애물 프레임은 `base_link`로 통일합니다.
카메라를 옮기면 기존 변환은 무효이므로 재캘리브레이션해야 합니다.

GraspGenX 후보는 점수, 도달 반경, 접근축과 IK 가능 여부로 필터링합니다. 계획 실패 시 차순위
후보로 전환하고 approach, grasp, lift의 3점 경로를 실행 전에 검증합니다.

## Pick FSM

```text
IDLE → PERCEIVE → PLAN → WAIT_APPROVAL
     → APPROACH → DESCEND → CLOSE → VERIFY → LIFT
     → WAIT_PLACE_TARGET → PLACE → RELEASE → HOME
```

- 사람이 승인하기 전에는 모션을 실행하지 않습니다.
- 파지 검증 실패 시 RG2를 다시 좁혀 재시도합니다.
- `SAFE_STOP`은 모션을 중단하되 물체를 임의로 떨어뜨리지 않습니다.
- `/pick/stow`는 종료 전에 물체를 안전하게 내려놓고 홈으로 복귀합니다.
- 상태 전이는 `states.py`의 `TRANSITIONS` 한 곳에서 관리합니다.

## 계획 경로와 검증 범위

| 경로·기능 | 상태 |
| --- | --- |
| MoveIt 2 OMPL pick-and-place 기준선 | 구현, 가상·실기 기록 구분 |
| 상태머신·JSON 경계 순수 로직 | 자동 테스트 |
| nvblox·cuMotion 연결 | 구현 |
| 장애물 없는 반복 재계획·궤적 교체 | 프로토타입 검증 |
| 움직이는 장애물 실기 회피 | **미검증** |

계획 요청 성공만으로 동적 회피가 검증되는 것은 아닙니다. 향후 ESDF 갱신, 재계획 지연, 궤적
이음새, 성공률과 최소 장애물 거리를 같은 실험에서 반복 측정해야 합니다.

## 상세 문서

- [`src/PACKAGES.md`](../src/PACKAGES.md): 패키지, 토픽, 파라미터와 검증 상태
- [`docs/fsm/README.md`](fsm/README.md): 로봇 문서 지도
- [`docs/fsm/vla-bridge-contract.md`](fsm/vla-bridge-contract.md): VLA–FSM JSON 계약
- [`docs/fsm/graspgenx-perception-notes.md`](fsm/graspgenx-perception-notes.md): 파지 인식 설계
- [`docs/fsm/cumotion-experiment-log.md`](fsm/cumotion-experiment-log.md): 재계획 실험 기록
- [`docs/RUNBOOK.md`](RUNBOOK.md): 통합 실행 절차
