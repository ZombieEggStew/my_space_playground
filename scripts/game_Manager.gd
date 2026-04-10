extends Node3D
class_name GameManager

const TEAM_NEUTRAL := 0
const TEAM_PLAYER := 1
const TEAM_ENEMY := 2

# enum State {
#     PATROL,
#     CHASE,
#     STRAFE,
#     EVADE
# }

static var instance: GameManager

@export var bullet_scene: PackedScene
@export var bullets_parent: Node
@export var player_ship: CharacterBody3D
@export var test_box: CharacterBody3D

const default_state_name := &"null" 
const patrol_state_name := &"patrol"
const chase_state_name := &"chase"
const strafe_state_name := &"strafe"
const evade_state_name := &"evade"

const aim_state_name := &"aim"
const attack_state_name := &"attack"
const idle_state_name := &"idle"


func get_player() -> CharacterBody3D:
	return player_ship
func get_test_box() -> CharacterBody3D:
	return test_box

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if instance:
		queue_free()
	else:
		instance = self



