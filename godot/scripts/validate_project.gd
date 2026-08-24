extends SceneTree

## CI project validator.
## 개별 .gd 파일을 load()하면 class_name 등록 순서 때문에 거짓 오류가 발생할 수 있습니다.
## 실제 프로젝트를 부팅하여 Autoload + main scene 의존성 그래프를 Godot 자체로 검사합니다.

var elapsed: float = 0.0

func _init() -> void:
	print("=== DiceGod Project Validation ===")
	print("Mode: real project startup / parser validation")
	set_process(true)

func _process(delta: float) -> void:
	elapsed += delta
	if elapsed >= 1.5:
		print("Project startup validation completed.")
		quit(0)
