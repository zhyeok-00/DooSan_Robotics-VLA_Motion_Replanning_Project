# 공개 전 점검

[README로 돌아가기](../README.md)

## 적용 완료

- 빌드·설치·로그·가상환경·캐시·실행 출력 ignore
- `.env` ignore 및 안전한 `.env.example` 제공
- IDE 설정과 C/C++ 인덱스 데이터베이스 ignore
- 외부 Doosan·OnRobot·Isaac ROS·GraspGenX 저장소 제외 및 복원 스크립트 제공
- README 링크를 저장소 상대경로로 변경
- 실행 스크립트의 개인 홈 경로를 저장소 기준 경로로 변경
- 구현·프로토타입·실기 미검증 범위를 구분

## 자동 점검

```bash
git status --short
git ls-files | grep -E '(^|/)(build|install|log|\.venv|\.pytest_cache|__pycache__)/'
git grep -nE 'sk-[A-Za-z0-9_-]{20,}|ghp_[A-Za-z0-9]{20,}|BEGIN .*PRIVATE KEY'
git ls-files -z | xargs -0 du -h | sort -h | tail
```

## 모델 가중치

모델 가중치는 Git에서 제외하고 `scripts/fetch_models.sh`로 Ultralytics 공식 제공처에서 받습니다.
출처를 확인할 수 없는 `yolov8n_tools_0122.pt`는 공개 설치 대상에서 제외했습니다. 이미 과거 커밋에
들어간 가중치를 공개 이력에서도 제거하려면 별도의 history rewrite와 팀 합의가 필요합니다.

## 공개 직전 수동 확인

- 팀원 이름·기여 범위·연락처 공개 동의
- 실기 성공 횟수와 성능 수치를 원본 로그로 확인
- 캘리브레이션 파일의 개인·장소 정보 확인
- 이미지·영상의 얼굴, 명찰, 알림과 API 키 노출 확인
- 외부 프로젝트별 고정 commit과 라이선스 기록
- clean clone 환경에서 설치 절차 재현

과거 실험 문서에는 당시 머신의 절대경로가 근거로 남아 있을 수 있습니다. 실행 스크립트와 정본
문서는 환경 독립적으로 유지하고, 기록 문서의 경로는 역사적 정보로 구분합니다.
