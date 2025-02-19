extends Node

var score = 0

@onready var score_label: Label = $"../Player/scoreLabel"
@onready var deathLabel: Label = $"../Player/deathLabel"
@onready var debugLabels: Label = $"../Player/debugLabels"

func die():
	deathLabel.text = "YOU DIED"

func addPoint():
	score += 1
	score_label.text = "Coins " + str(score)

func updateDebug(
		posX,
		posY,
		velX,
		velY,
		accel,
		direction,
		inputVector,
		facing,
		crouching,
		grounded,
		dashType,
		dashRelease,
		dashCountdown,
		dashJump,
		dashLand,
		hasWallJump,
		wallStick,
		wallStickRelease,
	):
	debugLabels.text = "Coordinates: (" + str(posX) + ", " + str(posY) + ")
	\nVelocity: (" + str(velX) + ", " + str(velY) + ")
	\nAcceleration: " +  str(accel) + "
	\nDirection: " + str(direction) + " Facing: " + str(facing) + " Input Vector: " + str(inputVector) + "
	\nCrouching = " +str(crouching) + "
	\nGrounded = " +str(grounded) + "
	\nDash Type = " + str(dashType) + "
	\nDash Countdown = " + str(dashCountdown) + "
	\nDash Release = " + str(dashRelease) + "
	\nDash Jump = " + str(dashJump) + "
	\nDash Land = " + str(dashLand) + "
	\nHas Wall Jump = " + str(hasWallJump) + "
	\nWall Stick = " + str(wallStick) + "dDDdddddd Wall Stick Release = " + str(wallStickRelease)

func closeDebug():
	debugLabels.text = ""
