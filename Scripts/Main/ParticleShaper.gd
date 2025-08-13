tool
extends ReferenceRect
class_name ParticleShaper

# Number of particles for each tile size of 64
export var amountPerArea = 5

func _ready():
	if Engine.is_editor_hint():
		self.connect("item_rect_changed", self, "update_children_emission_shape")
	else:
		for child in get_children():
			if child.get_class() == "CPUParticles2D":
				child.emitting = true

func update_children_emission_shape():
	for child in get_children():
		if child.get_class() == "CPUParticles2D":
			child.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
			child.emission_rect_extents = rect_size/2
			child.global_position = rect_global_position + rect_size/2
			
			var area = (rect_size.x / 64) * (rect_size.y / 64)
			child.amount = amountPerArea * area
			
