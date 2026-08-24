class_name DifficultyScaler
extends RefCounted

## 던전 런 횟수에 따라 적의 기본 능력치를 단계적으로 증가시킵니다.
## run_number 1에서는 배율 1.0이며, 이후 완만하게 증가하고 상한을 둡니다.

static func get_scale(run_number: int) -> float:
	var safe_run: int = maxi(1, run_number)
	return minf(1.0 + float(safe_run - 1) * 0.15, 3.0)

static func get_elite_scale(run_number: int) -> float:
	var safe_run: int = maxi(1, run_number)
	return minf(1.0 + float(safe_run - 1) * 0.20, 3.5)

static func get_boss_scale(run_number: int) -> float:
	var safe_run: int = maxi(1, run_number)
	return minf(1.0 + float(safe_run - 1) * 0.25, 4.0)

static func scale_hp(base_hp: int, run_number: int, tier: String) -> int:
	var multiplier: float = get_scale(run_number)
	if tier == "elite":
		multiplier = get_elite_scale(run_number)
	elif tier == "boss":
		multiplier = get_boss_scale(run_number)
	return maxi(1, ceili(float(base_hp) * multiplier))

static func scale_damage(base_damage: int, run_number: int, tier: String) -> int:
	var multiplier: float = get_scale(run_number)
	if tier == "elite":
		multiplier = get_elite_scale(run_number)
	elif tier == "boss":
		multiplier = get_boss_scale(run_number)
	return maxi(1, ceili(float(base_damage) * (0.85 + multiplier * 0.15)))

static func scale_armor(base_armor: int, run_number: int, tier: String) -> int:
	var multiplier: float = get_scale(run_number)
	if tier == "elite":
		multiplier = get_elite_scale(run_number)
	elif tier == "boss":
		multiplier = get_boss_scale(run_number)
	return maxi(0, floori(float(base_armor) * multiplier))
