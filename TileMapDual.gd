@tool #for live editing in editor
class_name TileMapDual
extends TileMapLayer

@export var world_tilemap: TileMapLayer = null
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

func _ready() -> void:
	if freeze:
		return
	
	if debug:
		print('Updating in-game is activated')
	
	update_tileset()
	

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
			return false
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
