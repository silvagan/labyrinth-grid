extends Camera2D

func _process(delta):
	if (Input.is_action_pressed("camera_up")):
		self.position.y += -5
	if (Input.is_action_pressed("camera_left")):
		self.position.x += -5
	if (Input.is_action_pressed("camera_down")):
		self.position.y += 5
	if (Input.is_action_pressed("camera_right")):
		self.position.x += 5
