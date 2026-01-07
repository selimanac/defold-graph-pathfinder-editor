local const = {}

local function split_csv(str)
	local t = {}
	for token in str:gmatch("[^,%s]+") do
		token = token:gsub('^"(.-)"$', '%1')
		t[#t + 1] = token
	end
	return t
end

const.EPSILON         = 0.0001

-- Timer delays
const.TIMER_DELAYS    = {
	STATUS_MESSAGE = 0.7, -- Auto-clear status messages
	AGENT_ERROR    = 1.5, -- Error message for agent
	GRAPH_LOAD     = 0.1 -- Delay before loading graph data
}

-- Agent configuration
const.AGENT_CONFIG_XY = {
	MAX_SPEED         = 500,
	ROTATION_SPEED    = 20.0,
	ARRIVAL_THRESHOLD = 1.0
}

const.AGENT_CONFIG_XZ = {
	MAX_SPEED         = 3.5,
	ROTATION_SPEED    = 20.0,
	ARRIVAL_THRESHOLD = 0.1
}

-- Plane configuration
local plane_setting   = sys.get_config_string("graph_editor.plane", "XZ"):upper()

-- Validate plane setting
if plane_setting ~= "XZ" and plane_setting ~= "XY" then
	error(string.format("Invalid plane configuration: '%s'. Must be 'XZ' or 'XY'", plane_setting))
end

const.PLANE_TYPE  = plane_setting -- "XZ" or "XY"
const.IS_XZ_PLANE = (plane_setting == "XZ")

-- Plane constants based on configuration
if const.IS_XZ_PLANE then
	-- XZ plane: Y is up, plane at Y=0
	const.PLANE_POINT   = vmath.vector3(0, 0, 0)
	const.PLANE_NORMAL  = vmath.vector3(0, 1, 0)
	const.PLANE_UP_AXIS = 1 -- Y axis index
	const.PLANE_H_AXIS  = 0 -- X axis index (horizontal)
	const.PLANE_V_AXIS  = 2 -- Z axis index (vertical on plane)
	const.COLLIDER_SIZE = vmath.vector3(0.1)
else
	-- XY plane: Z is up, plane at Z=0
	const.PLANE_POINT   = vmath.vector3(0, 0, 0)
	const.PLANE_NORMAL  = vmath.vector3(0, 0, 1)
	const.PLANE_UP_AXIS = 2 -- Z axis index
	const.PLANE_H_AXIS  = 0 -- X axis index (horizontal)
	const.PLANE_V_AXIS  = 1 -- Y axis index (vertical on plane)
	const.COLLIDER_SIZE = vmath.vector3(16)
end

const.EDITOR_STATES   = {
	ADD_NODE             = 1,
	REMOVE_NODE          = 2,
	MOVE_NODE            = 3,
	ADD_EDGE             = 4,
	REMOVE_EDGE          = 5,
	ADD_AGENT            = 6,
	ADD_DIRECTIONAL_EDGE = 7,
	--SELECT_NODE          = 8
}

const.PROJECT_NAME    = sys.get_config_string("project.title", "defold-graph-pathfinder-editor")

const.MOUSE           = "/graph_editor/mouse"
const.TRIGGERS        = {
	MOUSE_BUTTON_LEFT  = hash("mouse_button_left"),
	MOUSE_BUTTON_RIGHT = hash("mouse_button_right"),
	MOUSE_WHEEL_UP     = hash("mouse_wheel_up"),
	MOUSE_WHEEL_DOWN   = hash("mouse_wheel_down"),
	KEY_W              = hash("key_w"),
	KEY_A              = hash("key_a"),
	KEY_S              = hash("key_s"),
	KEY_D              = hash("key_d"),
	KEY_UP             = hash("key_up"),
	KEY_DOWN           = hash("key_down"),
	KEY_LEFT           = hash("key_left"),
	KEY_RIGHT          = hash("key_right"),
}

const.VIEWPORT_CAMERA = "/graph_editor/editor_camera#camera"
const.VIEWPORT        = "/graph_editor/editor_camera"

const.FACTORIES       = {
	NODE      = "/graph_editor/factories#node",
	AGENT     = "/graph_editor/factories#agent",
	DIRECTION = "/graph_editor/factories#direction",
}
const.GRAPH_EDITOR    = {
	MAX_NODES             = sys.get_config_int("graph_editor.max_nodes", 128),
	MAX_GAMEOBJECT_NODES  = sys.get_config_int("graph_editor.max_gameobject_nodes", 128),
	MAX_EDGES_PER_NODE    = sys.get_config_int("graph_editor.max_edges_per_node", 6),
	HEAP_POOL_BLOCK_SIZE  = sys.get_config_int("graph_editor.heap_pool_block_size", 128),
	MAX_CACHE_PATH_LENGTH = sys.get_config_int("graph_editor.max_cache_path_length", 128),
	FOLDER                = nil, -- Initialized in editor.init()
	FILES                 = split_csv(sys.get_config_string("graph_editor.files", "default.json"))
}

const.COLORS          = {
	RED   = vmath.vector4(1, 0, 0, 1),
	BLUE  = vmath.vector4(0, 0, 1, 1),
	GREEN = vmath.vector4(0, 1, 0, 1)
}

const.FILE_STATUS     = {
	SAVE_SUCCESS   = "...Saved!...",
	EXPORT_SUCCESS = "...Exported!...",
	SAVE_ERROR     = "...Can't save the file!...",
	EXPORT_ERROR   = "...Can't export the file!...",
	LOAD_SUCCESS   = "...Loaded!...",
	LOAD_ERROR     = "...Can't load the file!...",
	PREPARE        = "...Preparing Data..."
}

const.EDITOR_STATUS   = {
	ADD_NODE                             = "Click anywhere to add a node",
	REMOVE_NODE                          = "Select a node to remove",
	MOVE_NODE                            = "Select a node to move",
	ADD_EDGE_1                           = "Select the first node",
	ADD_EDGE_2                           = "Select the second node to connect",
	ADD_EDGE_ERROR                       = "Start node and end node cannot be the same",
	ADD_AGENT                            = "Click anywhere to add an agent",
	READY                                = "READY",
	SELECT_NODE                          = "Click to select a node",
	LOADING                              = "LOADING",
	RESET                                = "RESET",
	AGENT_MODE_FIND_PATH_LABEL           = "FIND PATH",
	AGENT_MODE_FIND_PROJECTED_PATH_LABEL = "FIND PROJECTED PATH",
	NO_PATH_FOR_AGENT                    = "No valid path for agent",
	REMOVE_EDGE                          = "Select a edge to remove"
}

const.AGENT_MODE      = {
	NODE_TO_NODE           = 1,
	PROJECTED_TO_NODE      = 2,
	NODE_TO_PROJECTED      = 3,
	PROJECTED_TO_PROJECTED = 4
}

const.AGENT_TO_PATH   = {
	"node_to_node",
	"projected_to_node",
	"node_to_projected",
	"projected_to_projected"
}



return const
