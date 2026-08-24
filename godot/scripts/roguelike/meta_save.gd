class_name MetaSave
extends RefCounted

const SAVE_PATH: String = "user://dicegod_meta.json"

static func save(run_state: RunStateManager) -> bool:
	var data: Dictionary = {"version": 1, "permanent_runs": run_state.permanent_runs, "permanent_wins": run_state.permanent_wins, "permanent_deaths": run_state.permanent_deaths, "unlocked_gods": run_state.unlocked_gods.duplicate(), "unlocked_divine_symbols": run_state.unlocked_divine_symbols.duplicate(), "inherited_die": run_state.inherited_die.duplicate(true)}
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data))
	file.close()
	return true

static func load(run_state: RunStateManager) -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not (parsed is Dictionary):
		return false
	var data: Dictionary = parsed
	run_state.permanent_runs = int(data.get("permanent_runs", 0))
	run_state.permanent_wins = int(data.get("permanent_wins", 0))
	run_state.permanent_deaths = int(data.get("permanent_deaths", 0))
	run_state.unlocked_gods = Array(data.get("unlocked_gods", []))
	run_state.unlocked_divine_symbols = Array(data.get("unlocked_divine_symbols", []))
	run_state.inherited_die = Dictionary(data.get("inherited_die", {}))
	return true
