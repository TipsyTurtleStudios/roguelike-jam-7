extends Area2D

func _process(delta):
	if get_overlapping_bodies():
		Transition.change_scene(Transition.TransitionTypes.dissolve,"res://CharacterController/SideScroller/Scenes/test_scene.tscn")
