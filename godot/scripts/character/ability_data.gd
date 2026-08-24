class_name AbilityData
extends Resource

## 심볼 조합 스킬의 기본 설정입니다.
@export var display_name: String = ""
@export_multiline var description: String = ""

# 공통 조합 보너스
@export var matching_pair_bonus: int = 2
@export var matching_triple_bonus: int = 3

# 심볼별 기본 개성 보너스
@export var sword_heavy_bonus: int = 2
@export var bow_penetration: int = 1
@export var staff_magic_bonus: int = 1
@export var shuriken_extra_hits: int = 1
