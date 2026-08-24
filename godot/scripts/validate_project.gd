extends SceneTree

## Headless CI validator.
## Godot의 GDScript parser/type checker가 프로젝트 전체 스크립트를 로드하도록 하여
## 선언되지 않은 타입/변수/함수, 문법 오류를 빌드 전에 잡습니다.

const ROOT: String = "res://scripts"
var failures: int = 0
var scanned: int = 0

func _init() -> void:
	_scan(ROOT)
	print("=== DiceGod Project Validation ===")
	print("Scripts scanned: %d" % scanned)
	print("Parser/type failures: %d" % failures)
	if failures > 0:
		quit(1)
	else:
		print("PASS")
		quit(0)

func _scan(path: String) -> void:
	var directory: DirAccess = DirAccess.open(path)
	if directory == null:
		_failures_add("Directory not found: %s" % path)
		return
	directory.list_dir_begin()
	var name: String = directory.get_next()
	while not name.is_empty():
		if name != "." and name != "..":
			var full_path: String = path.path_join(name)
			if directory.current_is_dir():
				_scan(full_path)
			elif name.ends_with(".gd") and not name.ends_with("validate_project.gd") and not name.ends_with("validate_gd.gd"):
				_validate(full_path)
			name = directory.get_next()
	directory.list_dir_end()

func _validate(path: String) -> void:
	scanned += 1
	var script: GDScript = load(path) as GDScript
	if script == null:
		_failures_add("Failed to parse/load: %s" % path)

func _failures_add(message: String) -> void:
	failures += 1
	push_error(message)
