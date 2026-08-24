class_name AbilityData
extends Resource

## 심볼 조합 스킬의 기본 설정입니다.
@export var display_name: String = ""
@export_multiline var description: String = ""

# 같은 공격 심볼 2개 / 3개 이상을 만들었을 때의 추가 공격력입니다.
@export var matching_pair_bonus: int = 2
@export var matching_triple_bonus: int = 3
