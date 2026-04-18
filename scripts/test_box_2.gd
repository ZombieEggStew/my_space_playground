extends MeshInstance3D


func _process(_delta):
	var player := GameManager.get_current_player()
	if player == null: return
	position = player.global_position + player.global_basis.z * 50.0

