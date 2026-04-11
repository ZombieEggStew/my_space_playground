extends CharacterBody3D

var team_id := 2

var hit_count := IntStat.new(0,10)


var speed := 10.0
var _orbit_angle := 0.0

@export var player_ship: CharacterBody3D 
@export var spawn_radius_min := 100.0
@export var spawn_radius_max := 600.0
var orbit_radius := 200.0
var orbit_angular_speed := .1
@export var radius_correction_gain := 3.0

func _ready() -> void:
    _randomize_spawn_and_orbit()


func _randomize_spawn_and_orbit() -> void:
    if player_ship == null:
        return

    var min_r := min(spawn_radius_min, spawn_radius_max) as float
    var max_r := max(spawn_radius_min, spawn_radius_max) as float
    orbit_radius = randf_range(min_r, max_r)
    _orbit_angle = randf_range(0.0, TAU)

    var center := player_ship.global_position
    var offset := Vector3(cos(_orbit_angle), 0.0, sin(_orbit_angle)) * orbit_radius
    global_position = center + offset
    velocity = Vector3.ZERO

func _physics_process(delta: float) -> void:
    if player_ship == null:
        velocity = Vector3.ZERO
        move_and_slide()
        return

    var center := player_ship.global_position
    var to_center := global_position - center
    to_center.y = 0.0

    if to_center.length() < 0.001:
        to_center = Vector3.RIGHT * orbit_radius

    var current_radius := to_center.length()
    var radial_dir := to_center.normalized()
    var tangent_dir := Vector3(-radial_dir.z, 0.0, radial_dir.x)

    var orbit_linear_speed := abs(orbit_angular_speed) * orbit_radius as float
    var tangent_vel := tangent_dir * orbit_linear_speed * sign(orbit_angular_speed) as Vector3
    var radial_correction := radial_dir * ((orbit_radius - current_radius) * radius_correction_gain)

    velocity = tangent_vel + radial_correction
    velocity.y = 0.0
    move_and_slide()

func reset() -> void:
    hit_count.value = 0
    _randomize_spawn_and_orbit()

func get_hit_count() -> IntStat:
    return hit_count

func get_hit(_damage: float) -> void:
    hit_count.value += 1
    if hit_count.value >= 10:
        reset()

func get_pivot_offset() -> Vector3:
    return Vector3.ZERO

func get_team_id() -> int:
    return team_id
