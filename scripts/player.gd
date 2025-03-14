extends CharacterBody2D

signal isMoving(value: bool)
signal isGrounded(value: bool)

@onready var playerSprite = $AnimatedSprite2D
@onready var hitbox_body_right: CollisionShape2D = $HitboxBodyRight
@onready var hitbox_body_left: CollisionShape2D = $HitboxBodyLeft
@onready var hitbox_feet: CollisionShape2D = $HitboxFeet
@onready var walk_push_ray_left: CollisionShape2D = $walkPushRayLeft
@onready var walk_push_ray_right: CollisionShape2D = $walkPushRayRight
@onready var foot_push_ray_right: CollisionShape2D = $footPushRayRight
@onready var foot_push_ray_left: CollisionShape2D = $footPushRayLeft

@onready var game_manager: Node = %gameManager

func getCardinal():
	var x = 0
	var y = 0
	
	if Input.is_action_pressed("moveRight"):
		x += 1
		
	if Input.is_action_pressed("moveLeft"):
		x -= 1
		
	if Input.is_action_pressed("Climb"):
		y -= 1
		
	if Input.is_action_pressed("Crouch"):
		y += 1
		
	return Vector2(x,y)

#Constants
const INPUT_BUFFER: int = 5

const AIR_ACCEL = 425
const GROUND_ACCEL = 280
const TURNING_ACCEL_FACTOR = 15

const AIR_RESISTANCE = 800
const FRICTION = 1000

const MAX_GROUND_SPEED = 180
const MAX_AIR_SPEED = 250

const FALL_SPEED = 500
const FASTFALL_SPEED = 700

const LEAP_VELOCITY = -400
const JUMP_VELOCITY = -360
const HOP_VELOCITY = -275
const GRAVITY = 981

const NEAR_MISS_THRESHOLD = 5

const DASH_SPEED = 420

const DASH_TIME = 40
const DASH_RELEASE = 30

const WALL_STICK_RELEASE = 15
const WALL_JUMP_TIME = 10

const LEAP_COUNTDOWN = 20

const GROUNDDASH_FRICTION = 2.5
const AIRDASH_FRICTION = 1.5

const DASHTYPE_KEY = {
	notDashing = 0,
	
	shortGround = 1.0,
	longGround = 1.1,
	
	airDefault = 2.0,
	airUp = 2.8,
	airUpRight = 2.9,
	airRight = 2.6,
	airDownRight = 2.3,
	airDown = 2.2,
	airDownLeft = 2.1,
	airLeft = 2.4,
	airUpLeft = 2.7,
	
	landingDefault = 3.0,
	landingDownRight = 3.3,
	landingDown = 3.2,
	landingDownLeft = 3.1
	}

const STOP: Vector2 = Vector2(0,0)

#Variables

#Booleans
var bufferedJump: bool = false
var bufferedDash: bool = false

var isTalking: bool = false
var dashRelease: bool = false
var dashJump: bool = false
var dashLand: bool = false
var hasAirdash: bool = true

var wallStick: bool = false
var canWallStick: bool = true
var wallJumping: bool = false
var hasWallJump: bool = true

var turning: bool = false

var grounded: bool
var crouching: bool

#Floating Points
var dashType: float = 0
var dashSpeedx: float
var dashSpeedy: float
var dashFriction: float = 1

var turningFactor: float

var accel: float
var gravity: float

var maxSpeedx: float
var maxSpeedy: float

#Integers
var jumpBuffer: int = 0
var dashBuffer: int = 0

var debugMenu: int = -1

var dashCountdown: int = 0
var wallJumpCountdown: int = 0
var wallStickRelease: int = 0
var leapCountdown: int = 0

var direction: int
var facing: int = 1

#Vector :pog:
var dashCardinal: Vector2
var inputVector: Vector2

func debug():
	print("Grounded = " + str(grounded) + " Crouching = " + str(crouching) + " Turning = " +
	str(turning) + " Dash Countdown = " + str(dashCountdown) + " Dash Type = " + str(dashType) +
	" Dash Release = " + str(dashRelease) + " Dash Jump = " + str(dashJump) + " hasAirDash = " + 
	str(hasAirdash) + " Wall Jump = " + str(wallJumping) + " Wall Jump Countdown = " +
	str(wallJumpCountdown) + " isTalking = " + str(isTalking))

func _ready():
	#Handle connections with Interaction Manager
	print(".")
	var connection1 = get_node("/root/InteractionManager")
	connection1.isTalking.connect(_on_isTalking_signal)

func _on_isTalking_signal(value: bool):
	isTalking = value

#Input buffers function
func buffer():
	#Jump buffer
	if Input.is_action_just_pressed("Jump"):
		jumpBuffer = INPUT_BUFFER
	elif jumpBuffer > 0:
		jumpBuffer -= 1
	
	if Input.is_action_just_pressed("dash"):
		dashBuffer = INPUT_BUFFER
	elif dashBuffer > 0:
		dashBuffer -= 1

#TO DO:
#Expand turn mechanic
#Add dash slip
#Add jump countdown so the separation rays don't push you away from platforms
func _physics_process(delta: float) -> void:
	buffer()
	print(str(dashBuffer) + " " + str(jumpBuffer))
	
	#Emit various player state signals
	emit_signal("isGrounded", grounded)
	if velocity.x > 25 or velocity.x < -25:
		emit_signal("isMoving", true)
	else:
		emit_signal("isMoving", false)
	
	#Skip physics when player is talking
	if isTalking:
		return
	
	#Check if the player is on the ground
	if is_on_floor():
		grounded = true
		hasWallJump = true
	else:
		grounded = false
	
	#Check if player is crouching
	if Input.is_action_pressed("Crouch"):
		crouching = true
		
	else:
		crouching = false
	
	#Get input vector
	inputVector = getCardinal()
	
	#Get input direction (-1, 0, 1)
	if dashType == 0 and not wallStick:
		direction = Input.get_axis("moveLeft", "moveRight")
	
	else:
		direction = facing
	
	if direction != 0:
		facing = direction
	
	#Activate correct body hitbox
	if facing == -1:
		hitbox_body_left.disabled = false
		hitbox_body_right.disabled = true
	
	else:
		hitbox_body_left.disabled = true
		hitbox_body_right.disabled = false
	
	#Handle Wall-Stick and apply movement
	if is_on_wall_only() and hasWallJump or wallStick:
		#Check if player is airdashing or not already stuck to a wall
		if (dashType >= 2 and dashType < 3) and not wallStick:
			#Check if dash is horizontal
			#Stick Right
			if dashType == 2.6:
				wallStick = true
				
				velocity = STOP
				wallStickRelease = WALL_STICK_RELEASE
			#Stick Left
			elif dashType == 2.4:
				wallStick = true
				
				velocity = STOP
				wallStickRelease = WALL_STICK_RELEASE
			#"Stick" Diagonal Up, conserve vertical momentum, still allow wall jumps
			elif (dashType == 2.9 or dashType == 2.7):
				wallStick = true
				
				velocity.x = 0
				wallStickRelease = WALL_STICK_RELEASE
			#Diagonal Down and straight down or up do not trigger wall stick
		
		#Decrement timer when stuck to a wall
		if wallStick:
				
			if wallStickRelease > 0:
				wallStickRelease -= 1
			
			else:
				wallStick = false
			
		else:
			wallStick = false
			wallStickRelease = 0
	
	#Handle dash countdowns and Dash-Landing
	if dashCountdown > DASH_RELEASE:
		#Disable foot hitbox and enable push boxes for Air-Dashes
		if dashType > 2:
			hitbox_feet.disabled = true
			foot_push_ray_right.disabled = false
			foot_push_ray_left.disabled = false
		
		#First tick of Dash Landing
		if grounded and dashType > 2 and dashType < 3:
			#Horizontal Dash-Land
			if dashType == 2.6 or dashType == 2.4:
				dashType = 3.0
			
			#Down-Right
			elif dashType == 2.3:
				dashType = 3.3
			
			#SPECIAL --------------------------------------------------
			#Down
			elif dashType == 2.2:
				dashType = 3.2
				leapCountdown = LEAP_COUNTDOWN
			
			#Down-Left
			elif dashType == 2.1:
				dashType = 3.1
			
			dashLand = true
			hitbox_feet.disabled = false
		
		#First and later ticks of Dash Landing
		if dashType >= 3:
			dashSpeedx = DASH_SPEED
		
		dashCountdown -= 1
	
	elif dashCountdown > 0:
		
		dashType = 0
		dashLand = false
		
		#Dash Jumping does not reset the countdown to keep the lower air resistance
		if not dashJump:
			if grounded:
				dashFriction = GROUNDDASH_FRICTION
				
			else:
				dashFriction = AIRDASH_FRICTION
				
			dashRelease = true
		
		hitbox_feet.disabled = false
		foot_push_ray_right.disabled = true
		foot_push_ray_left.disabled = true
		
		dashCountdown -= 1
		
	else:
		if grounded:
			hasAirdash = true
		
		dashRelease = false
		dashJump = false
		dashFriction = 1
		
		
		hitbox_feet.disabled = false
		foot_push_ray_left.disabled = true
		foot_push_ray_right.disabled = true
		walk_push_ray_left.disabled = false
		walk_push_ray_right.disabled = false
	
	#Handle leap countdown
	if leapCountdown > 0:
		leapCountdown -= 1
	
	
	#Handle dashes
	if dashBuffer > 0 and dashType == 0 and not dashRelease:
		dashBuffer = 0
		#Ground dash
		if grounded:
			#Crouch dash is shorter
			if crouching:
				dashCountdown = DASH_TIME - 5
				dashSpeedx = DASH_SPEED - 50
				dashType = 1.0
			#Normal Ground Dash
			else:
				dashCountdown = DASH_TIME
				dashSpeedx = DASH_SPEED
				dashType = 1.1
		#Set default airdash, get dash cardinal
		elif hasAirdash:
			dashCountdown = DASH_TIME
			dashCardinal = getCardinal()
			dashType = 2.0
			hasAirdash = false
		
		dashJump = false
		wallJumpCountdown = 0
	
		#Handle Wall Jump Countdown and Movement
	if wallJumpCountdown > 0:
		wallJumping = true
		
		dashCountdown = 0
		dashType = 0
		dashRelease = false
		
		wallJumpCountdown -= 1
	
	else:
		wallJumping = false
	
	# Handle Jumps and Dash-Jumps
	if jumpBuffer > 0 and grounded and dashType == 0:
		jumpBuffer = 0
		
		#If player is nearly stationary and Dash-Landed directly down
		if (velocity.x > -5 or velocity.x < 5) and leapCountdown > 0:
			leapCountdown = 0
			velocity.y = LEAP_VELOCITY
		
		elif crouching:
			if dashRelease: #Dash Hop
				dashJump = true
				
				dashRelease = false
				dashFriction = 0.1
			
			velocity.y = HOP_VELOCITY
			
		else:
			if dashRelease: #Dash Jump
				dashJump = true
				dashRelease = false
				dashFriction = 0.1
			
			velocity.y = JUMP_VELOCITY
			
		hasAirdash = true
	
	#Handle Wall-Jumps
	if jumpBuffer > 0 and wallStick and hasWallJump:
		hasAirdash = true
		hasWallJump = false
		wallStick = false
		
		wallJumpCountdown = WALL_JUMP_TIME
		
		dashCountdown = 0
		dashType = 0
		
		#30
		if inputVector == Vector2(-1, 1) or inputVector == Vector2(0, 1) or inputVector == Vector2(1, 1):
			print("30")
			velocity = Vector2(-facing * 468, -270)
		#60
		elif inputVector == Vector2(0, -1) or inputVector == Vector2(1, -1) or inputVector == Vector2(-1, -1):
			print("60")
			velocity = Vector2(-facing * 270, -381)
		else: #45
			print("45")
			velocity = Vector2(-facing * 381, -381)
	
	#Figure out if the player is turning (holding the direction they aren't moving)
	if (direction > 0 and velocity.x < 0) or (direction < 0 and velocity.x > 0):
		turning = true
	
	else:
		turning = false
	
	if turning and dashRelease:
		turningFactor = TURNING_ACCEL_FACTOR * .5
	
	elif turning:
		turningFactor = TURNING_ACCEL_FACTOR
	
	else:
		turningFactor = 1
	
	#Apply max horizontal speed
	if grounded:
		maxSpeedx = MAX_GROUND_SPEED * direction
	
	else:
		maxSpeedx = MAX_AIR_SPEED * direction
	
	gravity = GRAVITY
	#Apply max vertical speed and gravity
	if crouching:
		maxSpeedy = FASTFALL_SPEED
		gravity *= 1.5
	
	else:
		maxSpeedy = FALL_SPEED
	
	#Handle acceleration/decceleration
	if direction != 0:
		if grounded:
			accel = GROUND_ACCEL * turningFactor * dashFriction
		
		else:
			accel = AIR_ACCEL * turningFactor * dashFriction
		
	else:
		if grounded:
			accel = FRICTION * dashFriction
		
		else:
			accel = AIR_RESISTANCE * dashFriction
	
	#Flip sprite
	if facing > 0:
		playerSprite.flip_h = false
	elif facing < 0:
		playerSprite.flip_h = true
	
	#Play animations
	#TO DO: Add animations for: dashes, walljumps, dash slips, crouches, hops, dash jumps, jumps
	if dashType != 0:
		playerSprite.play("Dash")
	elif grounded:
		if direction == 0:
			playerSprite.play("Idle")
		else:
			playerSprite.play("Run")
	else:
		playerSprite.play("Jump")
	
	#Begin to Apply Movement
	
	#Wallstick
	if wallStick:
		pass
	#Handle air dash directions
	elif (dashType >= 2.0 and dashType < 3) and not dashRelease and not wallJumping:
		if dashCardinal[0] == 0 and dashCardinal[1] == 0:  
			dashCardinal[0] = facing
			
		if dashCardinal[0] > 0:
			if dashCardinal[1] < 0: #Up-right
				dashSpeedx = 297
				dashSpeedy = -297
				dashType = 2.9
				
			elif dashCardinal[1] > 0: #Down-right
				dashSpeedx = 297
				dashSpeedy = 297
				dashType = 2.3
				
			else: #right
				dashSpeedx = DASH_SPEED
				dashSpeedy = 0
				dashType = 2.6
				
		elif dashCardinal[0] < 0:
			if dashCardinal[1] < 0: #Up-left
				dashSpeedx = -297
				dashSpeedy = -297
				dashType = 2.7
				
			elif dashCardinal[1] > 0: #Down-left
				dashSpeedx = -297
				dashSpeedy = 297
				dashType = 2.1
				
			else: #left
				dashSpeedx = -DASH_SPEED
				dashSpeedy = 0
				dashType = 2.4
		else:
			if dashCardinal[1] < 0: #Up
				dashSpeedx = 0
				dashSpeedy = -297
				dashType = 2.8
				
			else: #Down
				dashSpeedx = 0
				dashSpeedy = DASH_SPEED
				dashType = 2.2
		
		velocity.x = dashSpeedx
		velocity.y = dashSpeedy
	
	#Apply movement for Grounded Dashes and Dash Lands
	elif dashType == 1.0 or dashType == 1.1:
		velocity.x = dashSpeedx * facing
		velocity.y = 0
	
	elif dashLand:
		if dashType == 3.3 or dashType == 3.1 or dashType == 3.0:
			velocity.x = dashSpeedx * facing
		
		elif dashType == 3.2:
			pass
	
	#Apply gravity for not dashing
	else:
		velocity.y = move_toward(velocity.y, maxSpeedy, gravity * delta)
		
		#Apply movement for holding a direction
		if direction != 0:
			#move from current veloxity to max by accel
			velocity.x = move_toward(velocity.x, maxSpeedx, accel * delta)
		#Apply movement for idling from motion
		else:
			velocity.x = move_toward(velocity.x, 0, accel * delta)
	
	move_and_slide()

func _process(delta: float) -> void:
	#Debug labels
	if Input.is_action_just_pressed("debug"):
		debugMenu *= -1
	
	if debugMenu > 0:
		game_manager.updateDebug(
			position.x,
			position.y,
			velocity.x,
			velocity.y,
			accel,
			gravity,
			direction,
			inputVector,
			facing,
			crouching,
			grounded,
			dashType,
			dashRelease,
			dashCountdown,
			dashJump,
			leapCountdown,
			dashLand,
			hasWallJump,
			wallStick,
			wallStickRelease,
			jumpBuffer,
			dashBuffer,
			)
	else:
		game_manager.closeDebug()
	
	#debug()
