class_name DiceData
extends Resource

## DiceGod의 기본 행동 심볼 주사위 데이터입니다.
## 각 주사위는 현재 6개의 기본 심볼 면을 사용합니다.
const SWORD: int = 1
const BOW: int = 2
const STAFF: int = 3
const SHURIKEN: int = 4
const SHIELD: int = 5
const HEAL: int = 6

const FACE_COUNT: int = 6
const STARTING_DICE_COUNT: int = 6
const DEFAULT_FACES: PackedInt32Array = PackedInt32Array([SWORD, BOW, STAFF, SHURIKEN, SHIELD, HEAL])

const SYMBOLS: Dictionary = {
	SWORD: "⚔️",
	BOW: "🏹",
	STAFF: "🔮",
	SHURIKEN: "🗡️",
	SHIELD: "🛡️",
	HEAL: "❤️"
}
const NAMES: Dictionary = {
	SWORD: "검",
	BOW: "활",
	STAFF: "지팡이",
	SHURIKEN: "표창",
	SHIELD: "방패",
	HEAL: "힐"
}

@export var display_name: String = "기본 심볼 주사위"
@export_multiline var description: String = "⚔️ 🏹 🔮 🗡️ 🛡️ ❤️ 6개의 행동 심볼이 하나씩 들어 있는 기본 주사위"
@export var face_values: PackedInt32Array = DEFAULT_FACES

func is_valid() -> bool:
	if face_values.size() != FACE_COUNT:
		return false
	for face: int in face_values:
		if not SYMBOLS.has(face):
			return false
	return true

static func symbol_for(value: int) -> String:
	return str(SYMBOLS.get(value, "?"))

static func name_for(value: int) -> String:
	return str(NAMES.get(value, "알 수 없음"))

static func is_attack(value: int) -> bool:
	return value == SWORD or value == BOW or value == STAFF or value == SHURIKEN

static func is_defense(value: int) -> bool:
	return value == SHIELD

static func is_heal(value: int) -> bool:
	return value == HEAL

static func is_base_symbol(value: int) -> bool:
	return SYMBOLS.has(value) and value >= SWORD and value <= HEAL
