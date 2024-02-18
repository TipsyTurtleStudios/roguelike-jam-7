extends Node

var transitions = preload("res://CharacterController/SideScroller/Scenes/Transitions.tscn")
enum TransitionTypes {dissolve, bluewave}
var Transitioning : bool = false
var animationPlayer
var target : String

var level_dict = { 1 : "res://blue.tscn" , 2 : "res://pink.tscn" }

func _ready():
	init_tranistions()
	
func init_tranistions():
	var instance = transitions.instantiate()
	add_child(instance)
	animationPlayer = $"CanvasLayer/AnimationPlayer"

func change_scene(transition_type: TransitionTypes = TransitionTypes.dissolve,target: String = "") -> void:
	if target == "":
		target = get_random_target()
	
	if not Transitioning:
		match transition_type:
			TransitionTypes.dissolve:
				Transitioning = true
				animationPlayer.play("Fade_out")
				await animationPlayer.animation_finished
				get_tree().change_scene_to_file(target)
				animationPlayer.play("Fade_in")
				Transitioning = false
				
	pass

func get_random_target():
	var a = level_dict[ level_dict.keys()[ randi() % level_dict.size() ] ]
	return a
	
	
