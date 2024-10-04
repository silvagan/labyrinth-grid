extends Node2D
@export var grid_width = 16
@export var grid_height = 16
var world_grid = []
var offset_grid = []
var displace = 125
#func _ready():
	#DisplayServer.window_set_size(Vector2i(1000, 1000))
	#Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	#for i in grid_width:
		#world_grid.append([])
		#for j in grid_height:
			#world_grid[i].append(0)
	#for i in grid_width+1:
		#offset_grid.append([])
		#for j in grid_height+1:
			#offset_grid[i].append(0)
	#world_grid[1][1] = 1
	#queue_redraw()
#
#func _draw():
	#for i in range(0, 16):
		#for j in range(0, 16):
			#if (world_grid[i][j] != 0):
				#draw_circle(Vector2(i * 50 + displace, j * 50 + displace), 25, Color.RED)
			#else:
				#draw_circle(Vector2(i * 50 + displace, j * 50 + displace), 25, Color.BLUE)
	#for i in range(0, 17):
		#for j in range(0, 17):
			#draw_circle(Vector2(i * 50 + displace-25, j * 50 + displace-25), 25, Color.DARK_BLUE)
