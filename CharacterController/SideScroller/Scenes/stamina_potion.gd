extends StaticBody2D

@export var value = 10

func Collect():
	queue_free()
	LevelDirector.stamina_potion += 1
