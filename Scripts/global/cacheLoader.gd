extends Node

var cache_ := []

var thread_ = Thread.new()

func _ready():
	thread_.start(self,"load_stuff","no_use")

func load_stuff(no_use) -> void:
	var to_load := ["res://Maps/podunk/podunk.tscn"]
	
	for i in to_load.size():
		cache_.push_back(load(to_load[i]))

func _exit_tree():
	thread_.wait_to_finish()
