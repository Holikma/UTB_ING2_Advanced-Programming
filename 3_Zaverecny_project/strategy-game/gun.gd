extends CharacterBody2D

var speed = 400

var bullet_path = preload("res://bullets.tscn")

func _physics_process(delta: float) -> void:
	look_at(get_global_mouse_position())
	if Input.is_action_just_pressed("ui_accept"):
		fire()
	get_input()
	move_and_slide()
		
func fire():
	var bullet = bullet_path.instantiate()
	bullet.dir = rotation
	bullet.pos = $Node2D.global_position
	bullet.rota= global_rotation
	get_parent().add_child(bullet)

func get_input():
	var input_direction =  Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = input_direction * speed
