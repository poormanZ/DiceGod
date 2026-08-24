# DiceGod — 로드맵 검증 기록

> 갱신일: 2026-08-25

## 이번 정리에서 확인한 현재 상태

- 기본 6면 심볼 주사위 구조가 코드에 존재합니다.
- 기본 전투는 6개 주사위, 잠금, 1회 리롤, 확정 흐름을 사용합니다.
- Battle은 심볼을 공격/보호막/치료 자원으로 집계합니다.
- Player는 보호막을 먼저 소비하고 남은 피해를 HP에 적용합니다.
- 1280×720 및 Web Export 설정이 유지됩니다.
- GitHub Actions는 Godot 4.7.2 headless import/startup/roadmap validation과 Web export를 수행합니다.

## 이번 리팩토링

- `DiceData`에 기본 면 수/주사위 수 상수를 중앙화했습니다.
- `DiceRuntimeState`에 결과 초기화 책임을 추가했습니다.
- `DiceRoller`에 전체 굴림을 분리하고 null/빈 결과 방어를 강화했습니다.
- `Battle`에서 주사위 굴림과 행동 집계 흐름을 정리했습니다.
- 방패 집계가 실제 Player 보호막으로 적용되도록 전투 흐름을 수정했습니다.
- Player/Ability의 동적 변수에 명시적 타입을 보강했습니다.
- 구형 숫자/빌드 용어가 남아 있는 문서를 현재 심볼 주사위 기준으로 재정렬했습니다.

## 검증 한계

이 대화 환경에는 Godot 실행 바이너리가 없어 로컬 headless 실행을 직접 수행할 수 없습니다. 따라서 최종 검증은 push 후 GitHub Actions의 실제 Godot 4.7.2 실행 결과를 기준으로 합니다.

CI에서 `SCRIPT ERROR`, `Parse Error`, `Cannot infer`, 깨진 리소스 참조가 발생하면 해당 로그를 기준으로 즉시 수정합니다.
