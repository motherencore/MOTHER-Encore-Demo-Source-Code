extends Position2D

export (String) var enemy
export var Return = true
export var Perma_Death = false
export var Appearence_Rate = 100
export var inital_direction = Vector2.ZERO

var EnemyScene

var _attached_enemy = null


func _ready():
	$Sprite.queue_free()
	var enemyData = _load_enemy_data(enemy)
	var ov_type = enemyData["ov"].get("type", "Basic Enemy")
	EnemyScene = load("res://Nodes/Overworld/Enemies/%s.tscn" % ov_type)

func _set_attached_enemy(enemy_node):
	_attached_enemy = enemy_node
	if _attached_enemy == null and is_inside_tree():
		$Timer.start()

func _on_VisibilityNotifier2D_screen_entered():
	if randi()%100 <= Appearence_Rate and Appearence_Rate != 0 and _attached_enemy == null and !global.cutscene and $Timer.time_left == 0:
		_create_enemy()
		if Perma_Death:
			queue_free()

func _create_enemy():
	var new_parent = global.currentScene.get_node("Objects")
	var enemy_node = EnemyScene.instance()
	enemy_node.enemy = enemy
	enemy_node.returning = Return
	enemy_node.global_position = self.global_position
	new_parent.add_child(enemy_node)
	enemy_node.start_pos = enemy_node.global_position
	if inital_direction != Vector2.ZERO and enemy_node.get("direction") != null:
		enemy_node.inputVector = inital_direction
		enemy_node.direction = inital_direction
	enemy_node.connect("enemy_erased", self, "_set_attached_enemy", [null])
	_set_attached_enemy(enemy_node)

func _load_enemy_data(enemy_name):
	var path = "res://Data/Battlers/"+(enemy_name.replace(" ", ""))+".yaml"
	return globaldata.get_json_data(path)

func _on_Enemy_Spawner_tree_exited():
	if _attached_enemy != null:
		_attached_enemy.die(false)
