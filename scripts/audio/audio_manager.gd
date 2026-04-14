extends Node
class_name AudioManager

@export var audio_stream_player : AudioStreamPlayer

func play_hit_sound() -> void:
    audio_stream_player.play()