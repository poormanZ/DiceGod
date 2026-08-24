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

`Battle`은 공통 전투 흐름을 조정합니다. `RunBattle`은 런 전투에 필요한 랜덤 적 생성, 난이도 스케일링, 보스 심볼 효과를 확장합니다.

### Roguelike

- `CombatContentSystem`: 일반/엘리트/보스 콘텐츠 풀
- `BossSymbolSystem`: 보스 전용 심볼과 효과 정의
- `DifficultyScaler`: 런 횟수 기반 적 능력치 스케일링

### State

- `RunStateManager`: 현재 런 전역 상태
- `ProgressionState`: 영구 진행/저장

## 보스 확장 구조

보스는 콘텐츠 풀에서 무작위 선택되고, 선택된 보스 데이터에 전용 심볼 ID/효과/위력이 주입됩니다. `EnemyData`는 이를 보관하고 `RunBattle`이 실제 플레이어 피해/보호막/보스 회복/보스 방어력 등에 적용합니다.

기본 플레이어 심볼 ID(1~6)와 보스 심볼 ID(101+)를 분리하여 두 시스템이 서로의 의미를 오염시키지 않도록 합니다.

## 리팩토링 원칙

- 숫자/심볼 의미를 혼용하지 않습니다.
- `DiceData`의 상수로 기본 주사위 수/면 수를 공유합니다.
- 동적 값은 가능한 한 명시적 타입을 사용합니다.
- 전투에서 동일 계산을 반복하지 않습니다.
- 보호막은 Player가 관리하고 Battle은 필요한 보호막 양만 전달합니다.
- UI 노드는 표시/입력에 집중하고 게임 규칙을 직접 소유하지 않습니다.
- 난이도 계산은 `DifficultyScaler` 한 곳에서 관리합니다.
- 보스 심볼 정의는 `BossSymbolSystem` 한 곳에서 관리합니다.

## 현재 검증

GitHub Actions는 Godot import, startup validation, roadmap validation, Web export를 순서대로 수행합니다. 새 보스/난이도 시스템도 동일한 CI 검증을 통과해야 완료로 간주합니다.
