# DiceGod — 기술 설계

## 환경

- Godot 4.7.2
- GDScript
- 2D
- GL Compatibility
- Web Export / GitHub Pages
- 1280×720 기준 Canvas Items stretch

## 핵심 구조

### Dice

- `DiceData`: 정적 6면 심볼 정의
- `DiceRuntimeState`: 개별 주사위 결과/잠금
- `DiceRoller`: 굴림/리롤/확정 상태
- `DiceRollPanel`: UI 표시와 입력

### Battle

`Battle`은 전투 흐름을 조정하고, 주사위 계산은 Dice 계층, 플레이어 피해/회복은 Player가 담당합니다.

### State

- `RunStateManager`: 현재 런 전역 상태
- `ProgressionState`: 영구 진행/저장

## 리팩토링 원칙

- 숫자/심볼 의미를 혼용하지 않습니다.
- `DiceData`의 상수로 기본 주사위 수/면 수를 공유합니다.
- 동적 값은 가능한 한 명시적 타입을 사용합니다.
- 전투에서 동일 계산을 반복하지 않습니다.
- 보호막은 Player가 관리하고 Battle은 필요한 보호막 양만 전달합니다.
- UI 노드는 표시/입력에 집중하고 게임 규칙을 직접 소유하지 않습니다.

## 현재 검증

GitHub Actions는 Godot import, startup validation, roadmap validation, Web export를 순서대로 수행합니다. 로컬 환경에 Godot 실행 파일이 없더라도 CI에서 동일한 프로젝트를 headless 검증할 수 있도록 유지합니다.
