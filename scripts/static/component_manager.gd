extends Node
class_name ComponentManager


static func get_health_component(node: Node) -> Node:
    return node.get_node_or_null("HealthComponent")