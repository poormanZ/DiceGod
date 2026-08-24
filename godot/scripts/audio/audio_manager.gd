extends Node

var _last_sfx_time: Dictionary = {}
const SFX_COOLDOWN: float = 0.04

## 현재 빌드에서는 외부/절차 생성 SFX 리소스를 사용하지 않습니다.
## 호출 API는 유지하여 전투 코드가 오디오 구현과 결합되지 않도록 합니다.
func play_sfx(sound_name: String) -> void:
	var now: float = float(Time.get_ticks_msec()) / 1000.0
	if _last_sfx_time.has(sound_name) and now - float(_last_sfx_time[sound_name]) < SFX_COOLDOWN:
		return
	_last_sfx_time[sound_name] = now

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
