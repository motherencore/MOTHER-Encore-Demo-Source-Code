extends Object

var skill = {}
var user = {}
var targets = []

signal done

func _init(_skill, _user, _targets = []):
	skill = _skill
	user = _user
	targets = _targets
