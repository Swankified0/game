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
	):
	debugLabels.text = "Coordinates: (" + str(posX) + ", " + str(posY) + ")
	\nVelocity: (" + str("%05.2f" % velX) + ", " + str("%05.2f" % velY) + ")
	\nAcceleration: " +  str("%05.2f" % accel) + ", Gravity: " + str("%05.2f" % gravity) + "
	\nDirection: " + str(direction) + ", Facing: " + str(facing) + ", Input Vector: " + str(inputVector) + "
	\nCrouching = " +str(crouching) + ", Grounded = " +str(grounded) + "
	\nDash Type = " + str("%03.1f" % dashType) + " Dash Countdown = " + str(dashCountdown) + " Dash Release = " + str(dashRelease) + ", Leap Countdown = " + str(leapCountdown) + "
	\nDash Jump = " + str(dashJump) + ", Dash Land = " + str(dashLand) + "
	\nHas Wall Jump = " + str(hasWallJump) + "
	\nWall Stick = " + str(wallStick) + ", Wall Stick Release = " + str(wallStickRelease) + "
	\nBuffers: Jump = " + str(jumpBuffer) + ", Dash Buffer = " + str(dashBuffer) + "
	\n"

func closeDebug():
	debugLabels.text = ""
