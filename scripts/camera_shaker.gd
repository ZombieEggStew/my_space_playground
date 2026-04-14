extends Node
class_name CameraShaker

@export var noise: FastNoiseLite = FastNoiseLite.new()
@export var shake_speed: float = 30.0
@export var shake_intensity: float = 0.5
@export var decay_rate: float = 3.0

var _shake_strength: float = 0.0
var _noise_i: float = 0.0
var _camera: Camera3D

func _ready() -> void:
    noise.seed = randi()
    noise.frequency = 0.5

func setup(camera: Camera3D) -> void:
    _camera = camera

func start_shake(intensity: float = 1.0) -> void:
    _shake_strength = intensity

func _process(delta: float) -> void:
    if _shake_strength > 0:
        _shake_strength = lerp(_shake_strength, 0.0, decay_rate * delta)
        _noise_i += delta * shake_speed
        
        if _camera:
            var shake_offset = Vector3(
                noise.get_noise_2d(_noise_i, 0),
                noise.get_noise_2d(0, _noise_i),
                0
            ) * _shake_strength * shake_intensity
            
            _camera.h_offset = shake_offset.x
            _camera.v_offset = shake_offset.y
    else:
        if _camera:
            _camera.h_offset = 0
            _camera.v_offset = 0
