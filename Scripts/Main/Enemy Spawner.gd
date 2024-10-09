extends Position2D

export (String) var enemy
export var Return = true
export var Perma_Death = false
export var Appearence_Rate = 100
export var inital_direction = Vector2.ZERO

onready var enemyPath = load("res://Nodes/Overworld/Enemies/Basic Enemy.tscn")

var attachedEnemy = null


func _ready():
	$Sprite.queue_free()
	var enemyData = Load_enemy_data(enemy)
	if enemyData.has("ovtype"):
		enemyPath = load("res://Nodes/Overworld/Enemies/" + enemyData["ovtype"] + ".tscn")

func set_attached_enemy(Enemy):
	attachedEnemy = Enemy
	if attachedEnemy == null and is_inside_tree():
		$Timer.start()

func _on_VisibilityNotifier2D_screen_entered():
	if randi()%100 <= Appearence_Rate and Appearence_Rate != 0 and attachedEnemy == null and !global.cutscene and $Timer.time_left == 0:
		create_enemy()
		if Perma_Death:
			queue_free()

func create_enemy():
	var new_parent = global.currentScene.get_node("Objects")
	var Enemy = enemyPath.instance()
	Enemy.enemy = enemy
	Enemy.returning = Return
	Enemy.global_position = self.global_position
	new_parent.add_child(Enemy)
	Enemy.start_pos = Enemy.global_position
	if inital_direction != Vector2.ZERO and Enemy.get("direction") != null:
		Enemy.inputVector = inital_direction
		Enemy.direction = inital_direction
	Enemy.connect("enemy_erased", self, "set_attached_enemy", [null])
	set_attached_enemy(Enemy)

func Load_enemy_data(enemy_name):
	var path = "res://Data/Battlers/"+(enemy_name.replace(" ", ""))+".json"
	var enemy_file = File.new()
	enemy_file.open(path, File.READ)
	var data = enemy_file.get_as_text()
	enemy_file.close()
	return parse_json(data)


func _on_Enemy_Spawner_tree_exited():
	if attachedEnemy != null:
		attachedEnemy.die(false)
