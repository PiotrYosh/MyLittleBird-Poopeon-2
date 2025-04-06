extends CharacterBody3D

@export var walk_speed: float = 180.0
@export var run_speed: float = 400.0
@export var crouch_speed: float = 100.0
@export var jump_velocity: float = 900.0
@export var gravity: float = 2000

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var armature: Node3D = $Armature
@onready var jump_timer: Timer = $JumpTimer

# Maszyna stanów
enum State { IDLE, WALK, RUN, CROUCH, SNEAK, JUMP, FALL }
var current_state: State = State.IDLE

# Zmienne pomocnicze
var direction = Vector3.ZERO
var is_moving = false

func _ready():
	$JumpTimer.timeout.connect(Callable(self, "_on_JumpTimer_timeout"))

func _physics_process(delta: float):
	update_movement(delta)
	process_state(delta)

	# Ruch i aktualizacja
	velocity.x = direction.x * get_speed()
	velocity.z = 0
	move_and_slide()
	handle_rotation()

# Aktualizacja ruchu
func update_movement(delta: float):
	is_moving = false
	direction = Vector3.ZERO

	# Lewo / Prawo
	if Input.is_action_pressed("ui_left"):
		direction.x = -1
		is_moving = true
	elif Input.is_action_pressed("ui_right"):
		direction.x = 1
		is_moving = true

	# Grawitacja
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0

# Logika stanów
func process_state(delta: float):
	match current_state:
		State.IDLE:
			if is_moving and Input.is_action_pressed("ctrl"):  # Skradanie: kucanie + ruch
				current_state = State.SNEAK
				play_looping_animation("sneaking")
			elif is_moving:
				current_state = State.WALK
				play_looping_animation("walk")
			elif is_moving and Input.is_action_pressed("shift"):
				current_state = State.RUN
				play_looping_animation("run")
			elif Input.is_action_pressed("ctrl"):
				current_state = State.CROUCH
				anim.play("crouch")
			elif Input.is_action_just_pressed("ui_accept"):
				current_state = State.JUMP
				anim.play("jump1")  # Skok nie jest zapętlony
				jump_timer.start()
			else:
				play_looping_animation("idle")
		State.WALK:
			if not is_moving:
				current_state = State.IDLE
				play_looping_animation("idle")
			elif is_moving and Input.is_action_pressed("shift"):
				current_state = State.RUN
				play_looping_animation("run")
			elif is_moving and Input.is_action_pressed("ctrl"):
				current_state = State.SNEAK
				play_looping_animation("sneaking")
		State.RUN:
			if not is_moving or not Input.is_action_pressed("shift"):
				current_state = State.WALK
				play_looping_animation("walk")
		State.CROUCH:
			if is_moving:
				current_state = State.SNEAK
				play_looping_animation("sneaking")
			elif not Input.is_action_pressed("ctrl"):
				current_state = State.IDLE
				play_looping_animation("idle")
		State.SNEAK:
			if not is_moving or not Input.is_action_pressed("ctrl"):
				current_state = State.IDLE
				play_looping_animation("idle")
		State.JUMP:
			pass # Czekaj, aż timer sie skończy

		State.FALL:
			# Po wylądowaniu wraca do odpowiedniego stanu
			if is_on_floor():
				if is_moving and Input.is_action_pressed("ctrl"):
					current_state = State.SNEAK
					play_looping_animation("sneaking")
				elif is_moving:
					current_state = State.WALK
					play_looping_animation("walk")
				else:
					current_state = State.IDLE
					play_looping_animation("idle")
		_:  # Domyślny fallback
			current_state = State.IDLE
			play_looping_animation("idle")

# Funkcja zapętlenia animacji
func play_looping_animation(animation_name: String):
	if $AnimationPlayer.current_animation != animation_name or not $AnimationPlayer.is_playing():
		$AnimationPlayer.play(animation_name)

# Obsługa rotacji postaci
func handle_rotation():
	if direction.x != 0:
		armature.rotation.y = deg_to_rad(180) if direction.x < 0 else 0

# Pobranie prędkości
func get_speed() -> float:
	match current_state:
		State.WALK: return walk_speed
		State.RUN: return run_speed
		State.CROUCH: return crouch_speed
		State.SNEAK: return crouch_speed  # Prędkość skradania = prędkość kucania
		_: return 0.0  # Domyślnie zwraca 0

# Funkcja wywoływana po zakończeniu Timera
func _on_JumpTimer_timeout():
	if current_state == State.JUMP:
		velocity.y = jump_velocity  # Fizyczny skok w górę
		current_state = State.FALL
