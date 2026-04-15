extends PanelContainer
class_name BuffIcon

@export var icon_rect: TextureRect

func set_texture(texture: Texture2D) -> void:
	icon_rect.texture = texture

func on_expire() -> void:
	queue_free()