# DiceGod

DiceGod은 **행동 심볼 주사위**를 중심으로 운과 전략을 결합하는 2D 턴제 로그라이크 던전 RPG입니다.

## 현재 기준 사양

- Godot 4.7.2
- GDScript / 2D / GL Compatibility
- 기준 해상도 1280×720, Canvas Items stretch
- Web Export + GitHub Pages 배포
- 기본 주사위 6개
- 각 주사위 6면: ⚔️ 검 / 🏹 활 / 🔮 지팡이 / 🗡️ 표창 / 🛡️ 방패 / ❤️ 힐
- 주사위 개별 잠금
- 턴당 리롤 1회
- 결과 확정 후 공격/방어/치료 자원 집계
- 전투 전 빌드 선택 화면 없음

## 현재 전투 흐름

전투 시작 → 6개 주사위 굴림 → 필요한 주사위 잠금 → 1회 리롤 → 결과 확정 → 치료/보호막 적용 → 공격/행동 → 적 행동 → 다음 턴

기본 자원은 심볼 개수로 계산합니다.

- ⚔️🏹🔮🗡️ → 공격 +1
- 🛡️ → 보호막 +1
- ❤️ → HP +1

동일 방어/치료 심볼 2개 이상은 현재 프로토타입에서 추가 자원으로 계산되며, 공격 심볼 쌍/트리플 스킬은 임시 프로토타입 규칙입니다. 이 규칙은 향후 심볼 고유 효과 설계에서 교체할 수 있습니다.

## 코드 구조

- `scripts/dice/` — 주사위 데이터, 런타임 상태, 굴림
- `scripts/battle/` — 전투 흐름과 적 행동
- `scripts/character/` — 플레이어/스킬 데이터와 런타임 객체
- `scripts/dungeon/` — 던전 노드와 이벤트 화면
- `scripts/roguelike/` — 상점/대장간/환생 등 확장 시스템
- `scripts/run_state.gd` — 현재 런 전역 상태
- `scripts/progression_state.gd` — 영구 성장/저장 상태

핵심 원칙은 **데이터(Resource)와 전투 런타임 로직을 분리하고, 주사위 계산을 `DiceData`/`DiceRoller`에 모으는 것**입니다.

### 리팩토링 기준

- 주사위 개수/면 수/기본 심볼 ID의 기준값은 `DiceData`에서 관리합니다.
- `PackedInt32Array`와 같은 런타임 생성 객체는 `const`로 선언하지 않습니다.
- `STARTING_DICE_COUNT` 같은 상수는 반드시 소유 클래스의 이름을 붙여 참조합니다. 예: `DiceData.STARTING_DICE_COUNT`.
- `RunState`는 런 진행 상태를 담당하고, 주사위 규격 자체의 중복 상수 정의는 만들지 않습니다.
- CI에서는 개별 `.gd` 파일을 독립적으로 로드하지 않고 실제 프로젝트 startup/import를 통해 의존성까지 검사합니다.

## 문서

- `docs/game_design.md` — 전체 게임 방향
- `docs/dice_design.md` — 심볼 주사위 규칙
- `docs/combat_design.md` — 현재 전투 규칙
- `docs/character_design.md` — 캐릭터/스킬/장비
- `docs/dungeon_design.md` — 던전과 이벤트
- `docs/game_progression.md` — 실제 런 진행
- `docs/progression_design.md` — 성장 방향
- `docs/roguelike_design.md` — 향후 로그라이크 확장안
- `docs/divine_symbols.md` — 신성 심볼 확장안
- `docs/forge_reincarnation_ui.md` — 대장간/환생 UI 방향
- `docs/ui_design.md` — 화면/반응형 UI
- `docs/technical_design.md` — 코드 구조와 검증
- `docs/roadmap.md` — 개발 순서와 완료 상태
- `docs/roadmap_completion.md` — 현재 기준 검증 기록

문서에는 **현재 구현**과 **향후 설계**를 명확히 구분합니다.
