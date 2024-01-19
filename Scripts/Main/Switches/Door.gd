extends Sprite

export var switch_path : NodePath
export var switch_path2 : NodePath
export var OG_Open = false
var open = false

onready var animationState = $AnimationTree.get("parameters/playback")
onready var switchnode = get_node_or_null(switch_path)
onready var switchnode2 = get_node_or_null(switch_path2)

func _ready():
	open = OG_Open
	set_opened()
	if switchnode != null:
		if switchnode.has_signal("switch_hit"):
			switchnode.connect("switch_hit", self, "check_switch")
	if switchnode2 != null:
		if switchnode2.has_signal("switch_hit"):
			switchnode2.connect("switch_hit", self, "check_switch")
	

func check_switch():
	open = !open
	set_opened()

func set_opened():
	if open:
		$AnimationPlayer.play("Open")
		$collision/CollisionShape2D.set_deferred("disabled", true)
	else:
		$AnimationPlayer.play("Close")
		$collision/CollisionShape2D.set_deferred("disabled", false)
