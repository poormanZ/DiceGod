extends Node

var _last_sfx_time: Dictionary = {}
const SFX_COOLDOWN := 0.04

# 현재는 외부 음원 파일 없이 동작하는 안전한 효과음 인터페이스입니다.
# 실제 .wav/.ogg 리소스가 추가되면 SOUND_LIBRARY에 연결합니다.
const SOUND_LIBRARY := {
	"roll": "",
	"lock": "",
	"confirm": "",
	"attack": "",
	"hit": "",
	"heal": "",
	"victory": "",
	"defeat": "",
}

func play_sfx(sound_name: String) -> void:
	if not SOUND_LIBRARY.has(sound_name):
		return
	var sound_path: String = SOUND_LIBRARY[sound_name]
	if sound_path.is_empty():
		return
	var stream := load(sound_path) as AudioStream
	if stream == null:
		return
	var now := Time.get_ticks_msec() / 1000.0
	if _last_sfx_time.has(sound_name) and now - float(_last_sfx_time[sound_name]) < SFX_COOLDOWN:
		return
	_last_sfx_time[sound_name] = now
	var player := AudioStreamPlayer.new()
	player.stream = stream
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()

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
