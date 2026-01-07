local utils = require("graph_editor.scripts.editor_utils")
local data  = require("graph_editor.scripts.editor_data")
local const = require("graph_editor.scripts.editor_const")

-- =======================================
-- MODULE
-- =======================================
local draw  = {}

-- =======================================
-- DRAW EDGES
-- =======================================
function draw.edges()
	for _, edge in pairs(data.edges) do
		local from, to = utils.get_edge_positions(edge.from_node_id, edge.to_node_id)
		msg.post("@render:", "draw_line", { start_point = from, end_point = to, color = const.COLORS.GREEN })
	end
end

-- =======================================
-- DRAW PATH HELPERS
-- =======================================
-- Helper to draw a path from waypoint table
local function draw_path_segments(path, path_size)
	for i = 1, path_size - 1 do
		local from_node = path[i]
		local to_node = path[i + 1]
		local start_point = utils.pathfinder_to_vec3(from_node.x, from_node.y)
		local end_point = utils.pathfinder_to_vec3(to_node.x, to_node.y)
		msg.post("@render:", "draw_line", { start_point = start_point, end_point = end_point, color = const.COLORS.RED })
	end
end

-- =======================================
-- DRAW NODE TO NODE
-- =======================================
function draw.node_to_node()
	local smooth_path = data.options.draw.smooth_path and data.path_smoothing_id or nil

	data.path.node_to_node.size,
	data.path.node_to_node.status,
	data.path.node_to_node.status_text,
	data.path.node_to_node.path = pathfinder.find_node_to_node(
		data.options.node_to_node.start_node_id,
		data.options.node_to_node.goal_node_id,
		data.options.node_to_node.max_path,
		smooth_path)

	if data.path.node_to_node.status ~= pathfinder.PathStatus.SUCCESS or not data.options.draw.paths then
		return
	end

	draw_path_segments(data.path.node_to_node.path, data.path.node_to_node.size)
end

-- =======================================
-- DRAW PROJECTED TO NODE
-- =======================================
function draw.projected_to_node()
	local smooth_path = data.options.draw.smooth_path and data.path_smoothing_id or nil
	local path_x, path_y = utils.vec3_to_pathfinder(data.mouse_position)

	data.path.projected_to_node.size,
	data.path.projected_to_node.status,
	data.path.projected_to_node.status_text,
	data.path.projected_to_node.entry_point,
	data.path.projected_to_node.path =
		pathfinder.find_projected_to_node(
			path_x,
			path_y,
			data.options.projected_to_node.goal_node_id,
			data.options.projected_to_node.max_path,
			smooth_path)

	if data.path.projected_to_node.status ~= pathfinder.PathStatus.SUCCESS or not data.options.draw.paths then
		return
	end

	local entry_point = utils.pathfinder_to_vec3(data.path.projected_to_node.entry_point.x, data.path.projected_to_node.entry_point.y)
	local first_node = data.path.projected_to_node.path[1]
	local first_point = utils.pathfinder_to_vec3(first_node.x, first_node.y)

	-- Draw line from mouse position to entry point
	msg.post("@render:", "draw_line", { start_point = data.mouse_position, end_point = entry_point, color = const.COLORS.RED })
	-- Draw line from entry point to first waypoint
	msg.post("@render:", "draw_line", { start_point = entry_point, end_point = first_point, color = const.COLORS.RED })
	-- Draw lines between remaining waypoints
	draw_path_segments(data.path.projected_to_node.path, data.path.projected_to_node.size)
end

-- =======================================
-- DRAW NODE TO PROJECTED
-- =======================================
function draw.node_to_projected()
	local smooth_path = data.options.draw.smooth_path and data.path_smoothing_id or nil
	local path_x, path_y = utils.vec3_to_pathfinder(data.mouse_position)

	data.path.node_to_projected.size,
	data.path.node_to_projected.status,
	data.path.node_to_projected.status_text,
	data.path.node_to_projected.exit_point,
	data.path.node_to_projected.path =
		pathfinder.find_node_to_projected(
			data.options.node_to_projected.start_node_id,
			path_x,
			path_y,
			data.options.node_to_projected.max_path,
			smooth_path)

	if data.path.node_to_projected.status ~= pathfinder.PathStatus.SUCCESS or not data.options.draw.paths then
		return
	end

	local exit_point = utils.pathfinder_to_vec3(data.path.node_to_projected.exit_point.x, data.path.node_to_projected.exit_point.y)
	local last_node = data.path.node_to_projected.path[data.path.node_to_projected.size]
	local last_point = utils.pathfinder_to_vec3(last_node.x, last_node.y)

	-- Draw lines between waypoints
	draw_path_segments(data.path.node_to_projected.path, data.path.node_to_projected.size)
	-- Draw line from last waypoint to exit point
	msg.post("@render:", "draw_line", { start_point = last_point, end_point = exit_point, color = const.COLORS.RED })
	-- Draw line from exit point to mouse position
	msg.post("@render:", "draw_line", { start_point = exit_point, end_point = data.mouse_position, color = const.COLORS.RED })
end

-- =======================================
-- DRAW PROJECTED TO PROJECTED
-- =======================================
function draw.projected_to_projected()
	local smooth_path = data.options.draw.smooth_path and data.path_smoothing_id or nil
	local start_x, start_y = utils.vec3_to_pathfinder(data.options.projected_to_projected.start_position)
	local end_x, end_y = utils.vec3_to_pathfinder(data.mouse_position)

	data.path.projected_to_projected.size,
	data.path.projected_to_projected.status,
	data.path.projected_to_projected.status_text,
	data.path.projected_to_projected.entry_point,
	data.path.projected_to_projected.exit_point,
	data.path.projected_to_projected.path =
		pathfinder.find_projected_to_projected(
			start_x,
			start_y,
			end_x,
			end_y,
			data.options.projected_to_projected.max_path,
			smooth_path)

	if data.path.projected_to_projected.status ~= pathfinder.PathStatus.SUCCESS or not data.options.draw.paths then
		return
	end

	local entry_point = utils.pathfinder_to_vec3(data.path.projected_to_projected.entry_point.x, data.path.projected_to_projected.entry_point.y)
	local exit_point = utils.pathfinder_to_vec3(data.path.projected_to_projected.exit_point.x, data.path.projected_to_projected.exit_point.y)
	local start_node = data.path.projected_to_projected.path[1]
	local start_point = utils.pathfinder_to_vec3(start_node.x, start_node.y)
	local last_node = data.path.projected_to_projected.path[data.path.projected_to_projected.size]
	local last_point = utils.pathfinder_to_vec3(last_node.x, last_node.y)

	-- Draw line from start position to entry point
	msg.post("@render:", "draw_line", { start_point = data.options.projected_to_projected.start_position, end_point = entry_point, color = const.COLORS.RED })
	-- Draw line from entry point to first waypoint
	msg.post("@render:", "draw_line", { start_point = entry_point, end_point = start_point, color = const.COLORS.RED })
	-- Draw lines between waypoints
	draw_path_segments(data.path.projected_to_projected.path, data.path.projected_to_projected.size)
	-- Draw line from last waypoint to exit point
	msg.post("@render:", "draw_line", { start_point = last_point, end_point = exit_point, color = const.COLORS.RED })
	-- Draw line from exit point to mouse position
	msg.post("@render:", "draw_line", { start_point = exit_point, end_point = data.mouse_position, color = const.COLORS.RED })
end

return draw
