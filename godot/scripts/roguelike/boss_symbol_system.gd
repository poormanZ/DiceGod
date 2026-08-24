class_name BossSymbolSystem
extends RefCounted

## 보스별 전용 심볼과 실제 전투 효과를 관리합니다.
## 플레이어의 6개 기본 심볼과 별개의 ID 영역을 사용합니다.

const FLAME: int = 101
const FROST: int = 102
const PLAGUE: int = 103
const BLOOD: int = 104
const STORM: int = 105
const STONE: int = 106
const FATE: int = 107
const VOID: int = 108

const DATA: Dictionary = {
	FLAME: {"icon": "🔥", "name": "화염", "effect": "burn", "power": 2, "description": "공격 후 추가 화염 피해"},
	FROST: {"icon": "❄️", "name": "빙결", "effect": "frost", "power": 1, "description": "공격 후 플레이어 보호막을 약화"},
	PLAGUE: {"icon": "☠️", "name": "역병", "effect": "plague", "power": 2, "description": "공격 후 지속 피해 표식을 남김"},
	BLOOD: {"icon": "🩸", "name": "혈액", "effect": "drain", "power": 2, "description": "공격 피해의 일부만큼 보스 회복"},
	STORM: {"icon": "⚡", "name": "폭풍", "effect": "storm", "power": 2, "description": "다음 공격에 추가 피해"},
	STONE: {"icon": "🪨", "name": "거암", "effect": "stone", "power": 1, "description": "보스 방어력 강화"},
	FATE: {"icon": "🔮", "name": "운명", "effect": "fate", "power": 1, "description": "플레이어의 다음 행동 피해 감소"},
	VOID: {"icon": "🌑", "name": "공허", "effect": "void", "power": 1, "description": "플레이어 보호막 일부 무시"}
}

static func get_symbol(symbol_id: int) -> Dictionary:
	return DATA.get(symbol_id, {})

static func get_icon(symbol_id: int) -> String:
	return str(get_symbol(symbol_id).get("icon", "❓"))

static func get_name(symbol_id: int) -> String:
	return str(get_symbol(symbol_id).get("name", "알 수 없음"))

static func get_effect(symbol_id: int) -> String:
	return str(get_symbol(symbol_id).get("effect", ""))

static func get_power(symbol_id: int) -> int:
	return int(get_symbol(symbol_id).get("power", 0))
