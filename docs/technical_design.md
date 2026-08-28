# DiceGod — 기술 설계

> 기준일: 2026-08-28

## 환경

- Godot 4.7.2
- GDScript
- 2D
- GL Compatibility
- Web Export / GitHub Pages
- 1280×720 기준 Canvas Items stretch

## 핵심 아키텍처

### Dice

- `DiceData`: 정적 주사위 정의
- `DiceRuntimeState`: 현재 굴림 결과/잠금 상태
- `DiceRoller`: 굴림/리롤/확정 상태
- `DiceRollPanel`: 주사위 UI와 입력

### Run State

`RunStateManager`는 현재 런의 모든 일시적 진행을 소유합니다.

- 현재 HP/골드
- 현재 6개 주사위 면 구성
- 런 중 면 강화
- 런 장비/버프
- 런 시너지
- 던전/이벤트/보스 진행

런 종료 시 이 데이터는 다음 런의 전투력으로 직접 승계하지 않습니다.

### Meta State

`ProgressionState`는 영구 진행만 소유합니다.

- 메타 재화
- 발견/해금 기록
- 주사위 타입 해금
- 심볼 효과 해금
- 이벤트/보스 해금
- 대장간 옵션 해금
- 유산 해금
- 통계

**완성된 런 주사위 면 구성은 영구 전투 데이터로 저장하지 않습니다.** 기존 `persistent_dice_faces` 계층은 유산/해금 데이터로 전환하는 것을 원칙으로 합니다.

## 성장 계층

```text
영구 해금
  ↓
유산/시작 선택
  ↓
런 시작
  ↓
6개 기본 주사위
  ↓
면 교체/강화/확률/시너지
  ↓
보스
  ↓
사망 또는 클리어
  ↓
기록/해금/유산
  ↓
다음 런
```

## 데이터 경계 원칙

런 데이터와 메타 데이터는 저장 경계를 명확히 분리합니다.

- 런 전투력 → `RunStateManager`
- 영구 해금/기록 → `ProgressionState`
- 주사위 정적 정의 → `DiceData`
- 보스 정의 → `BossSymbolSystem`
- 난이도 → `DifficultyScaler`

UI는 이 상태를 표시하고 입력을 전달하지만 게임 규칙을 직접 소유하지 않습니다.

## 보스 확장 구조

보스는 콘텐츠 풀에서 선택되고 전용 심볼/행동 패턴을 주입합니다. 기본 플레이어 심볼 ID(1~6)와 보스 심볼 ID(101+)는 계속 분리합니다.

## 밸런스 안전장치

- 영구 공격력/HP 직접 증가 최소화
- 영구 완성 주사위 금지
- 유산으로 완성형 빌드 제공 금지
- 런 중 강력한 보상에는 기회비용 부여
- 메타 성장은 선택지 확대 중심

## 검증

GitHub Actions에서 import/startup/roadmap/Web export 검증을 유지합니다. 향후에는 저장/불러오기, 한 런 전체 흐름, 좁은 화면, 메타 초기화 경계까지 회귀 테스트에 포함합니다.
