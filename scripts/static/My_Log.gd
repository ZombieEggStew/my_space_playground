extends Node
class_name Log

static  func log_error(sender:Node, message: String) -> void:
    print("[ERROE] ", sender.name, ": ", message)

static  func log_missing_component(sender:Node , module : String) -> void:
    log_error(sender ,"Missing component: %s" % module)

static func log_info(sender:Node, message: String) -> void:
    print("[INFO] ", sender.name, ": ", message)