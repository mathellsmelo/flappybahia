# script: bird

extends RigidBody2D

onready var state = FlyingState.new(self)
var prev_state

var speed = 50

const STATE_FLYING = 0
const STATE_FLAPPING = 1 
const STATE_HIT = 2
const STATE_GROUNDED = 3

signal state_changed

func _ready():
	set_process_input(true)
	set_physics_process(true)
	
	add_to_group(game.GROUP_BIRDS)
	connect("body_entered", self ,"_on_body_enter")
	pass
    
func _on_body_enter(other_body):
	if state.has_method("on_body_enter"):
		state.on_body_enter(other_body)
	pass

func _physics_process(delta):
	state.update(delta)
	pass

func _input(event):
	state.input(event)
	pass
	
    
func set_state(new_state):
	state.exit()
	prev_state = get_state()
	
	if new_state == STATE_FLYING:
		state = FlyingState.new(self)
	elif new_state == STATE_FLAPPING:
		state = FlappingState.new(self)
	elif new_state == STATE_GROUNDED:
		state = GroundedState.new(self)
	elif new_state == STATE_HIT:
		state = HitState.new(self)
	emit_signal("state_changed", self)
	pass

func get_state():
	if state is HitState:
		return STATE_HIT
	elif state is FlappingState:
		return STATE_FLAPPING
	elif state is FlyingState:
		return STATE_FLYING
	elif state is GroundedState:
	 	return STATE_GROUNDED
	pass
	 
class FlyingState:
	var bird
	var prev_gravity_scale
	
	func _init(bird):
		self.bird = bird
		bird.get_node("anim").play("flying")
		bird.set_linear_velocity(Vector2(bird.speed, bird.get_linear_velocity().y))
		prev_gravity_scale = bird.get_gravity_scale()
		bird.set_gravity_scale(0)
		pass
		
	func update(delta):
		pass
	
	func input(event):
		pass
	
	func exit():
		bird.set_gravity_scale(prev_gravity_scale)
		bird.get_node("anim").stop()
		bird.get_node("anim_sprite").set_position(Vector2(0, 0))
		pass

	
class FlappingState:
	var bird
	
	func _init(bird):
		self.bird = bird
		
		bird.set_linear_velocity(Vector2(bird.speed, bird.get_linear_velocity().y))
		flap()
		pass
		
	func update(delta):
		if rad2deg(bird.get_rotation()) < -20:
			bird.set_rotation(deg2rad(-20))
			bird.set_angular_velocity(0)
	
		if bird.get_linear_velocity().y > 0:
			bird.set_angular_velocity(1.5)
		pass
		
		
	func on_body_enter(other_body):
		if other_body.is_in_group(game.GROUP_PIPES):
			bird.set_state(bird.STATE_HIT)
		elif other_body.is_in_group(game.GROUP_GROUNDS):
			bird.set_state(bird.STATE_GROUNDED)
		pass
	
	func flap():
		bird.set_linear_velocity(Vector2(bird.get_linear_velocity().x, -150))
		bird.set_angular_velocity(-3)
		bird.get_node("anim").play("flap")
		audio_player.get_node("wing").play()
		pass 
	
	func input(event):
	  if Input.is_action_just_pressed("flap"):
	   flap()
	
	  elif (event.is_pressed() and event.button_index == BUTTON_LEFT):
	    flap()
	  pass
	
	func exit():
		pass
		
	
class HitState:
	var bird
	
	func _init(bird):
		self.bird = bird
		bird.set_linear_velocity(Vector2(0, 0))
		bird.set_angular_velocity(2)
		
		var other_body = bird.get_colliding_bodies()[0]
		bird.add_collision_exception_with(other_body)
		audio_player.get_node("hit").play()
		audio_player.get_node("die").play()
		pass
	
	func update(delta):
		pass
	
	func input(event):
		pass
	
	func on_body_enter(other_body):
		if other_body.is_in_group(game.GROUP_GROUNDS):
			bird.set_state(bird.STATE_GROUNDED)
		pass
	
	func exit():
		pass
		
	
class GroundedState:
	var bird
	
	func _init(bird):
		self.bird = bird
		game.score_best = game.score_current
		bird.set_linear_velocity(Vector2(0, 0))
		bird.set_angular_velocity(0)
		
		if bird.prev_state != bird.STATE_HIT:
			audio_player.get_node("hit").play()
		pass
		
	func update(delta):
		pass
	
	func input(event):
		pass
	
	func exit():
		pass
