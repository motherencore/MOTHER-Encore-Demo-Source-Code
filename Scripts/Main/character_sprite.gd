extends Sprite

signal sprite_changed

export (String,FILE,"*.json") var json
export (String,FILE) var sprite
export var autoOffset = true

var JsonFile = null
var dir = 0
var defaultOffset = Vector2.ZERO
var direction = Vector2.ZERO
var animationState = null
var animationTree = null
var directionalTags = []
var allTags = []

onready var animationPlayer = $AnimationPlayer

onready var anim_root_node = animationPlayer.get_node(animationPlayer.root_node)
onready var sprite_path: NodePath = anim_root_node.get_path_to(self)
onready var sprite_frame_path: NodePath = "%s:frame" % sprite_path


func _ready():
	var animTree = AnimationTree.new()
	add_child(animTree)
	animationTree = animTree
	
	#debug stuff
	if json != "":
		JsonFile = globaldata.get_json_file(json)
		create_animations()
		set_spritesheet()
		set_time_scale(5)
		animationState.travel("Talk")
	
	

#sets the json file to be used for animation
#connections sets what type of switch mode will be set between animation states
#each index is for one type of connection
#inside of each index, the first index is the origin of the connection, the second index is the target of the connection, and the third index is the switch mode as an integer number
#for the switch modes, 0 is for an immediate switch mode, 1 is for a sync switch mode and 2 is for a switch mode at end
#for example, [["Talk", "Idle", 2]] will add a connection from "Talk" to "Idle" with a SWITCH_MODE_AT_END switch mode
func set_animation(path, connections = []):
	json = path
	JsonFile = globaldata.get_json_file(json)
	create_animations(connections)

#manually set sprite offset
func set_sprite_offset(sprite_offset):
	offset = defaultOffset + sprite_offset

func set_sprite(path):
	sprite = path


func create_animations(connections = []):
	var singleTags = []
	hframes = JsonFile["size"][0]
	vframes = JsonFile["size"][1]
	
	for i in JsonFile["animations"]:
		if JsonFile["animations"][i]["directions"].size() == 1:
			singleTags.append(i)
		dir = JsonFile["animations"][i]["directions"].size()
		
		var directionalAnims = []
		for j in JsonFile["animations"][i]["directions"].size():
			
			var anim := Animation.new()
			var frame_track_id: int = anim.add_track(Animation.TYPE_VALUE)
			anim.track_set_path(frame_track_id, sprite_frame_path)
			
			if JsonFile["animations"][i]["type"] == 0:
				anim.loop = true
			else:
				anim.loop = false
				
			var frameCount = JsonFile["animations"][i]["directions"][0].size()
			
			var animationLength = JsonFile["animations"][i]["directions"][j][0]
			
			for frame_index in frameCount - 1:
				anim.track_insert_key(frame_track_id, animationLength, JsonFile["animations"][i]["directions"][j][frame_index + 1][0]-1)
				animationLength = animationLength + JsonFile["animations"][i]["directions"][j][frame_index + 1][1]
			
			anim.length = animationLength
			anim.value_track_set_update_mode(frame_track_id,Animation.UPDATE_DISCRETE)
			
			var dirTitle = ""
			var vector = Vector2.ZERO
			if JsonFile["animations"][i]["directions"].size() > 1:
				match j:
					0:
						dirTitle = " Down"
						vector = Vector2(0, 1)
					1:
						dirTitle = " Left"
						vector = Vector2(-1, 0)
					2:
						dirTitle = " Right"
						vector = Vector2(1, 0)
					3:
						dirTitle = " Up"
						vector = Vector2(0, -1)
					4:
						dirTitle = " DownLeft"
						vector = Vector2(-1, 1)
					5:
						dirTitle = " DownRight"
						vector = Vector2(1, 1)
					6:
						dirTitle = " UpLeft"
						vector = Vector2(-1, -1)
					7:
						dirTitle = " UpRight"
						vector = Vector2(1, -1)
						
				directionalAnims.append([i + dirTitle, vector])
				
			animationPlayer.add_animation(i + dirTitle, anim)
		directionalTags.append([i, directionalAnims])
	create_tree(directionalTags, singleTags, connections)

#sets the sprite texture
func set_spritesheet():
	if sprite != "":
		if ResourceLoader.exists(sprite):
			texture = load(sprite)
			if texture != null:
				if autoOffset:
					offset.y = -int(texture.get_height()/float(vframes*2))
				offset += Vector2(JsonFile["offset"][0], JsonFile["offset"][1])
				defaultOffset = offset
			show()
		else:
			hide()
	emit_signal("sprite_changed")

#creates the animation tree
func create_tree(tags:Array, singleTags:Array, connections = []):
	var animState = AnimationNodeStateMachine.new()
	animationTree.set_animation_player("../AnimationPlayer")
	animationTree.tree_root = animState
	
	allTags.clear()
	var tagNodes = []
	allTags.append_array(singleTags)
	
	for i in singleTags:
		var blendtree = AnimationNodeBlendTree.new()
		var timescale = AnimationNodeTimeScale.new()
		var blendnode = AnimationNodeAnimation.new()
		
		animState.add_node(i, blendtree)
		blendtree.add_node(i, blendnode)
		blendtree.add_node("TimeScale", timescale)
		
		blendnode.set_animation(i)
		
		timescale.add_input("Scale")
		
		blendtree.connect_node("TimeScale", 0, i)
		blendtree.connect_node("output", 0, "TimeScale")
		
		if i == "Idle":
			animState.set_start_node("Idle")
	
	
	for i in tags:
		if !animState.has_node(i[0]):
			tagNodes.append(i[0])
			var blendtree = AnimationNodeBlendTree.new()
			var blendspace = AnimationNodeBlendSpace2D.new()
			var timescale = AnimationNodeTimeScale.new()
			
			animState.add_node(i[0],blendtree)
			blendtree.add_node(i[0], blendspace)
			blendtree.add_node("TimeScale", timescale)
			
			timescale.add_input("TimeScale")
			
			blendtree.connect_node("TimeScale", 0, i[0])
			blendtree.connect_node("output", 0, "TimeScale")
			
			
			blendspace.blend_mode = AnimationNodeBlendSpace2D.BLEND_MODE_DISCRETE
			
			for j in i[1]:
				var animationNode = AnimationNodeAnimation.new()
				animationNode.set_animation(j[0])
				
				blendspace.add_blend_point(animationNode, j[1])
				
			if i[0] == "Idle":
				animState.set_start_node("Idle")
	
	
		
	
	allTags.append_array(tagNodes)
	
	
	for anim in connections:
		var trans = AnimationNodeStateMachineTransition.new()
		match anim[2]:
			0:
				trans.switch_mode = AnimationNodeStateMachineTransition.SWITCH_MODE_IMMEDIATE
			1:
				trans.switch_mode = AnimationNodeStateMachineTransition.SWITCH_MODE_SYNC
			2:
				trans.switch_mode = AnimationNodeStateMachineTransition.SWITCH_MODE_AT_END
		
		animationTree.tree_root.add_transition(anim[0],anim[1],trans)
	
	for i in allTags:
		for j in allTags:
			if i != j:
				if !animationTree.tree_root.has_transition(i, j):
					var trans = AnimationNodeStateMachineTransition.new()
					trans.switch_mode = AnimationNodeStateMachineTransition.SWITCH_MODE_IMMEDIATE
					animationTree.tree_root.add_transition(i,j,trans)
	
	animationTree.active = true
	animationState = animationTree.get("parameters/playback")
	
	if animState.get_start_node() == "":
		animState.set_start_node(allTags[0])
		var packed = PackedScene.new()
	
		for i in self.get_children():
			i.owner = self
		packed.pack(self)

		#ResourceSaver.save("res://FUCK.tscn",packed)
	
#animationTree.set("parameters/Idle/blend_position", vector2)



#travel to an animation state
func travel(state):
	animationState.travel(state)

#sets the direction for all animation states with multiple directions
func blend_position(vector):
	direction = vector
	for i in directionalTags:
		
		animationTree.set("parameters/"+ i[0] + "/" + i[0] + "/blend_position", direction)

#sets the speed at which animations play
func set_time_scale(scale = 1.0):
	for i in allTags:
		animationTree.set("parameters/"+ i + "/TimeScale/scale", scale)
