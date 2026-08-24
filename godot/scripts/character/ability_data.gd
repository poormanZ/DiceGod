class_name AbilityData
extends Resource

## 심볼 조합 스킬의 기본 설정입니다.
@export var display_name: String = ""
@export_multiline var description: String = ""

# HP 10 / 주사위 6개 기준 일반 전투 3~5턴을 목표로 한 초기 밸런스입니다.
@export var matching_pair_bonus: int = 1
@export var matching_triple_bonus: int = 2

# 공격 심볼 개성
@export var sword_heavy_bonus: int = 1
@export var bow_penetration: int = 1
@export var staff_magic_bonus: int = 1
@export var shuriken_extra_hits: int = 1

# 방어/지원 심볼 개성
@export var shield_protection_bonus: int = 1
@export var heal_overheal_shield: int = 1
@export var heal_pair_bonus: int = 1
