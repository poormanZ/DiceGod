# DiceGod — 기술 설계

## 1. 기술

- Godot 4.x
- GDScript
- 2D
- Compatibility 렌더러
- 웹 배포를 주요 목표로 함

## 2. 권장 구조

### Core

담당:

- 게임 상태
- 런 상태
- 향후 저장 데이터

### Dice

담당:

- 주사위 데이터
- 주사위 굴림
- 잠금
- 리롤
- 결과 처리

### Battle

담당:

- 턴 상태
- 플레이어 행동 단계
- 적 행동
- 피해 계산
- 승리/패배

### Character

담당:

- 플레이어 데이터
- 스킬
- 장비

### Dungeon

담당:

- 던전 지도
- 던전 노드
- 보상
- 전투 연결

## 3. 데이터 중심 설계

정적인 게임 콘텐츠는 가능한 한 Godot Resource 기반으로 관리합니다.

예:

- DiceData
- AbilityData
- EquipmentData
- EnemyData
- CharacterData

게임 시스템은 각각의 데이터를 사용하고, 콘텐츠를 코드에 지나치게 하드코딩하지 않습니다.

## 4. 기본 폴더

scenes/
scripts/
resources/
assets/

각 시스템은 가능한 한 책임에 따라 분리합니다.

## 5. 첫 번째 프로토타입

첫 번째 구현은 의도적으로 단순하게 만듭니다.

하나의 전투 씬만으로 충분합니다.

게임 플레이가 검증되기 전에 복잡한 전역 아키텍처를 만들지 않습니다.
