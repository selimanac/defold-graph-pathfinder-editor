local data = require("graph_editor.scripts.data")
local const = require("graph_editor.scripts.const")
local graph = require("graph_editor.scripts.graph")
local graph_imgui = require("graph_editor.scripts.graph_imgui")
local agents = require("graph_editor.scripts.agents")

local editor = {}


-- Get the positions of two nodes connected by an edge
-- Returns two vector3 positions for the start and end of the edge
local function get_edge_positions(from_node_id, to_node_id)
	local from_v2 = pathfinder.get_node_position(from_node_id)
	local to_v2 = pathfinder.get_node_position(to_node_id)
	return vmath.vector3(from_v2.x, from_v2.y, 0), vmath.vector3(to_v2.x, to_v2.y, 0)
end

-- Draw all edges in the graph as green lines
local function draw_edges()
	for _, edge in ipairs(data.edges) do
		local from, to = get_edge_positions(edge.from_node_id, edge.to_node_id)
		msg.post("@render:", "draw_line", { start_point = from, end_point = to, color = vmath.vector4(0, 1, 0, 1) })
	end
end

-- Draw a path as red lines connecting waypoints
local function draw_path()
	local smooth_path = data.options.draw_smooth_path and data.path_smoothing_id or nil

	data.path.size, data.path.status, data.path.status_text, data.path.path = pathfinder.find_path(data.options.find_path_start_node_id, data.options.find_path_goal_node_id, data.options.find_path_max_path, smooth_path)

	if data.path.status == pathfinder.PathStatus.SUCCESS and data.options.draw_path then
		for i = 1, data.path.size - 1, 1 do
			local from_node = data.path.path[i]
			local to_node = data.path.path[i + 1]

			msg.post("@render:", "draw_line", { start_point = vmath.vector3(from_node.x, from_node.y, 0), end_point = vmath.vector3(to_node.x, to_node.y, 0), color = vmath.vector4(1, 0, 0, 1) })
		end
	end
end

-- Draw a projected path from the mouse position to the goal
-- Shows the connection from mouse -> entry point -> first waypoint -> remaining path
local function draw_projected_path()
	local smooth_path = data.options.draw_smooth_path and data.path_smoothing_id or nil

	data.projected_path.size, data.projected_path.status, data.projected_path.status_text, data.projected_path.entry_point, data.projected_path.path = pathfinder.find_projected_path(data.mouse_position.x, data.mouse_position.y, data.options.find_projected_path_goal_node_id,
		data.options.find_projected_path_max_path, smooth_path)

	if data.projected_path.status == pathfinder.PathStatus.SUCCESS and data.options.draw_projected_path then
		-- Draw line from mouse position to entry point
		msg.post("@render:", "draw_line", { start_point = data.mouse_position, end_point = data.projected_path.entry_point, color = vmath.vector4(1, 0, 0, 1) })

		-- Draw line from entry point to first waypoint
		local first_node = data.projected_path.path[1]
		msg.post("@render:", "draw_line", { start_point = data.projected_path.entry_point, end_point = vmath.vector3(first_node.x, first_node.y, 0), color = vmath.vector4(1, 0, 0, 1) })

		-- Draw lines between remaining waypoints
		for i = 1, data.projected_path.size - 1, 1 do
			local from_node = data.projected_path.path[i]
			local to_node = data.projected_path.path[i + 1]

			msg.post("@render:", "draw_line", { start_point = vmath.vector3(from_node.x, from_node.y, 0), end_point = vmath.vector3(to_node.x, to_node.y, 0), color = vmath.vector4(1, 0, 0, 1) })
		end
	end
end


function editor.init()
	graph_imgui.init()
	graph.init()
end

function editor.update(dt)
	graph_imgui.update()

	if data.options.draw_edges then
		draw_edges()
	end

	if data.options.find_path then
		draw_path()
	end

	if data.options.find_projected_path then
		draw_projected_path()
	end
	data.stats = pathfinder.get_cache_stats()
	agents.update(dt)
end

function editor.input(action_id, action)
	if action.screen_x then
		data.mouse_position = camera.screen_xy_to_world(action.screen_x, action.screen_y, const.CAMERA)
		data.mouse_position.z = 1
		go.set_position(data.mouse_position, const.MOUSE)
	end


	graph.input(action_id, action)
end

return editor
