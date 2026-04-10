extends Node

var targetable_objects: Array[AbleToBeLocked] = []

func register_target(obj: AbleToBeLocked):
	if not targetable_objects.has(obj):
		targetable_objects.append(obj)

func unregister_target(obj: AbleToBeLocked):
	targetable_objects.erase(obj)



