local const         = {}

const.EDITOR_STATES = {
	ADD_NODE             = 1,
	REMOVE_NODE          = 2,
	MOVE_NODE            = 3,
	ADD_EDGE             = 4,
	REMOVE_EDGE          = 5,
	ADD_AGENT            = 6,
	ADD_DIRECTIONAL_EDGE = 7
}

const.CAMERA        = "/graph_editor/camera#camera"
const.MOUSE         = "/graph_editor/mouse"
const.TRIGGERS      = {
	MOUSE_BUTTON_LEFT = hash("mouse_button_left")
}
const.FACTORIES     = {
	NODE      = "/graph_editor/factories#node",
	AGENT     = "/graph_editor/factories#agent",
	DIRECTION = "/graph_editor/factories#direction",
}
const.GRAPH         = {
	MAX_NODES             = sys.get_config_int("graph_editor.max_nodes", 32),
	MAX_GAMEOBJECT_NODES  = sys.get_config_int("graph_editor.max_nodes", 32),
	MAX_EDGES_PER_NODE    = sys.get_config_int("graph_editor.max_edges_per_node", 6),
	HEAP_POOL_BLOCK_SIZE  = sys.get_config_int("graph_editor.heap_pool_block_size", 32),
	MAX_CACHE_PATH_LENGTH = sys.get_config_int("graph_editor.max_cache_path_length", 32),
}
const.COLORS        = {
	RED   = vmath.vector3(1, 0, 0),
	BLUE  = vmath.vector3(0, 0, 1),
	GREEN = vmath.vector3(0, 1, 0)
}
const.FILE_STATUS   = {
	SAVE_SUCCESS = "...Saved!...",
	SAVE_ERROR   = "...Can't save the file!...",
	LOAD_SUCCESS = "...Loaded!...",
	LOAD_ERROR   = "...Can't load the file!...",
	PREPARE      = "...Preparing Data..."
}

const.EDITOR_STATUS = {
	ADD_NODE = "Click anywhere to add a node",
	REMOVE_NODE = "Select a node to remove",
	MOVE_NODE = "Select a node to move",
	ADD_EDGE_1 = "Select the first node",
	ADD_EDGE_2 = "Select the second node to connect",
	ADD_EDGE_ERROR = "Start node and end node cannot be the same",
	ADD_AGENT = "Click anywhere to add an agent"
}

return const
