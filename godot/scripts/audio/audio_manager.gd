extends Node

var _last_sfx_time: Dictionary = {}
const SFX_COOLDOWN := 0.04

func play_sfx(sound_name: String) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if _last_sfx_time.has(sound_name) and now - float(_last_sfx_time[sound_name]) < SFX_COOLDOWN:
		return
	_last_sfx_time[sound_name] = now

	match sound_name:
		"roll": ProceduralSfx.play_roll(self)
		"lock": ProceduralSfx.play_lock(self)
		"confirm": ProceduralSfx.play_confirm(self)
		"attack": ProceduralSfx.play_attack(self)
		"hit": ProceduralSfx.play_hit(self)
		"heal": ProceduralSfx.play_heal(self)
		"victory": ProceduralSfx.play_victory(self)
		"defeat": ProceduralSfx.play_defeat(self)
		_: return

func play_roll() -> void:
	play_sfx("roll")

func play_lock() -> void:
	play_sfx("lock")

func play_confirm() -> void:
	play_sfx("confirm")

func play_attack() -> void:
	play_sfx("attack")

func play_hit() -> void:
	play_sfx("hit")

func play_heal() -> void:
	play_sfx("heal")

func play_victory() -> void:
	play_sfx("victory")

func play_defeat() -> void:
	play_sfx("defeat")
