extends Area2D
var damage: int = 0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	await get_tree().create_timer(0.2).timeout
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		var attack = Attack.new()
		attack.damage = damage
		body.take_damage(attack)
