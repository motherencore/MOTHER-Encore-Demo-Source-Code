extends Sprite

onready var anim_player = $AnimationPlayer

func _ready():
	anim_player.play("Fadeout")

func set_texture(sprite):
	texture = sprite.texture
	hframes = sprite.hframes
	vframes = sprite.vframes
	offset = sprite.offset
	frame = sprite.frame

func _on_AnimationPlayer_animation_finished(_anim_name):
	queue_free()
