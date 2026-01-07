local const             = require("graph_editor.scripts.editor_const")
local data              = require("graph_editor.scripts.editor_data")
local collision         = require("graph_editor.scripts.editor_collision")
local agents            = require("graph_editor.scripts.editor_agents")
local utils             = require("graph_editor.scripts.editor_utils")

-- =======================================
-- MODULE
-- =======================================
local graph             = {}

-- =======================================
-- VARIABLES
-- =======================================
local bindings          = {}
local edge_nodes        = {}
local edge_select_count = 0
local is_node_moving    = false


function graph.clear()
	edge_nodes            = {}
	edge_select_count     = 0
	data.is_node_selected = false
	data.selected_node    = {}
	is_node_moving        = false
end

---- AGENTS
local function add_agent()
	agents.add()
end

---- EDGES
local function add_edge_collider(uuid, from_node_id, to_node_id)
	local from_node_position               = pathfinder.get_node_position(from_node_id)
	local to_node_position                 = pathfinder.get_node_position(to_node_id)
	local center, width, height            = utils.rect_from_points(from_node_position, to_node_position)
	local edge_aabb_id                     = collision.insert_aabb(center, width, 1, height, collision.COLLISION_BITS.EDGE)

	data.lookup.aabb_to_edge[edge_aabb_id] = uuid
	return edge_aabb_id
end

local function add_edge(bidirectional)
	local is_bidirectional = (bidirectional == nil) and true or bidirectional

	local result, _ = collision.query_mouse_node()
	if not result then
		return
	end

	local node = utils.get_node_from_aabb(result[1])
	if not node then
		return
	end

	edge_select_count = edge_select_count + 1
	if edge_select_count == 1 then
		data.action_status = const.EDITOR_STATUS.ADD_EDGE_2
	end
	edge_nodes[edge_select_count] = node.pathfinder_node_id

	if edge_nodes[1] == edge_nodes[2] then
		data.action_status = const.EDITOR_STATUS.ADD_EDGE_ERROR
	end

	if edge_select_count == 2 then
		edge_select_count  = 0

		data.action_status = const.EDITOR_STATUS.ADD_EDGE_1
		local from_node_id = edge_nodes[1]
		local to_node_id   = edge_nodes[2]
		pathfinder.add_edge(from_node_id, to_node_id, is_bidirectional)
		local edge_uuid    = uuid4.generate()
		local edge_aabb_id = add_edge_collider(edge_uuid, from_node_id, to_node_id)
		local edge         = { from_node_id = edge_nodes[1], to_node_id = edge_nodes[2], bidirectional = is_bidirectional, uuid = edge_uuid, aabb_id = edge_aabb_id }

		if not is_bidirectional then
			utils.add_edge_directions(edge)
		end

		data.edges[edge.uuid] = edge

		local from_node       = utils.get_node_from_pathfinder_id(edge_nodes[1])
		local to_node         = utils.get_node_from_pathfinder_id(edge_nodes[2])

		if from_node then
			from_node.edges[edge.uuid] = "from_node_id"
		end
		if to_node then
			to_node.edges[edge.uuid] = "to_node_id"
		end

		edge_nodes = {}
	end
end

local function add_directional_edge()
	add_edge(false)
end

local function remove_edge()
	local result, _ = collision.query_mouse_edge()
	if result then
		local edge = utils.get_edge_from_aabb(result[1].id)
		utils.remove_edge(edge)
	end
end

---- NODES
local function remove_node()
	local result, _ = collision.query_mouse_node()
	if not result then
		return
	end

	local node = utils.get_node_from_aabb(result[1])
	if not node then
		return
	end

	pathfinder.remove_node(node.pathfinder_node_id)
	collision.remove(node.aabb_id)
	go.delete(node.url)
	utils.remove_node_edges(node)
	utils.remove_node_with_aabb(result[1])
end

local function move_node()
	local result, _ = collision.query_mouse_node()

	if result then
		data.selected_node    = utils.get_node_from_aabb(result[1])
		data.is_node_selected = true
		is_node_moving        = true
	else
		data.selected_node    = {}
		data.is_node_selected = false
		is_node_moving        = false
	end
end

local function add_node(loaded_node)
	loaded_node = loaded_node and loaded_node or nil

	local node_position = data.mouse_position

	if loaded_node then
		node_position = loaded_node.position --table_to_vec3(node.position)
	end

	if node_position == nil then
		return
	end

	local path_x, path_y = utils.vec3_to_pathfinder(node_position)
	local node_url = factory.create(const.FACTORIES.NODE, utils.pathfinder_to_vec3(path_x, path_y))
	local label_url = msg.url(node_url)
	label_url.fragment = "label"

	local temp_node = {
		position = node_position,
		aabb_id = collision.insert_gameobject(node_url, const.COLLIDER_SIZE.x, const.COLLIDER_SIZE.y, const.COLLIDER_SIZE.z, collision.COLLISION_BITS.NODE),
		pathfinder_node_id = pathfinder.add_node(path_x, path_y),
		url = node_url,
		label_url = label_url,
		edges = (loaded_node and loaded_node.edges) or {},
		uuid = (loaded_node and loaded_node.uuid) or uuid4.generate()
	}
	label.set_text(label_url, temp_node.pathfinder_node_id)
	data.nodes[temp_node.uuid] = temp_node
	data.lookup.aabb_to_node[temp_node.aabb_id] = temp_node.uuid               -- AABB Reference
	data.lookup.pathfinder_to_node[temp_node.pathfinder_node_id] = temp_node.uuid -- Pathfinder Reference

	-- From Loaded
	if loaded_node then
		if loaded_node.edges and type(loaded_node.edges) == "table" then
			for key, edge_type in pairs(temp_node.edges) do
				-- Validate edge exists in data.edges before accessing
				if data.edges[key] then
					data.edges[key][edge_type] = temp_node.pathfinder_node_id
				else
					pprint("Warning: Edge not found in data.edges:", key)
				end
			end
		end
	end
end

local function add_bindings()
	-- NODES
	bindings[const.EDITOR_STATES.ADD_NODE]             = add_node
	bindings[const.EDITOR_STATES.MOVE_NODE]            = move_node
	bindings[const.EDITOR_STATES.REMOVE_NODE]          = remove_node

	-- EDGES
	bindings[const.EDITOR_STATES.ADD_EDGE]             = add_edge
	bindings[const.EDITOR_STATES.ADD_DIRECTIONAL_EDGE] = add_directional_edge
	bindings[const.EDITOR_STATES.REMOVE_EDGE]          = remove_edge

	-- AGENTS
	bindings[const.EDITOR_STATES.ADD_AGENT]            = add_agent
end

-- =======================================
-- INIT
-- =======================================
function graph.init()
	data.action_status = const.EDITOR_STATUS.READY
	collision.init()
	pathfinder.init(const.GRAPH_EDITOR.MAX_NODES, const.GRAPH_EDITOR.MAX_GAMEOBJECT_NODES, const.GRAPH_EDITOR.MAX_EDGES_PER_NODE, const.GRAPH_EDITOR.HEAP_POOL_BLOCK_SIZE, const.GRAPH_EDITOR.MAX_CACHE_PATH_LENGTH)

	add_bindings()
	data.path_smoothing_id = pathfinder.add_path_smoothing(data.options.smoothing_config)
end

-- =======================================
-- INPUT
-- =======================================
function graph.input(action_id, action)
	if data.want_mouse_input then -- Mouse on imgui window
		return
	end

	if data.is_node_selected and is_node_moving then -- moving a node
		utils.move_selected_node(data.mouse_position)
	end

	if action_id == const.TRIGGERS.MOUSE_BUTTON_LEFT and action.released and data.is_node_selected then
		is_node_moving = false
		utils.update_node(data.mouse_position)
	end

	if action_id == const.TRIGGERS.MOUSE_BUTTON_LEFT and action.pressed then
		if bindings[data.editor_state] then
			local action_call = bindings[data.editor_state]
			action_call()
		end
	end
end

-- =======================================
-- RESET
-- =======================================
function graph.reset()
	graph.clear()
	data.action_status = const.EDITOR_STATUS.RESET
	collision.reset()
	pathfinder.shutdown()

	for _, node in pairs(data.nodes) do
		go.delete(node.url)
	end

	for _, edge in pairs(data.edges) do
		if not edge.bidirectional then
			go.delete(edge.url)
		end
	end

	data.nodes         = {}
	data.edges         = {}
	data.lookup        = {
		aabb_to_node = {},
		aabb_to_edge = {},
		pathfinder_to_node = {}
	}

	data.action_status = const.EDITOR_STATUS.READY
end

-- =======================================
-- LOAD
-- =======================================
function graph.load(loaded_data)
	data.action_status = const.EDITOR_STATUS.LOADING

	-- Validate loaded data exists and has required fields
	if not loaded_data then
		pprint("Error: loaded_data is nil")
		data.action_status = const.EDITOR_STATUS.READY
		return
	end

	if not loaded_data.nodes or type(loaded_data.nodes) ~= "table" then
		pprint("Error: loaded_data.nodes is missing or invalid")
		data.action_status = const.EDITOR_STATUS.READY
		return
	end

	if not loaded_data.edges or type(loaded_data.edges) ~= "table" then
		pprint("Error: loaded_data.edges is missing or invalid")
		data.action_status = const.EDITOR_STATUS.READY
		return
	end

	graph.reset()
	graph.init()

	-- Delay to prevent same frame ops
	timer.delay(const.TIMER_DELAYS.GRAPH_LOAD, false, function()
		-- Store edges safely
		data.edges = loaded_data.edges

		-- sort loaded nodes
		local nodes = loaded_data.nodes
		local order = {}

		for uuid, _ in pairs(nodes) do
			order[#order + 1] = uuid
		end

		-- Sort UUIDs by node.pathfinder_node_id
		table.sort(order, function(a, b)
			local node_a = nodes[a]
			local node_b = nodes[b]

			-- Safety check for node existence and pathfinder_node_id
			if not node_a or not node_a.pathfinder_node_id then
				return false
			end
			if not node_b or not node_b.pathfinder_node_id then
				return true
			end

			return node_a.pathfinder_node_id < node_b.pathfinder_node_id
		end)

		-- Add nodes
		for _, uuid in ipairs(order) do
			local node = nodes[uuid]

			-- Validate node before adding
			if node and node.pathfinder_node_id and node.position then
				-- Ensure edges table exists
				if not node.edges then
					node.edges = {}
				end

				add_node(node)
			else
				pprint("Warning: Skipping invalid node:", uuid)
			end
		end

		-- Add edges
		local temp_edges = {}
		for uuid, edge in pairs(data.edges) do
			-- Validate edge has required fields
			if edge and edge.from_node_id and edge.to_node_id then
				local success, result = pcall(function()
					return add_edge_collider(edge.uuid or uuid, edge.from_node_id, edge.to_node_id)
				end)

				if success then
					edge.aabb_id = result

					if not edge.bidirectional then
						local dir_success, dir_error = pcall(utils.add_edge_directions, edge)
						if not dir_success then
							pprint("Warning: Failed to add edge direction:", dir_error)
						end
					end

					table.insert(temp_edges, edge)
				else
					pprint("Warning: Failed to add edge collider for:", uuid, result)
				end
			else
				pprint("Warning: Skipping invalid edge:", uuid)
			end
		end

		-- Add edges to pathfinder with error handling
		if #temp_edges > 0 then
			local add_edges_success, add_edges_error = pcall(pathfinder.add_edges, temp_edges)
			if not add_edges_success then
				pprint("Error adding edges to pathfinder:", add_edges_error)
			end
		end
	end)

	data.action_status = const.EDITOR_STATUS.READY
end

return graph
