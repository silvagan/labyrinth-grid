@tool #for live editing in editor
class_name TileMapDual
extends TileMapLayer

@export var wall_height:float = 1.5
@export var vpdistance_multiplier:float = 1

@export var world_tilemap: TileMapLayer = null
@onready var canvas_layer = $"../CanvasLayer"
## Click to update the tilemap inside the editor.
## Make sure that the Freeze option is not checked!
@export var update_in_editor: bool = true:
	set(value):
		update_tileset()
## Clean all the drawn tiles from the TileMapDual node.
@export var clean: bool = false:
	set(value):
		self.clear()
## Stop any incoming updates of the dual tilemap,
## freezing it in its current state.
@export var freeze: bool = false
## Print debug messages. Lots of them.
@export var debug: bool = false

enum location {
	TOP_LEFT  = 1,
	LOW_LEFT  = 2,
	TOP_RIGHT = 4,
	LOW_RIGHT = 8
	}
	
const NEIGHBOURS := {
	location.TOP_LEFT  : Vector2i(0,0),
	location.LOW_LEFT  : Vector2i(0,1),
	location.TOP_RIGHT : Vector2i(1,0),
	location.LOW_RIGHT : Vector2i(1,1)
	}
	
## Dict to assign the Atlas coordinates from the
## summation over all sketched NEIGHBOURS.
## Follows the official 2x2 template.
############ SHOULD ALSO WORK FOR ISOMETRIC
const NEIGHBOURS_TO_ATLAS: Dictionary = {
	 0: Vector2i(0,3),
	 1: Vector2i(3,3),
	 2: Vector2i(0,0),
	 3: Vector2i(3,2),
	 4: Vector2i(0,2),
	 5: Vector2i(1,2),
	 6: Vector2i(2,3),
	 7: Vector2i(3,1),
	 8: Vector2i(1,3),
	 9: Vector2i(0,1),
	10: Vector2i(3,0),
	11: Vector2i(2,0),
	12: Vector2i(1,0),
	13: Vector2i(2,2),
	14: Vector2i(1,1),
	15: Vector2i(2,1)
	}
	
# Base vertices for calculating the starting point of wall meshes
const BASE_VERTICES: Dictionary = {
	0: [Vector2(0,0.5), Vector2(0.5,0.5), Vector2(0.5,1), Vector2(0,1)],
	1: [Vector2(0.5,0), Vector2(1,0), Vector2(1,1), Vector2(0.5,1)],
	2: [Vector2(0,0), Vector2(0.5,0), Vector2(0.5,0.5), Vector2(1,1), Vector2(0,1)],
	3: [Vector2(0,0.5), Vector2(1,0.5), Vector2(1,1), Vector2(0,1)],
	4: [Vector2(0,0), Vector2(0.5,0), Vector2(0.5,0.5), Vector2(1,0.5), Vector2(1,1), Vector2(0.5,1), Vector2(0.5,0.5), Vector2(0,0.5)],
	5: [Vector2(0.5,0), Vector2(1,0), Vector2(1,1), Vector2(0,1), Vector2(0,0.5), Vector2(0.5,0.5)],
	6: [Vector2(0,0), Vector2(1,0), Vector2(1,1), Vector2(0,1)], 			#FULL
	7: [Vector2(0,0), Vector2(1,0), Vector2(1,0.5), Vector2(0.5,0.5), Vector2(0.5,1), Vector2(0,1)],
	8: [Vector2(0.5,0), Vector2(1,0), Vector2(1,0.5), Vector2(0.5, 0.5)],
	9: [Vector2(0,0), Vector2(1,0), Vector2(1,0.5), Vector2(0,0.5)],
	10: [Vector2(0,0), Vector2(1,0), Vector2(1,1), Vector2(0.5,1), Vector2(0.5,0.5), Vector2(0,0.5)],
	11: [Vector2(0,0), Vector2(0.5,0), Vector2(0.5,1), Vector2(0,1)],
	12: [], 																#EMPTY
	13: [Vector2(0.5,0.5), Vector2(1,0.5), Vector2(1,1), Vector2(0.5,1)],
	14: [Vector2(0.5,0), Vector2(1,0), Vector2(1,0.5), Vector2(0.5,0.5), Vector2(0.5,1), Vector2(0,1), Vector2(0,0.5), Vector2(0.5,0.5)],
	15: [Vector2(0,0), Vector2(0.5,0), Vector2(0.5,0.5), Vector2(0,0.5)]
	}

const BASE_VERTICES_PRIMITIVE_TRI: Dictionary = {
	0: [Vector2(0,0.5), Vector2(0.5,0.5), Vector2(0.5,1), Vector2(0.5,1), Vector2(0,1), Vector2(0,0.5)],
	1: [Vector2(0.5,0), Vector2(1,0), Vector2(1,1), Vector2(1,1), Vector2(0.5,1), Vector2(0.5,0)],
	2: [Vector2(0,0), Vector2(0.5,0), Vector2(0.5,0.5), Vector2(0.5,0.5), Vector2(1,0.5), Vector2(1,1),Vector2(1,1), Vector2(0,1), Vector2(0,0)],
	3: [Vector2(0,0.5), Vector2(1,0.5), Vector2(1,1), Vector2(1,1), Vector2(0,1), Vector2(0,0.5)],
	4: [Vector2(0,0), Vector2(0.5,0), Vector2(0.5,0.5), Vector2(0.5,0.5), Vector2(1,0.5), Vector2(1,1), Vector2(1,1), Vector2(0.5,1), Vector2(0.5,0.5), Vector2(0.5,0.5), Vector2(0,0.5), Vector2(0,0)],
	5: [Vector2(0.5,0.5), Vector2(0.5,0), Vector2(1,0), Vector2(1,0), Vector2(1,1), Vector2(0,1), Vector2(0,1), Vector2(0,0.5), Vector2(0.5,0.5)],
	6: [Vector2(0,0), Vector2(1,0), Vector2(1,1), Vector2(1,1), Vector2(0,1), Vector2(0,0)], 			#FULL
	7: [Vector2(0.5,0.5), Vector2(0.5,1), Vector2(0,1), Vector2(0,1), Vector2(0,0), Vector2(1,0), Vector2(1,0), Vector2(1,0.5), Vector2(0.5,0.5)],
	8: [Vector2(0.5,0), Vector2(1,0), Vector2(1,0.5), Vector2(1,0.5), Vector2(0.5, 0.5), Vector2(0.5,0)],
	9: [Vector2(0,0), Vector2(1,0), Vector2(1,0.5), Vector2(1,0.5), Vector2(0,0.5), Vector2(0,0)],
	10: [Vector2(0,0), Vector2(1,0), Vector2(1,1), Vector2(1,1), Vector2(0.5,1), Vector2(0.5,0.5), Vector2(0.5,0.5), Vector2(0,0.5), Vector2(0,0)],
	11: [Vector2(0,0), Vector2(0.5,0), Vector2(0.5,1), Vector2(0.5,1), Vector2(0,1), Vector2(0,0)],
	12: [], 																#EMPTY
	13: [Vector2(0.5,0.5), Vector2(1,0.5), Vector2(1,1), Vector2(1,1), Vector2(0.5,1), Vector2(0.5,0.5)],
	14: [Vector2(0.5,0.5), Vector2(0.5,1), Vector2(0,1), Vector2(0,1), Vector2(0,0.5), Vector2(0.5,0.5), Vector2(0.5,0.5), Vector2(0.5,0), Vector2(1,0), Vector2(1,0), Vector2(1,0.5), Vector2(0.5,0.5)],
	15: [Vector2(0,0), Vector2(0.5,0), Vector2(0.5,0.5), Vector2(0.5,0.5), Vector2(0,0.5), Vector2(0,0)]
	}
	
## Coordinates for the fully-filled tile in the Atlas
## that will be used to sketch in the World grid.
## Defaults to the one in the standard Godot template.
## Only this tile will be considered for autotiling.
var full_tile: Vector2i = Vector2i(2,1)
## The opposed of full_tile.
## Used in-game to erase sketched tiles.
var empty_tile: Vector2i = Vector2i(0,3)
## Prevents checking the cells more than once
## when the entire tileset is being updated,
## which is indicated by checked_cells[0]=true.
## checked_cells[0]=false to overpass this check. 
var checked_cells: Array = [false]
## Keep track of the atlas ID
var _atlas_id: int

var tile_size = 128;

var orthographic = false;

var height = 1.0
var vpm = 1.0

func _physics_process(delta: float) -> void:
	update_3D()
	if (Input.is_action_just_pressed("switch_view")):
		if (orthographic):
			orthographic = false
		else:
			orthographic = true
	
	if (!orthographic):
		height = lerp(height, wall_height, 0.5)
	if (orthographic):
		height = lerp(height, 1.0, 0.5)

func _ready() -> void:
	if freeze:
		return
	
	if debug:
		print('Updating in-game is activated')
	InputMap.load_from_project_settings()
	update_tileset()
	update_3D()
	
func update_3D():
	for n in canvas_layer.get_children():
		canvas_layer.remove_child(n)
		n.queue_free()
	
	var temp = self.get_used_cells().size()
	for _world_cell in self.get_used_cells():
		var c = self.get_cell_atlas_coords(_world_cell)
		var _atlas = c.x + c.y * 4
		if (_atlas != -1):
			var m = MeshInstance2D.new()
			var vertices = PackedVector2Array()
			for vert in BASE_VERTICES_PRIMITIVE_TRI[_atlas]:
				vertices.push_back(vert * tile_size + Vector2(_world_cell * tile_size) - Vector2(64, 64))
			var count = vertices.size()
			var pos = $"../Camera2D".position*vpm
			for i in range(0,count):
				vertices.push_back((vertices[i] - pos) * height + pos)
			
			var arr = BASE_VERTICES[_atlas]
			for i in range(0, arr.size()-1):
				vertices.push_back(arr[i]* tile_size + Vector2(_world_cell * tile_size) - Vector2(64, 64))
				vertices.push_back(arr[i+1]* tile_size + Vector2(_world_cell * tile_size) - Vector2(64, 64))
				vertices.push_back((arr[i] * tile_size + Vector2(_world_cell * tile_size) - Vector2(64, 64) - pos) * height + pos)
				vertices.push_back((arr[i] * tile_size + Vector2(_world_cell * tile_size) - Vector2(64, 64) - pos) * height + pos)
				vertices.push_back((arr[i+1] * tile_size + Vector2(_world_cell * tile_size) - Vector2(64, 64) - pos) * height + pos)
				vertices.push_back(arr[i+1]* tile_size + Vector2(_world_cell * tile_size) - Vector2(64, 64))
			vertices.push_back(arr[arr.size()-1]* 	tile_size + Vector2(_world_cell * tile_size) - Vector2(64, 64))
			vertices.push_back(arr[0]* 				tile_size + Vector2(_world_cell * tile_size) - Vector2(64, 64))
			vertices.push_back((arr[arr.size()-1] * tile_size + Vector2(_world_cell * tile_size) - Vector2(64, 64) - pos) * height + pos)
			vertices.push_back((arr[arr.size()-1] * tile_size + Vector2(_world_cell * tile_size) - Vector2(64, 64) - pos) * height + pos)
			vertices.push_back((arr[0] * 			tile_size + Vector2(_world_cell * tile_size) - Vector2(64, 64) - pos) * height + pos)
			vertices.push_back(arr[0]* 	tile_size + Vector2(_world_cell * tile_size) - Vector2(64, 64))

			# Initialize the ArrayMesh.
			var arr_mesh = ArrayMesh.new()
			var arrays = []
			arrays.resize(Mesh.ARRAY_MAX)
			arrays[Mesh.ARRAY_VERTEX] = vertices

			# Create the Mesh.
			arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
			m.mesh = arr_mesh
			m.texture = Texture2D.new()
			m.set_modulate(Color(0.5,0.5,0.5))
			canvas_layer.add_child(m)

## Update the entire tileset resource from the dual grid.
## Copies the tileset resource from the world grid,
## displaces itself by half a tile, and updates all tiles.
func update_tileset() -> void:
	if freeze:
		return
	
	if world_tilemap == null:
		if debug:
			print('WARNING: No TileMapLayer connected!')
		return
	
	if debug:
		print('tile_set.tile_shape = ' + str(world_tilemap.tile_set.tile_shape))
	
	self.tile_set = world_tilemap.tile_set
	
	self.position.x = - self.tile_set.tile_size.x * 0.5
	self.position.y = - self.tile_set.tile_size.y * 0.5
	_update_tiles()
	
## Update all displayed tiles from the dual grid.
## It will only process fully-filled tiles from the world grid.
func _update_tiles() -> void:
	if debug:
		print('Updating tiles....................')
	
	self.clear()
	checked_cells = [true]
	var temp = world_tilemap.get_used_cells().size()
	for _world_cell in world_tilemap.get_used_cells():
		if _is_world_tile_sketched(_world_cell):
			update_tile(_world_cell)
	# checked_cells will only be used when updating
	# the entire tilemap to avoid repeating checks.
	# This check is skipped when updating tiles individually.
	checked_cells = [false]
	
## Takes a world cell, and updates the
## overlapping tiles from the dual grid accordingly.
func update_tile(world_cell: Vector2i) -> void:
	if freeze:
		return
	
	# Get the atlas ID of this world cell before
	# updating the corresponding tiles
	_atlas_id = world_tilemap.get_cell_source_id(world_cell)
	
	if debug:
		print('  Updating displayed cells around world cell ' + str(world_cell) + ' with atlas ID ' + str(_atlas_id) + '...')
	
	# Calculate the overlapping cells from the dual grid and update them accordingly
	var _top_left = world_cell + NEIGHBOURS[location.TOP_LEFT]
	var _low_left = world_cell + NEIGHBOURS[location.LOW_LEFT]
	var _top_right = world_cell + NEIGHBOURS[location.TOP_RIGHT]
	var _low_right = world_cell + NEIGHBOURS[location.LOW_RIGHT]
	_update_displayed_tile(_top_left)
	_update_displayed_tile(_low_left)
	_update_displayed_tile(_top_right)
	_update_displayed_tile(_low_right)

func _update_displayed_tile(_display_cell: Vector2i) -> void:
	# Avoid updating cells more than necessary
	if checked_cells[0] == true:
		if _display_cell in checked_cells:
			return
		checked_cells.append(_display_cell)
	
	if debug:
		print('    Checking display tile ' + str(_display_cell) + '...')
	
	# INFO: To get the world cells from the dual grid, we apply the opposite vectors
	var _top_left = _display_cell - NEIGHBOURS[location.LOW_RIGHT]  # - (1,1)
	var _low_left = _display_cell - NEIGHBOURS[location.TOP_RIGHT]  # - (1,0)
	var _top_right = _display_cell - NEIGHBOURS[location.LOW_LEFT]  # - (0,1)
	var _low_right = _display_cell - NEIGHBOURS[location.TOP_LEFT]  # - (0,0)
	
	# We perform a bitwise summation over the sketched neighbours
	var _tile_key: int = 0
	if _is_world_tile_sketched(_top_left):
		_tile_key += location.TOP_LEFT
	if _is_world_tile_sketched(_low_left):
		_tile_key += location.LOW_LEFT
	if _is_world_tile_sketched(_top_right):
		_tile_key += location.TOP_RIGHT
	if _is_world_tile_sketched(_low_right):
		_tile_key += location.LOW_RIGHT
	
	var _coords_atlas: Vector2i = NEIGHBOURS_TO_ATLAS[_tile_key]
	self.set_cell(_display_cell, _atlas_id, _coords_atlas)
	if debug:
		print('    Display tile ' + str(_display_cell) + ' updated with key ' + str(_tile_key))
		
func _is_world_tile_sketched(_world_cell: Vector2i) -> bool:
	var _atlas_coords = world_tilemap.get_cell_atlas_coords(_world_cell)
	if _atlas_coords == full_tile:
		if debug:
			print('      World cell ' + str(_world_cell) + ' IS sketched with atlas coords ' + str(_atlas_coords))
		return true
	else:
		# If the cell is empty, get_cell_atlas_coords() returns (-1,-1)
		if Vector2(_atlas_coords) == Vector2(-1,-1):
			if debug:
				print('      World cell ' + str(_world_cell) + ' Is EMPTY')
			return true
		if debug:
			print('      World cell ' + str(_world_cell) + ' Is NOT sketched with atlas coords ' + str(_atlas_coords))
		return false
		
## Public method to add a tile in a given World cell
func fill_tile(world_cell, atlas_id=0) -> void:
	if freeze:
		return
	
	if world_tilemap == null:
		if debug:
			print('WARNING: No TileMapLayer connected!')
		return
	
	world_tilemap.set_cell(world_cell, atlas_id, full_tile)
	update_tile(world_cell)


## Public method to erase a tile in a given World cell
func erase_tile(world_cell, atlas_id=0) -> void:
	if freeze:
		return
	
	if world_tilemap == null:
		if debug:
			print('WARNING: No TileMapLayer connected!')
		return
	
	world_tilemap.set_cell(world_cell, atlas_id, empty_tile)
	update_tile(world_cell)
