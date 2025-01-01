extends Camera2D


var velocity: Vector2 = Vector2(0,0)

func _process(delta):
	#vertical movement
	if (Input.is_action_pressed("camera_up")):
		if(velocity.y > 0):
			velocity.y = lerpf(velocity.y, 0, delta*6)
			velocity.y -= 20*delta
		else:
			velocity.y -= 40*delta
	if (Input.is_action_pressed("camera_down")):
		if(velocity.y < 0):
			velocity.y = lerpf(velocity.y, 0, delta*6)
			velocity.y += 20*delta
		else:
			velocity.y += 40*delta
	elif (!Input.is_action_pressed("camera_up")):
		velocity.y = lerpf(velocity.y, 0, delta)
		
	#horizontal movement
	if (Input.is_action_pressed("camera_left")):
		if(velocity.x > 0):
			velocity.x = lerpf(velocity.x, 0, delta*6)
			velocity.x -= 20*delta
		else:
			velocity.x -= 40*delta
	if (Input.is_action_pressed("camera_right")):
		if(velocity.x < 0):
			velocity.x = lerpf(velocity.x, 0, delta*6)
			velocity.x += 20*delta
		else:
			velocity.x += 40*delta
	elif (!Input.is_action_pressed("camera_left")):
		velocity.x = lerpf(velocity.x, 0, delta)
	
	#update position according to velocity
	self.position += velocity*delta*100
