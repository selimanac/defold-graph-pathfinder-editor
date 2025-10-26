local const = require("graph_editor.scripts.const")
local data = require("graph_editor.scripts.data")
local collision = require("graph_editor.scripts.collision")
local agents = require("graph_editor.scripts.agents")

-- MODULE
local graph = {}

-- Variables
local bindings = {}
local is_moving_node = false
local selected_node = {}
local edge_nodes = {}
local edge_select_count = 0

--[[local function rect_from_points(p1, p2)
	-- Center of rectangle
	local center = vmath.vector3(
		(p1.x + p2.x) * 0.5,
		(p1.y + p2.y) * 0.5,
		0
	)

	-- Width and height (absolute difference)
	local width = math.abs(p2.x - p1.x)
	local height = math.abs(p2.y - p1.y)

	return center, width, height
end



local function update_collision_edges(node)
	for i, edge in pairs(data.edges) do
		if edge.from_node_id == node.pathfinder_node_id or edge.to_node_id == node.pathfinder_node_id then
			local from_node_position = pathfinder.get_node_position(edge.from_node_id)
			local to_node_position = pathfinder.get_node_position(edge.to_node_id)

			local center, width, height = rect_from_points(from_node_position, to_node_position)

			local aabb = {
				aabb_id = i,
				position = { x = center.x, y = center.y },
				size = { width = width, height = height }
			}
			collision.update_aabb(aabb)
		end
	end
end]]



local function update_node()
	local node_position = data.mouse_position
	node_position.z = 0.8
	go.set_position(node_position, selected_node.url)
	selected_node.position = data.mouse_position

	--update_collision_edges(selected_node)
	pprint(data.nodes)
end


-- Functions
local function move_node()
	print("MOVENODE ")
	local result, result_count = collision.query_mouse_node()


	if result then
		selected_node = data.nodes[result[1]]
		is_moving_node = true
	else
		is_moving_node = false
	end
end

local function add_node(node, loaded_edges)
	print("ADD NODE")
	node = node and node or nil

	local node_position = data.mouse_position

	if node then
		node_position = node.position
	end

	local node_url = factory.create(const.FACTORIES.NODE, vmath.vector3(node_position.x, node_position.y, 0.8))
	local label_url = msg.url(node_url)
	label_url.fragment = "node_id"

	local temp_node = {
		id = 0,
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



local function add_edge()
	local result, result_count = collision.query_mouse_node()

	if result then
		local node = data.nodes[result[1]]

		edge_select_count = edge_select_count + 1
		edge_nodes[edge_select_count] = node.pathfinder_node_id

		if edge_nodes[1] == edge_nodes[2] then
			print("start node and end node is same")
		end

		if edge_select_count == 2 then
			local from_node_id = edge_nodes[1]
			local to_node_id = edge_nodes[2]
			pathfinder.add_edge(from_node_id, to_node_id, true)

			--	local from_node_position = pathfinder.get_node_position(from_node_id)
			--	local to_node_position = pathfinder.get_node_position(to_node_id)

			--	local center, width, height = rect_from_points(from_node_position, to_node_position)
			--	print(center, width, height)
			--	local edge_id = collision.insert_aabb(center.x, center.y, width, height, collision.COLLISION_BITS.EDGE)
			--	print("edge_id", edge_id)
			edge_select_count = 0

			table.insert(data.edges, { from_node_id = edge_nodes[1], to_node_id = edge_nodes[2], bidirectional = true })
			edge_nodes = {}
		end
	end

	pprint(data.edges)
end

local function remove_node_edges(node)
	local edges_to_remove = {}
	print("pathfinder_node_id", node.pathfinder_node_id)
	pprint(data.edges)

	for i, edge in ipairs(data.edges) do
		if edge.from_node_id == node.pathfinder_node_id or edge.to_node_id == node.pathfinder_node_id then
			pathfinder.remove_edge(edge.from_node_id, edge.to_node_id, edge.bidirectional)
			--	collision.remove(i)
			table.insert(edges_to_remove, i)
		end
	end

	-- Remove from the end to avoid index shifting
	for i = #edges_to_remove, 1, -1 do
		table.remove(data.edges, edges_to_remove[i])
	end

	pprint(data.edges)
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

local function remove_edge()
	local result, result_count = collision.query_mouse_edge()
	pprint(result, result_count)
	if result then
		local edge = data.edges[result[1]]

		pprint(edge)
	end
end

local function add_agent()
	agents.add()
end

local function add_bindings()
	bindings[const.EDITOR_STATES.ADD_NODE] = add_node
	bindings[const.EDITOR_STATES.MOVE_NODE] = move_node
	bindings[const.EDITOR_STATES.REMOVE_NODE] = remove_node

	bindings[const.EDITOR_STATES.ADD_EDGE] = add_edge
	bindings[const.EDITOR_STATES.REMOVE_EDGE] = remove_edge

	bindings[const.EDITOR_STATES.ADD_AGENT] = add_agent
end

function graph.init()
	print("init")
	collision.init()
	add_bindings()

	pathfinder.init(const.GRAPH.MAX_NODES, const.GRAPH.MAX_GAMEOBJECT_NODES, const.GRAPH.MAX_EDGES_PER_NODE, const.GRAPH.HEAP_POOL_BLOCK_SIZE, const.GRAPH.MAX_CACHE_PATH_LENGTH)

	data.path_smoothing_id = pathfinder.add_path_smoothing(data.options.smoothing_config)
end

function graph.input(action_id, action)
	if data.want_mouse_input then
		return
	end
	if is_moving_node then
		go.set_position(data.mouse_position, selected_node.url)
	end
	if action_id == const.TRIGGERS.MOUSE_BUTTON_LEFT and action.released and is_moving_node then
		print("Release")
		pprint(selected_node)

		update_node()
		is_moving_node = false
		selected_node = {}
	end
	if action_id == const.TRIGGERS.MOUSE_BUTTON_LEFT and action.pressed then
		if bindings[data.editor_state] then
			local action_call = bindings[data.editor_state]
			action_call()
		end
	end
end

function graph.reset()
	print("RESET")
	collision.reset()
	pathfinder.shutdown()

	for _, node in pairs(data.nodes) do
		go.delete(node.url)
	end
	data.nodes = {}
	data.edges = {}
end

function graph.load(loaded_data)
	print("LOAD")
	graph.reset()
	graph.init()

	-- Delay to prevent same frame ops
	timer.delay(0.1, false, function()
		for key, node in pairs(loaded_data.nodes) do
			add_node(node, loaded_data.edges)
		end
		-- pprint(data.edges)
		pathfinder.add_edges(data.edges)
	end)
end

function graph.set_nodes_visiblity()
	local status = data.options.draw_nodes and "enable" or "disable"
	for _, node in pairs(data.nodes) do
		msg.post(node.url, status)
	end
end

function graph.update_smooth_config()
	pathfinder.update_path_smoothing(data.path_smoothing_id, data.options.smoothing_config)
end

return graph
