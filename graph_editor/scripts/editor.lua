local data = require("graph_editor.scripts.data")
local const = require("graph_editor.scripts.const")
local graph = require("graph_editor.scripts.graph")
local graph_imgui = require("graph_editor.scripts.graph_imgui")
local agents = require("graph_editor.scripts.agents")

-- =======================================
-- MODULE
-- =======================================

local editor = {}

local function get_edge_positions(from_node_id, to_node_id)
	local from_v2 = pathfinder.get_node_position(from_node_id)
	local to_v2 = pathfinder.get_node_position(to_node_id)
	return vmath.vector3(from_v2.x, from_v2.y, 0), vmath.vector3(to_v2.x, to_v2.y, 0)
end

local function draw_edges()
	for _, edge in ipairs(data.edges) do
		local from, to = get_edge_positions(edge.from_node_id, edge.to_node_id)
		msg.post("@render:", "draw_line", { start_point = from, end_point = to, color = vmath.vector4(0, 1, 0, 1) })
	end
end

local function draw_node_to_node()
	local smooth_path = data.options.draw.smooth_path and data.path_smoothing_id or nil


	data.path.node_to_node.size,
	data.path.node_to_node.status,
	data.path.node_to_node.status_text,
	data.path.node_to_node.path = pathfinder.find_node_to_node(
		data.options.node_to_node.start_node_id,
		data.options.node_to_node.goal_node_id,
		data.options.node_to_node.max_path,
		smooth_path)

	if data.path.node_to_node.status == pathfinder.PathStatus.SUCCESS and data.options.draw.paths then
		for i = 1, data.path.node_to_node.size - 1, 1 do
			local from_node = data.path.node_to_node.path[i]
			local to_node = data.path.node_to_node.path[i + 1]

			local start_point = vmath.vector3(from_node.x, from_node.y, 0)
			local end_point = vmath.vector3(to_node.x, to_node.y, 0)

			msg.post("@render:", "draw_line", { start_point = start_point, end_point = end_point, color = vmath.vector4(1, 0, 0, 1) })
		end
	end
end

local function draw_projected_to_node()
	local smooth_path = data.options.draw.smooth_path and data.path_smoothing_id or nil

	data.path.projected_to_node.size,
	data.path.projected_to_node.status,
	data.path.projected_to_node.status_text,
	data.path.projected_to_node.entry_point,
	data.path.projected_to_node.path =
		pathfinder.find_projected_to_node(
			data.mouse_position.x,
			data.mouse_position.y,
			data.options.projected_to_node.goal_node_id,
			data.options.projected_to_node.max_path,
			smooth_path)

	if data.path.projected_to_node.status == pathfinder.PathStatus.SUCCESS and data.options.draw.paths then
		-- Draw line from mouse position to entry point
		msg.post("@render:", "draw_line", { start_point = data.mouse_position, end_point = data.path.projected_to_node.entry_point, color = vmath.vector4(1, 0, 0, 1) })

		-- Draw line from entry point to first waypoint
		local first_node = data.path.projected_to_node.path[1]

		msg.post("@render:", "draw_line", { start_point = data.path.projected_to_node.entry_point, end_point = vmath.vector3(first_node.x, first_node.y, 0), color = vmath.vector4(1, 0, 0, 1) })

		-- Draw lines between remaining waypoints
		for i = 1, data.path.projected_to_node.size - 1, 1 do
			local from_node = data.path.projected_to_node.path[i]
			local to_node = data.path.projected_to_node.path[i + 1]

			local start_point = vmath.vector3(from_node.x, from_node.y, 0)
			local end_point = vmath.vector3(to_node.x, to_node.y, 0)

			msg.post("@render:", "draw_line", { start_point = start_point, end_point = end_point, color = vmath.vector4(1, 0, 0, 1) })
		end
	end
end

local function draw_node_to_projected()
	local smooth_path = data.options.draw.smooth_path and data.path_smoothing_id or nil

	data.path.node_to_projected.size,
	data.path.node_to_projected.status,
	data.path.node_to_projected.status_text,
	data.path.node_to_projected.exit_point,
	data.path.node_to_projected.path =
		pathfinder.find_node_to_projected(data.options.node_to_projected.start_node_id, data.mouse_position.x, data.mouse_position.y, data.options.node_to_projected.max_path, smooth_path)

	if data.path.node_to_projected.status == pathfinder.PathStatus.SUCCESS and data.options.draw.paths then
		-- Draw lines between remaining waypoints
		for i = 1, data.path.node_to_projected.size - 1, 1 do
			local from_node = data.path.node_to_projected.path[i]
			local to_node = data.path.node_to_projected.path[i + 1]

			local start_point = vmath.vector3(from_node.x, from_node.y, 0)
			local end_point = vmath.vector3(to_node.x, to_node.y, 0)

			msg.post("@render:", "draw_line", { start_point = start_point, end_point = end_point, color = vmath.vector4(1, 0, 0, 1) })
		end


		-- Draw line from exit point to mouse position
		msg.post("@render:", "draw_line", { start_point = data.path.node_to_projected.exit_point, end_point = data.mouse_position, color = vmath.vector4(1, 0, 0, 1) })

		-- Draw line from entry point to first waypoint
		local last_node = data.path.node_to_projected.path[data.path.node_to_projected.size]

		msg.post("@render:", "draw_line", { start_point = vmath.vector3(last_node.x, last_node.y, 0), end_point = data.path.node_to_projected.exit_point, color = vmath.vector4(1, 0, 0, 1) })
	end
end


local function draw_node_to_projected()
	local smooth_path = data.options.draw.smooth_path and data.path_smoothing_id or nil

	data.path.node_to_projected.size,
	data.path.node_to_projected.status,
	data.path.node_to_projected.status_text,
	data.path.node_to_projected.exit_point,
	data.path.node_to_projected.path =
		pathfinder.find_node_to_projected(
			data.options.node_to_projected.start_node_id,
			data.mouse_position.x,
			data.mouse_position.y,
			data.options.node_to_projected.max_path,
			smooth_path)

	if data.path.node_to_projected.status == pathfinder.PathStatus.SUCCESS and data.options.draw.paths then
		-- Draw lines between remaining waypoints
		for i = 1, data.path.node_to_projected.size - 1, 1 do
			local from_node = data.path.node_to_projected.path[i]
			local to_node = data.path.node_to_projected.path[i + 1]

			local start_point = vmath.vector3(from_node.x, from_node.y, 0)
			local end_point = vmath.vector3(to_node.x, to_node.y, 0)

			msg.post("@render:", "draw_line", { start_point = start_point, end_point = end_point, color = vmath.vector4(1, 0, 0, 1) })
		end


		-- Draw line from exit point to mouse position
		msg.post("@render:", "draw_line", { start_point = data.path.node_to_projected.exit_point, end_point = data.mouse_position, color = vmath.vector4(1, 0, 0, 1) })

		-- Draw line from entry point to first waypoint
		local last_node = data.path.node_to_projected.path[data.path.node_to_projected.size]

		msg.post("@render:", "draw_line", { start_point = vmath.vector3(last_node.x, last_node.y, 0), end_point = data.path.node_to_projected.exit_point, color = vmath.vector4(1, 0, 0, 1) })
	end
end


local function draw_projected_to_projected()
	local smooth_path = data.options.draw.smooth_path and data.path_smoothing_id or nil

	data.path.projected_to_projected.size,
	data.path.projected_to_projected.status,
	data.path.projected_to_projected.status_text,
	data.path.projected_to_projected.entry_point,
	data.path.projected_to_projected.exit_point,
	data.path.projected_to_projected.path =
		pathfinder.find_projected_to_projected(
			data.options.projected_to_projected.start_position.x,
			data.options.projected_to_projected.start_position.y,
			data.mouse_position.x,
			data.mouse_position.y,
			data.options.projected_to_projected.max_path,
			smooth_path)


	if data.path.projected_to_projected.status == pathfinder.PathStatus.SUCCESS and data.options.draw.paths then
		-- Draw line from start point to entry point
		msg.post("@render:", "draw_line", { start_point = data.options.projected_to_projected.start_position, end_point = data.path.projected_to_projected.entry_point, color = vmath.vector4(1, 0, 0, 1) })

		-- Draw line from entry point to first waypoint
		local start_node = data.path.projected_to_projected.path[1]

		msg.post("@render:", "draw_line", { start_point = data.path.projected_to_projected.entry_point, end_point = vmath.vector3(start_node.x, start_node.y, 0), color = vmath.vector4(1, 0, 0, 1) })

		-- Draw lines between remaining waypoints
		for i = 1, data.path.projected_to_projected.size - 1, 1 do
			local from_node = data.path.projected_to_projected.path[i]
			local to_node = data.path.projected_to_projected.path[i + 1]

			local start_point = vmath.vector3(from_node.x, from_node.y, 0)
			local end_point = vmath.vector3(to_node.x, to_node.y, 0)

			msg.post("@render:", "draw_line", { start_point = start_point, end_point = end_point, color = vmath.vector4(1, 0, 0, 1) })
		end


		-- Draw line from exit point to mouse position
		msg.post("@render:", "draw_line", { start_point = data.path.projected_to_projected.exit_point, end_point = data.mouse_position, color = vmath.vector4(1, 0, 0, 1) })

		-- Draw line from entry point to first waypoint
		local last_node = data.path.projected_to_projected.path[data.path.projected_to_projected.size]

		msg.post("@render:", "draw_line", { start_point = vmath.vector3(last_node.x, last_node.y, 0), end_point = data.path.projected_to_projected.exit_point, color = vmath.vector4(1, 0, 0, 1) })
	end
end

function editor.init()
	graph_imgui.init()
	graph.init()
end

function editor.update(dt)
	graph_imgui.update()

	if data.options.draw.edges then
		draw_edges()
	end

	if data.options.node_to_node.is_active then
		draw_node_to_node()
	end

	if data.options.projected_to_node.is_active then
		draw_projected_to_node()
	end

	if data.options.node_to_projected.is_active then
		draw_node_to_projected()
	end

	if data.options.projected_to_projected.is_active then
		draw_projected_to_projected()
	end

	data.stats = pathfinder.get_stats()
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
