class_name DiceData
extends Resource

## 주사위의 변하지 않는 면 구성을 정의하는 데이터입니다.
@export var display_name: String = "기본 주사위"
@export var face_values: PackedInt32Array = PackedInt32Array([1, 2, 3, 4, 5, 6])


func is_valid() -> bool:
	return not face_values.is_empty()
