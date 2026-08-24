@tool
extends EditorScript

## DiceGod GDScript 정적 검증 도구
## 목적: 선언되지 않은 변수/함수/타입을 Godot parser 단계에서 최대한 빨리 발견하고
## 프로젝트 전체를 반복적으로 검사할 수 있도록 합니다.
##
## 사용법:
## Godot Editor > FileSystem에서 이 파일 선택 > 우클릭 > Run
## 또는 CI에서는 scripts/validate_project.gd를 사용하세요.

const SCRIPT_ROOT: String = "res://scripts"

func _run() -> void:
	var errors: Array[String] = []
	var warnings: Array[String] = []
	_scan_directory(SCRIPT_ROOT, errors, warnings)
	print("=== DiceGod GDScript Validation ===")
	print("Scanned: %s" % SCRIPT_ROOT)
	print("Errors: %d" % errors.size())
	print("Warnings: %d" % warnings.size())
	for error_text in errors:
		push_error(error_text)
	for warning_text in warnings:
		push_warning(warning_text)
	if errors.is_empty():
		print("PASS: no static validation errors found.")

func _scan_directory(path: String, errors: Array[String], warnings: Array[String]) -> void:
	var directory: DirAccess = DirAccess.open(path)
	if directory == null:
		errors.append("Directory not found: %s" % path)
		return
	directory.list_dir_begin()
	var name: String = directory.get_next()
	while not name.is_empty():
		if name == "." or name == "..":
			name = directory.get_next()
			continue
		var full_path: String = path.path_join(name)
		if directory.current_is_dir():
			_scan_directory(full_path, errors, warnings)
		elif name.ends_with(".gd"):
			_validate_script(full_path, errors, warnings)
		name = directory.get_next()
	directory.list_dir_end()

func _validate_script(path: String, errors: Array[String], warnings: Array[String]) -> void:
	var script: GDScript = load(path) as GDScript
	if script == null:
		errors.append("Could not load GDScript: %s" % path)
		return
	var source: String = script.source_code
	if source.is_empty():
		return
	# Godot의 실제 parser/type checker가 잡는 오류는 load() 단계에서 검증합니다.
	# 여기서는 프로젝트에서 반복적으로 발생한 위험 패턴을 추가 검사합니다.
	var lines: PackedStringArray = source.split("\n")
	for index: int in lines.size():
		var line: String = lines[index]
		if line.strip_edges().begins_with("var ") and ":=" in line:
			warnings.append("%s:%d: inferred variable type (prefer explicit type for stable CI parsing)" % [path, index + 1])
		if "func(" in line and ")" in line and ":" not in line:
			warnings.append("%s:%d: anonymous/function value may need an explicit Callable type" % [path, index + 1])
