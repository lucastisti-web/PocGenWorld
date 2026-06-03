@tool
extends EditorPlugin

var dock: Control

func _enter_tree() -> void:
	dock = preload("res://addons/procgen_world/procgen_dock.gd").new()
	dock.name = "ProcGen World"
	dock.editor_plugin = self
	add_control_to_bottom_panel(dock, "🌍 ProcGen World")

func _exit_tree() -> void:
	if dock:
		remove_control_from_bottom_panel(dock)
		dock.queue_free()
