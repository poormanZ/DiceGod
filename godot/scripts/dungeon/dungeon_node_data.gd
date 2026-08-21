class_name DungeonNodeData
extends Resource

## 던전 지도에서 하나의 노드를 표현하는 데이터입니다.
## 실제 씬/UI는 이 데이터를 읽어서 표시합니다.

enum NodeType {
	BATTLE,
	REWARD,
	SHOP,
	EVENT,
	ELITE,
	BOSS,
	REST,
	TREASURE,
}

@export var node_id: String = ""
@export var display_name: String = "던전 노드"
@export_multiline var description: String = ""
@export var node_type: NodeType = NodeType.BATTLE
@export var next_node_ids: Array[String] = []
@export var is_start_node: bool = false
@export var is_end_node: bool = false
