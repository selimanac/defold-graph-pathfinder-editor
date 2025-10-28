local const = require("graph_editor.scripts.const")
local data = require("graph_editor.scripts.data")
local collision = require("graph_editor.scripts.collision")
local agents = require("graph_editor.scripts.agents")
-- =======================================
-- MODULE
-- =======================================
local graph = {}

-- =======================================
-- VARIABLES
-- =======================================
local bindings = {}
local edge_nodes = {}
local edge_select_count = 0
local is_node_moving = false

-- =======================================
-- UTILS
-- =======================================

function graph.set_nodes_visiblity()
	local status = data.options.draw_nodes and "enable" or "disable"
	for _, node in pairs(data.nodes) do
		msg.post(node.url, status)
	end
end

function graph.update_smooth_config()
	pathfinder.update_path_smoothing(data.path_smoothing_id, data.options.smoothing_config)
end

local function get_edge_positions(from_node_id, to_node_id)
	local from_v2 = pathfinder.get_node_position(from_node_id)
	local to_v2 = pathfinder.get_node_position(to_node_id)
	return vmath.vector3(from_v2.x, from_v2.y, 0), vmath.vector3(to_v2.x, to_v2.y, 0)
end

local function get_directional_transform(edge)
	local from, to = get_edge_positions(edge.from_node_id, edge.to_node_id)
	local center = (from + to) * 0.5
	local dir = to - from
	local angle = math.atan2(dir.y, dir.x)
	center.z = 0.9

	return center, angle
end

local function set_directional_transform(edge)
	local center, angle = get_directional_transform(edge)
	go.set_position(center, edge.url)
	go.set_rotation(vmath.quat_rotation_z(angle - math.pi * 0.5), edge.url)
end

local function add_edge_directions(edge)
	local center, angle = get_directional_transform(edge)
	local direction_url = factory.create(const.FACTORIES.DIRECTION, center, vmath.quat_rotation_z(angle - math.pi * 0.5))
	-- TODO ADD THIS direction_url

	edge.url = direction_url
end

-- This is expensive
local function get_node_edges(node, bidirectional)
	local node_edges = {}
	for _, edge in ipairs(data.edges) do
		if edge.from_node_id == node.pathfinder_node_id or edge.to_node_id == node.pathfinder_node_id then
			if bidirectional == nil or edge.bidirectional == bidirectional then
				table.insert(node_edges, edge)
			end
		end
	end
	return node_edges
end

local function remove_node_edges(node)
	local edges_to_remove = {}

	for i, edge in ipairs(data.edges) do
		if edge.from_node_id == node.pathfinder_node_id or edge.to_node_id == node.pathfinder_node_id then
			pathfinder.remove_edge(edge.from_node_id, edge.to_node_id, edge.bidirectional)
			--	collision.remove(i)
			table.insert(edges_to_remove, i)
		end
	end

	-- remove from the end to avoid index shifting
	for i = #edges_to_remove, 1, -1 do
		table.remove(data.edges, edges_to_remove[i])
	end
end

function graph.move_selected_node(position)
	local node_edges = get_node_edges(data.selected_node, false)

	for _, edge in ipairs(node_edges) do
		set_directional_transform(edge)
	end
	position.z = 0.8
	data.selected_node.position = position
	go.set_position(position, data.selected_node.url)
end

function graph.update_node(node_position)
	node_position.z = 0.8
	data.selected_node.position = node_position
	go.set_position(node_position, data.selected_node.url)

	is_node_moving = false
end

-- =======================================
-- FUNCTIONS
-- =======================================

local function move_node()
	local result, _ = collision.query_mouse_node()

	if result then
		data.selected_node    = data.nodes[result[1]]
		data.is_node_selected = true
		is_node_moving        = true
	else
		data.selected_node    = {}
		data.is_node_selected = false
		is_node_moving        = false
	end
end

local function add_node(node, loaded_edges)
	node = node and node or nil

	local node_position = data.mouse_position

	if node then
		node_position = node.position
	end

	local node_url = factory.create(const.FACTORIES.NODE, vmath.vector3(node_position.x, node_position.y, 0.8))
	local label_url = msg.url(node_url)
	label_url.fragment = "node_id"

	local temp_node = {
		id = 0, -- not using this
		position = node_position,
		aabb_id = collision.insert_gameobject(node_url, 16, 16, collision.COLLISION_BITS.NODE),
		pathfinder_node_id = pathfinder.add_gameobject_node(node_url),
		url = node_url,
		edges = {}
	}
	label.set_text(label_url, temp_node.pathfinder_node_id)
	table.insert(data.nodes, temp_node.aabb_id, temp_node)

	if node then
		if node.edges then
			for key, edge in pairs(node.edges) do
				if not data.edges[key] then
					data.edges[key] = {}
				end
				if edge.from_node_id then
					data.edges[key].from_node_id = temp_node.pathfinder_node_id
				end

				if edge.to_node_id then
					data.edges[key].to_node_id = temp_node.pathfinder_node_id
				end

				data.edges[key].bidirectional = loaded_edges[key].bidirectional
			end
		end
	end
end


local function add_edge(bidirectional)
	local is_bidirectional = (bidirectional == nil) and true or bidirectional

	local result, _ = collision.query_mouse_node()

	if result then
		local node = data.nodes[result[1]]

		edge_select_count = edge_select_count + 1
		if edge_select_count == 1 then
			data.action_status = const.EDITOR_STATUS.ADD_EDGE_2
		end
		edge_nodes[edge_select_count] = node.pathfinder_node_id

		if edge_nodes[1] == edge_nodes[2] then
			data.action_status = const.EDITOR_STATUS.ADD_EDGE_ERROR
		end

		if edge_select_count == 2 then
			data.action_status = const.EDITOR_STATUS.ADD_EDGE_1
			local from_node_id = edge_nodes[1]
			local to_node_id = edge_nodes[2]
			pathfinder.add_edge(from_node_id, to_node_id, is_bidirectional)

			edge_select_count = 0

			local edge = { from_node_id = edge_nodes[1], to_node_id = edge_nodes[2], bidirectional = is_bidirectional }

			if not is_bidirectional then
				add_edge_directions(edge)
			end

			table.insert(data.edges, edge)
			edge_nodes = {}
		end
	end
end

local function add_directional_edge()
	add_edge(false)
end

local function remove_node()
	local result, result_count = collision.query_mouse_node()

	if result then
		local node = data.nodes[result[1]]

		pathfinder.remove_gameobject_node(node.pathfinder_node_id)
		collision.remove(node.aabb_id)
		go.delete(node.url)
		remove_node_edges(node)
		data.nodes[result[1]] = nil
	end
end

local function add_agent()
	agents.add()
end

-- local function select_node()
-- 	local result, _ = collision.query_mouse_node()

-- 	if result then
-- 		data.selected_node = data.nodes[result[1]]
-- 		data.node_selected = true
-- 		pprint(data.selected_node)
-- 	else
-- 		data.selected_node = {}
-- 		data.is_node_selected = false
-- 	end
-- end

local function add_bindings()
	-- NODES
	-- bindings[const.EDITOR_STATES.SELECT_NODE]          = select_node
	bindings[const.EDITOR_STATES.ADD_NODE]             = add_node
	bindings[const.EDITOR_STATES.MOVE_NODE]            = move_node
	bindings[const.EDITOR_STATES.REMOVE_NODE]          = remove_node

	-- EDGES
	bindings[const.EDITOR_STATES.ADD_EDGE]             = add_edge
	bindings[const.EDITOR_STATES.ADD_DIRECTIONAL_EDGE] = add_directional_edge

	-- AGENTS
	bindings[const.EDITOR_STATES.ADD_AGENT]            = add_agent
end

function graph.init()
	data.action_status = const.EDITOR_STATUS.READY
	collision.init()
	add_bindings()

	pathfinder.init(const.GRAPH.MAX_NODES, const.GRAPH.MAX_GAMEOBJECT_NODES, const.GRAPH.MAX_EDGES_PER_NODE, const.GRAPH.HEAP_POOL_BLOCK_SIZE, const.GRAPH.MAX_CACHE_PATH_LENGTH)

	data.path_smoothing_id = pathfinder.add_path_smoothing(data.options.smoothing_config)
end

function graph.input(action_id, action)
	if data.want_mouse_input then -- Mouse on imgui window
		return
	end

	if data.is_node_selected and is_node_moving then -- moving a node
		graph.move_selected_node(data.mouse_position)
	end

	if action_id == const.TRIGGERS.MOUSE_BUTTON_LEFT and action.released and data.is_node_selected then
		graph.update_node(data.mouse_position)
	end

	if action_id == const.TRIGGERS.MOUSE_BUTTON_LEFT and action.pressed then
		if bindings[data.editor_state] then
			local action_call = bindings[data.editor_state]
			action_call()
		end
	end
end

function graph.reset()
	data.action_status = const.EDITOR_STATUS.RESET
	collision.reset()
	pathfinder.shutdown()

	for _, node in pairs(data.nodes) do
		go.delete(node.url)
	end

	for index, edge in ipairs(data.edges) do
		if not edge.bidirectional then
			go.delete(edge.url)
		end
	end

	data.nodes = {}
	data.edges = {}

	data.action_status = const.EDITOR_STATUS.READY
end

function graph.load(loaded_data)
	data.action_status = const.EDITOR_STATUS.LOADING
	graph.reset()
	graph.init()

	-- Delay to prevent same frame ops
	timer.delay(0.1, false, function()
		for _, node in pairs(loaded_data.nodes) do
			add_node(node, loaded_data.edges)
		end


		for index, edge in ipairs(data.edges) do
			if not edge.bidirectional then
				add_edge_directions(edge)
			end
		end

		pathfinder.add_edges(data.edges)
	end)

	data.action_status = const.EDITOR_STATUS.READY
end

return graph
