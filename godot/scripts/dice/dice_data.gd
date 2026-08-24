class_name DiceData
extends Resource

## DiceGod의 주사위 면을 정의합니다.
## 기본 심볼은 1~6, 신성 심볼은 101~108을 사용합니다.
const SWORD: int = 1
const BOW: int = 2
const STAFF: int = 3
const SHURIKEN: int = 4
const SHIELD: int = 5
const HEAL: int = 6
const DIVINE_GOLD: int = 101
const DIVINE_CRITICAL: int = 102
const DIVINE_FORESIGHT: int = 103
const DIVINE_LIFE: int = 104
const DIVINE_BERSERK: int = 105
const DIVINE_SANCTUARY: int = 106
const DIVINE_FATE: int = 107
const DIVINE_DEATH: int = 108

const SYMBOLS: Dictionary = {
	SWORD: "⚔️", BOW: "🏹", STAFF: "🪄", SHURIKEN: "✦", SHIELD: "🛡️", HEAL: "✚",
	DIVINE_GOLD: "💰", DIVINE_CRITICAL: "💥", DIVINE_FORESIGHT: "🔮", DIVINE_LIFE: "❤️",
	DIVINE_BERSERK: "⚡", DIVINE_SANCTUARY: "🛡️✦", DIVINE_FATE: "⭐", DIVINE_DEATH: "☠️"
}
const NAMES: Dictionary = {
	SWORD: "검", BOW: "활", STAFF: "지팡이", SHURIKEN: "표창", SHIELD: "방패", HEAL: "힐",
	DIVINE_GOLD: "황금", DIVINE_CRITICAL: "크리티컬", DIVINE_FORESIGHT: "예지", DIVINE_LIFE: "생명",
	DIVINE_BERSERK: "광전", DIVINE_SANCTUARY: "성역", DIVINE_FATE: "운명", DIVINE_DEATH: "사신"
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
	return str(SYMBOLS.get(value, "?"))

static func name_for(value: int) -> String:
	return str(NAMES.get(value, "알 수 없음"))

static func is_divine(value: int) -> bool:
	return value >= DIVINE_GOLD and value <= DIVINE_DEATH

static func divine_symbol_id(value: int) -> String:
	match value:
		DIVINE_GOLD: return "gold"
		DIVINE_CRITICAL: return "critical"
		DIVINE_FORESIGHT: return "foresight"
		DIVINE_LIFE: return "life"
		DIVINE_BERSERK: return "berserk"
		DIVINE_SANCTUARY: return "sanctuary"
		DIVINE_FATE: return "fate"
		DIVINE_DEATH: return "death"
	return ""

static func is_attack(value: int) -> bool:
	return value == SWORD or value == BOW or value == STAFF or value == SHURIKEN or value == DIVINE_CRITICAL or value == DIVINE_BERSERK or value == DIVINE_DEATH

static func is_defense(value: int) -> bool:
	return value == SHIELD or value == DIVINE_SANCTUARY

static func is_heal(value: int) -> bool:
	return value == HEAL or value == DIVINE_LIFE
