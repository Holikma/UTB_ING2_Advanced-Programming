extends CharacterBody2D

signal game_over(victorious: bool)
signal update_hp_bar(hp_bar_value: int)

enum State {
	IDLE,
	WALK,
	ATTACK,
	DEAD
}
@export_category("Stats")
@export var speed: int = 400
@export var hitpoints: int = 200
@export var attack_damage: int = 60

var state: State = State.IDLE
var move_direction: Vector2 = Vector2.ZERO
var attack_speed: float
var hitpoints_max: int 


@onready var animation_tree: AnimationTree = $AnimationTree
@onready var animation_playback: AnimationNodeStateMachinePlayback = $AnimationTree["parameters/playback"]
@onready var attack_sound: AudioStreamPlayer = get_node("/root/SceneHandler/HITSFX")

func _ready() -> void:
	hitpoints_max = hitpoints
	animation_tree.set_active(true)
	calculate_stats()
	

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		attack()

func _physics_process(_delta: float) -> void:		
	if not state == State.ATTACK:
		movement_loop()

func calculate_stats() ->void:
	attack_speed = Equations.calculate_attack_speed()
	var time_factor: float = Equations.BASE_ATTACK_SPEED / attack_speed
	animation_tree.set("parameters/ATTACK/TimeScale/scale", time_factor)
	print("new speed", attack_speed)

func movement_loop() -> void:
	move_direction.x = int(Input.is_action_pressed("RIGHT")) - int(Input.is_action_pressed("LEFT"))
	move_direction.y = int(Input.is_action_pressed("DOWN")) - int(Input.is_action_pressed("UP"))
	var motion: Vector2 = move_direction.normalized() * speed
	set_velocity(motion)
	move_and_slide()
	
	if state == State.IDLE or state == State.WALK:
		if move_direction.x < -0.01:
			$Sprite2D.flip_h = true
		elif move_direction.x > 0.01:
			$Sprite2D.flip_h = false
	
	
	if motion != Vector2.ZERO and state == State.IDLE:
		state = State.WALK
		update_animation()
	elif motion == Vector2.ZERO and state == State.WALK:
		state = State.IDLE
		update_animation()
		
func update_animation() ->void:
	match state:
		State.IDLE:
			animation_playback.travel("IDLE")
		State.WALK:
			animation_playback.travel("WALK")
		State.ATTACK:
			animation_playback.travel("ATTACK")
		State.DEAD:
			animation_playback.travel("DEAD")

func attack() -> void:
	if state == State.ATTACK:
		return
	state = State.ATTACK
	
	var mouse_pos: Vector2 = get_global_mouse_position()
	var attack_dir: Vector2 = (mouse_pos - global_position).normalized()
	$Sprite2D.flip_h = attack_dir.x < 0 and abs(attack_dir.x) >= abs(attack_dir.y)
	animation_tree.set("parameters/ATTACK/BlendSpace2D/blend_position", attack_dir)
	update_animation()
	
	await get_tree().create_timer(attack_speed).timeout
	state = State.IDLE
	
	
func take_damage(damage_taken: int) -> void:
	hitpoints -= damage_taken
	@warning_ignore("integer_division")
	update_hp_bar.emit((hitpoints * 100) / hitpoints_max)
	
	if hitpoints <= 0:
		death()
		
func death() -> void:
	state = State.DEAD
	update_animation()
	await get_tree().create_timer(0.5).timeout
	game_over.emit(false)

func _on_hit_box_area_entered(area: Area2D) -> void:
	attack_sound.play()
	area.owner.take_damage(attack_damage)
