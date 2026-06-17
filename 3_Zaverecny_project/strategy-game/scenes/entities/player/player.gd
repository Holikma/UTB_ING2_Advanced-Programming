extends CharacterBody2D

enum State {
	IDLE,
	WALK,
	ATTACK,
	DEAD
}
@export_category("Stats")
@export var speed: int = 400
@export var hitpoints: int = 200
@export var attack_speed: float = 0.6
@export var attack_damage: int = 60

var state: State = State.IDLE
var move_direction: Vector2 = Vector2.ZERO

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var animation_playback: AnimationNodeStateMachinePlayback = $AnimationTree["parameters/playback"]

func _ready() -> void:
	animation_tree.set_active(true)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		attack()

func _physics_process(delta: float) -> void:		
	if not state == State.ATTACK:
		movement_loop()

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
	print(hitpoints)
	if hitpoints <= 0:
		death()
		
func death() -> void:
	print("I died")

func _on_hit_box_area_entered(area: Area2D) -> void:
	area.owner.take_damage(attack_damage)
