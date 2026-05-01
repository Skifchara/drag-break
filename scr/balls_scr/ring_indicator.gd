extends Node2D

@export var ring_radius: float = 56.0
@export var ring_thickness: float = 5.0
@export var segments: int = 48


func _draw():
	draw_arc(Vector2.ZERO, ring_radius, 0, TAU, segments, Color.WHITE, ring_thickness, true)
