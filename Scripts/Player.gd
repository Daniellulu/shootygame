extends KinematicBody2D

class_name Player


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var player_name := ""

var x_input := 0.0
var y_input := 0.0
export var player_speed := 300.0
#export var dash_multiplier := 2.0
var is_dashing := false
#networked variables
puppet var player_velocity := Vector2()
puppet var player_position := Vector2()
puppet var facing_left := false

var gravity := 1200
var jump_force := 600
var air_jumps := 2 #number of air jumps
var air_jumps_left = air_jumps
var is_jumping := false

#enum Direction{UP, DOWN, LEFT, RIGHT, UP_LEFT, UP_RIGHT, DOWN_LEFT, DOWN_RIGHT}
#var current_direction = Direction.UP

#var player_angle := 0

export var default_health = 10
export(int) onready var player_health = default_health

export var default_shield := 10
export(int) onready var shield_health := default_shield
var shield_pressed := false

var is_shooting := false
var shoot_direction := Vector2()
#var special_pressed := false

#var melee_pressed := false
var bullet_template = preload("res://Scenes/Bullet.tscn")
var bullet_exit_radius := 54.0
export var bullet_speed := 500.0
var fire_rate := 0.2
var time_left_till_next_bullet = fire_rate


# Called when the node enters the scene tree for the first time.
func _ready():
	set_shoot_rotation()
	set_player_name(player_name)
	player_position = position
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	get_input(delta)
	set_movement(delta)
	#set_direction()
	set_shoot_rotation()
	do_attack(delta)
	pass

func get_input(delta):
	x_input = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	#y_input = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	
	#check for facing direction
	if(x_input >= 0):
		facing_left = false
	else:
		facing_left = true
	
	shield_pressed = Input.is_action_pressed("shield")
	
	is_shooting = Input.is_action_pressed("shoot")
	
	is_jumping = Input.is_action_just_pressed("jump_pressed")
	
	pass

func jump():
	player_velocity.y = -jump_force
	is_jumping = false

func set_movement(delta):
	if is_network_master():
		player_velocity.x = player_speed * x_input
	
		if(is_jumping and is_on_floor()):
			jump()
			print("normal_jump")
			print(str(player_velocity))
		elif(is_jumping and is_on_wall()):
			jump()
			print("left_wall_jump")
			print(str(player_velocity))
		elif(is_jumping and air_jumps_left > 0):
			jump()
			air_jumps_left -= 1
			print("air_jumps_left: " + str(air_jumps_left))
			print(str(player_velocity))
		elif(is_on_floor()):
			player_velocity.y = 0
			air_jumps_left = air_jumps
		elif(!is_on_floor()):
			player_velocity.y += gravity * delta
		
		rset("player_velocity", player_velocity)
		rset("player_position", player_position)
	else:
		position = player_position
	
	move_and_slide(player_velocity, Vector2(0, -1)) #added a floor 
	
	if not is_network_master():
		player_position = position # To avoid jitter
	pass


func set_shoot_rotation():
	#current_shoot.rotation_degrees = rad2deg(player_angle)
	var mouse_direction := get_position().direction_to(get_global_mouse_position()) # getting direction to mouse
	var bullet_angle := atan2(mouse_direction.y, mouse_direction.x)
	shoot_direction = Vector2(cos(bullet_angle), sin(bullet_angle))
	get_node("BulletExit").position = shoot_direction * bullet_exit_radius + self.position
	pass


func do_attack(delta):
	time_left_till_next_bullet -= delta
	if(is_shooting and time_left_till_next_bullet <= 0):
		var bullet = bullet_template.instance()
		bullet.set_direction(shoot_direction)
		bullet.bullet_speed = bullet_speed
		bullet.position = get_node("BulletExit").position
		bullet.node_this_belongs_to = self
		get_tree().get_root().add_child(bullet)
		time_left_till_next_bullet = fire_rate
		pass
	pass

func on_hit(damage):
	if(shield_health > 0):
		shield_health -= damage
	elif (player_health > 0):
		player_health -= damage
	else:
		death()
	pass

func death():
	#RESPAWN
	shield_health = default_shield
	player_health = default_health
	position = get_parent().get_node("SpawnPoints/0").position
	pass

func set_player_name(new_name):
	player_name = new_name
	get_node("NameLabel").set_text(player_name)

func _to_string():
	var player_string := ""
	player_string += "Current State: "
	
	player_string += "\n"
	
	player_string += "Health:" + str(player_health) + "\n"
	
	player_string += "Shield: " + str(shield_pressed) + "\nShield Health: " + str(shield_health) + "\n"
	
	player_string += "Shooting: " + str(is_shooting) + "\n"

	return player_string