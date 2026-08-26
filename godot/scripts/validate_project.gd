extends SceneTree

## CI project validator.
## 개별 .gd 파일을 load()하면 class_name 등록 순서 때문에 거짓 오류가 발생할 수 있습니다.
## 실제 프로젝트를 부팅하여 Autoload가 등록된 뒤 모든 스크립트/씬을 로드해 Godot 자체로 검사합니다.

const SCAN_ROOTS: Array[String] = ["res://scripts", "res://scenes"]

func _init() -> void:
	print("=== DiceGod Project Validation ===")
	print("Mode: real project startup / parser validation")
	# SceneTree._init() 시점에는 autoload 노드가 아직 root에 없으므로 한 프레임 뒤에 검증합니다.
	call_deferred("_run_validation")

func _run_validation() -> void:
	var failures: Array[String] = []
	var paths: Array[String] = []
	for root_path: String in SCAN_ROOTS:
		_collect_files(root_path, paths)
	for path: String in paths:
		var resource: Resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REPLACE)
		if resource == null:
			failures.append("load failed: %s" % path)
		elif resource is GDScript and not (resource as GDScript).can_instantiate():
			failures.append("script does not compile: %s" % path)
		elif resource is PackedScene and not (resource as PackedScene).can_instantiate():
			failures.append("scene cannot instantiate: %s" % path)
	print("Checked %d files." % paths.size())
	for failure: String in failures:
		push_error(failure)
	if failures.is_empty():
		print("Project startup validation completed.")
		quit(0)
	else:
		print("Project validation failed: %d error(s)." % failures.size())
		quit(1)

func _collect_files(path: String, out: Array[String]) -> void:
	var directory: DirAccess = DirAccess.open(path)
	if directory == null:
		return
	directory.list_dir_begin()
	var name: String = directory.get_next()
	while not name.is_empty():
		var full_path: String = path.path_join(name)
		if directory.current_is_dir():
			_collect_files(full_path, out)
		elif name.ends_with(".gd") or name.ends_with(".tscn"):
			out.append(full_path)
		name = directory.get_next()
	directory.list_dir_end()
