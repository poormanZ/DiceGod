class_name DiceData
extends Resource

## DiceGod의 주사위 면을 정의합니다.
## 숫자 1~6은 더 이상 수치가 아니라 행동 심볼 ID입니다.
const SWORD: int = 1
const BOW: int = 2
const STAFF: int = 3
const SHURIKEN: int = 4
const SHIELD: int = 5
const HEAL: int = 6

const SYMBOLS: Dictionary = {
	SWORD: "⚔️",
	BOW: "🏹",
	STAFF: "🪄",
	SHURIKEN: "✦",
	SHIELD: "🛡️",
	HEAL: "✚",
}

const NAMES: Dictionary = {
	SWORD: "검",
	BOW: "활",
	STAFF: "지팡이",
	SHURIKEN: "표창",
	SHIELD: "방패",
	HEAL: "힐",
}

@export var display_name: String = "기본 주사위"
@export_multiline var description: String = "공격·방어·치료 심볼이 섞인 기본 행동 주사위"
@export var face_values: PackedInt32Array = PackedInt32Array([SWORD, BOW, STAFF, SHURIKEN, SHIELD, HEAL])

func is_valid() -> bool:
	if face_values.is_empty():
		return false
	for face in face_values:
		if not SYMBOLS.has(face):
			return false
	return true

static func symbol_for(value: int) -> String:
	return SYMBOLS.get(value, "?")

static func name_for(value: int) -> String:
	return NAMES.get(value, "알 수 없음")

static func is_attack(value: int) -> bool:
	return value == SWORD or value == BOW or value == STAFF or value == SHURIKEN

static func is_defense(value: int) -> bool:
	return value == SHIELD

static func is_heal(value: int) -> bool:
	return value == HEAL
