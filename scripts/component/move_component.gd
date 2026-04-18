extends Node
class_name MoveComponent

# @export var drag_coefficient := 0.5
# @export var mass := 1.0

# var current_thrust := Vector3.ZERO

# func _physics_process(delta: float) -> void:
#     var root = get_parent() as CharacterBody3D
#     if not root:
#         return


#     var drag_force = -root.velocity * drag_coefficient
    

#     var net_force = current_thrust + drag_force
    

#     root.velocity += (net_force / mass) * delta
    
#     root.move_and_slide()

# func apply_thrust(thrust_vector: Vector3) -> void:
#     current_thrust = thrust_vector
