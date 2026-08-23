class_name ProceduralSfx
extends RefCounted

# 외부 음원 파일 없이 기본적인 UI/전투 효과음을 생성합니다.
# AudioStreamGenerator를 사용하므로 저작권 음원 없이 프로토타입에서 사용할 수 있습니다.

static func create_tone(frequency: float, duration: float, volume: float = 0.12) -> AudioStreamGenerator:
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = 22050
	stream.buffer_length = maxf(duration + 0.05, 0.1)
	return stream

static func tone_player(parent: Node, frequency: float, duration: float, volume: float = 0.12) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = create_tone(frequency, duration, volume)
	parent.add_child(player)
	return player
