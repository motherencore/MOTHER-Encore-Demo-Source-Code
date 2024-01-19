extends Area2D

#the paths for the objects that are moved
export (Array, NodePath) var object_paths = []
#where to move the objects
export (NodePath) var new_parent
#whether to copy the collisions or not
export (bool) var copy_collisions

#get the actual object nodes
onready var objectNodes = []
onready var newParentNode = get_node_or_null(new_parent)

func _ready():
	for object in object_paths:
		objectNodes.append(get_node_or_null(object))

func _on_Reparenter_body_entered(body):
	if body == global.persistPlayer:
		reparent()

#reparent the objects
func reparent():
	for item in objectNodes:
		if item != null and newParentNode != null:
			if item.get_parent() != newParentNode and item.get_parent() != null: #and item.get_parent() == oldParentNode:
				item.get_parent().remove_child(item)
				newParentNode.call_deferred("add_child", item)
				if copy_collisions:
					item.set_deferred("collision_mask", newParentNode.collision_mask)
					item.set_deferred("collision_layer", newParentNode.collision_layer)
		
