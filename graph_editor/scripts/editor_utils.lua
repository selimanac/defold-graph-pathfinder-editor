local const     = require("graph_editor.scripts.editor_const")
local data      = require("graph_editor.scripts.editor_data")
local collision = require("graph_editor.scripts.editor_collision")

-- =======================================
-- MODULE
-- =======================================
local utils     = {}

--- Create a 3D vector from 2D pathfinder coordinates
-- Pathfinder uses (x, y) which maps to the plane coordinates
-- @param x Horizontal coordinate on the plane
-- @param y Vertical coordinate on the plane (depth)
-- @return vmath.vector3 3D position vector on the configured plane
function utils.pathfinder_to_vec3(x, y)
	if const.IS_XZ_PLANE then
		return vmath.vector3(x, 0, y)
	else
		return vmath.vector3(x, y, 0.1)
	end
end

--- Get the 2D coordinates from a 3D vector for pathfinder
-- Returns x, y for pathfinder (where y is the vertical axis on the plane)
-- @param vec3 3D position vector
-- @return number, number x and y coordinates for pathfinder
function utils.vec3_to_pathfinder(vec3)
	if const.IS_XZ_PLANE then
		return vec3.x, vec3.z
	else
		return vec3.x, vec3.y
	end
end

--- Get the rotation axis vector based on plane type
-- @return vmath.vector3 Rotation axis (Y for XZ plane, Z for XY plane)
function utils.get_rotation_axis()
	if const.IS_XZ_PLANE then
		return vmath.vector3(0, 1, 0) -- Rotate around Y axis
	else
		return vmath.vector3(0, 0, 1) -- Rotate around Z axis
	end
end

--- Calculate rotation quaternion for direction on the plane
-- @param direction vmath.vector3 Direction vector
-- @return quaternion Rotation quaternion for the direction
function utils.calc_rotation_quat(direction)
	if const.IS_XZ_PLANE then
		-- XZ plane: rotate around Y axis
		local angle = math.atan2(direction.x, direction.z)
		return vmath.quat_rotation_y(angle)
	else
		-- XY plane: rotate around Z axis
		local angle = math.atan2(direction.y, direction.x)
		return vmath.quat_rotation_z(angle)
	end
end

--- Convert screen coordinates to world plane position
-- Uses ray-plane intersection to find 3D position on the configured plane
-- @param cam Camera URL
-- @param sx Screen X coordinate
-- @param sy Screen Y coordinate
-- @return vmath.vector3|nil 3D position on plane, or nil if no intersection
function utils.screen_to_plane(cam, sx, sy)
	local p0 = camera.screen_to_world(vmath.vector3(sx, sy, 0), cam)
	local p1 = camera.screen_to_world(vmath.vector3(sx, sy, 1), cam)

	local dir = p1 - p0
	local denom = vmath.dot(const.PLANE_NORMAL, dir)
	if math.abs(denom) < const.EPSILON then
		return nil
	end

	local t = vmath.dot(const.PLANE_POINT - p0, const.PLANE_NORMAL) / denom
	if t < 0 then
		return nil
	end

	return p0 + dir * t
end

function utils.round3(v)
	return math.floor(v * 1000 + 0.5) / 1000
end

function utils.vec3_to_table(v)
	return { v.x, v.y, v.z }
end

function utils.get_node_id_from_pathfinder(pathfinder_id)
	return data.lookup.pathfinder_to_node[pathfinder_id]
end

function utils.get_node_from_pathfinder_id(pathfinder_id)
	local node_id = utils.get_node_id_from_pathfinder(pathfinder_id)
	return data.nodes[node_id]
end

function utils.get_node_id_from_aabb(aabb_id)
	return data.lookup.aabb_to_node[aabb_id]
end

function utils.get_node_from_aabb(aabb_id)
	local node_id = utils.get_node_id_from_aabb(aabb_id)
	return data.nodes[node_id]
end

function utils.remove_node_with_aabb(aabb_id)
	local node_id = utils.get_node_id_from_aabb(aabb_id)
	if not node_id or not data.nodes[node_id] then
		return
	end

	data.lookup.aabb_to_node[aabb_id] = nil
	data.lookup.pathfinder_to_node[data.nodes[node_id].pathfinder_node_id] = nil
	data.nodes[node_id] = nil
end

function utils.get_edge_id_from_aabb(aabb_id)
	return data.lookup.aabb_to_edge[aabb_id]
end

function utils.get_edge_from_aabb(aabb_id)
	local edge_id = utils.get_edge_id_from_aabb(aabb_id)
	return data.edges[edge_id]
end

function utils.remove_edge_with_aabb(aabb_id)
	local edge_id = utils.get_edge_id_from_aabb(aabb_id)
	if not edge_id then
		return
	end

	data.lookup.aabb_to_edge[aabb_id] = nil
	data.edges[edge_id] = nil
end

function utils.get_edge(uuid)
	return data.edges[uuid]
end

function utils.remove_edge(edge)
	if not edge then
		return
	end

	pathfinder.remove_edge(edge.from_node_id, edge.to_node_id, edge.bidirectional)
	collision.remove(edge.aabb_id)

	-- REMOVE FROM NODES
	local from_node_id = data.lookup.pathfinder_to_node[edge.from_node_id]
	if from_node_id and data.nodes[from_node_id] then
		data.nodes[from_node_id].edges[edge.uuid] = nil
	end

	local to_node_id = data.lookup.pathfinder_to_node[edge.to_node_id]
	if to_node_id and data.nodes[to_node_id] then
		data.nodes[to_node_id].edges[edge.uuid] = nil
	end

	-- REMOVE DIRECTION
	if edge.url then
		go.delete(edge.url)
	end

	data.lookup.aabb_to_edge[edge.aabb_id] = nil
	data.edges[edge.uuid] = nil
end

function utils.rect_from_points(p1, p2)
	-- Center of rectangle
	local center = vmath.vector3(
		(p1.x + p2.x) * 0.5,
		const.IS_XZ_PLANE and 0 or (p1.y + p2.y) * 0.5,
		const.IS_XZ_PLANE and (p1.y + p2.y) * 0.5 or 0
	)

	-- Width and height (absolute difference)
	local width = math.abs(p2.x - p1.x)
	local height = math.abs(p2.y - p1.y)

	return center, width, height
end

local function update_collision_edges(node)
	if not node or not node.edges then
		return
	end

	for edge_uuid, edge_type in pairs(node.edges) do
		local edge = utils.get_edge(edge_uuid)
		if edge then
			local from_node_position    = pathfinder.get_node_position(edge.from_node_id)
			local to_node_position      = pathfinder.get_node_position(edge.to_node_id)
			local center, width, height = utils.rect_from_points(from_node_position, to_node_position)

			local aabb                  = {
				aabb_id = edge.aabb_id,
				position = center,
				size = { width = width, height = 1, depth = height }
			}

			collision.update_aabb(aabb)
		end
	end
end

function utils.get_edge_positions(from_node_id, to_node_id)
	local from_v2 = pathfinder.get_node_position(from_node_id)
	local to_v2   = pathfinder.get_node_position(to_node_id)
	return utils.pathfinder_to_vec3(from_v2.x, from_v2.y), utils.pathfinder_to_vec3(to_v2.x, to_v2.y)
end

function utils.get_directional_transform(edge)
	local from, to = utils.get_edge_positions(edge.from_node_id, edge.to_node_id)
	local center   = (from + to) * 0.5
	local dir      = to - from
	local angle

	if const.IS_XZ_PLANE then
		angle = math.atan2(dir.x, dir.z) - math.pi * 0.5
		center.y = 0.0
	else
		angle = math.atan2(dir.y, dir.x) - math.pi * 0.5
		center.z = 0.1
	end

	return center, angle
end

function utils.set_directional_transform(edge)
	local center, angle = utils.get_directional_transform(edge)

	go.set_position(center, edge.url)

	if const.IS_XZ_PLANE then
		go.set_rotation(vmath.quat_rotation_y(angle), edge.url)
	else
		go.set_rotation(vmath.quat_rotation_z(angle), edge.url)
	end
end

function utils.add_edge_directions(edge)
	local center, angle = utils.get_directional_transform(edge)
	local quat          = const.IS_XZ_PLANE and vmath.quat_rotation_y(angle) or vmath.quat_rotation_z(angle)

	local direction_url = factory.create(const.FACTORIES.DIRECTION, center, quat)
	edge.url            = direction_url
end

function utils.get_node_edges(node, bidirectional)
	local node_edges = {}

	if not node or not node.edges then
		return node_edges
	end

	for edge_uuid, edge_type in pairs(node.edges) do
		local edge = utils.get_edge(edge_uuid)
		if edge and (bidirectional == nil or edge.bidirectional == bidirectional) then
			table.insert(node_edges, edge)
		end
	end
	return node_edges
end

function utils.set_nodes_visiblity()
	local status = data.options.draw.nodes and "enable" or "disable"
	for _, node in pairs(data.nodes) do
		msg.post(node.url, status)
	end

	for _, edge in pairs(data.edges) do
		msg.post(edge.url, status)
	end
end

function utils.update_smooth_config()
	pathfinder.update_path_smoothing(data.path_smoothing_id, data.options.smoothing_config)
end

function utils.remove_node_edges(node)
	if not node or not node.edges then
		return
	end

	local to_remove = {}

	for edge_uuid in pairs(node.edges) do
		to_remove[#to_remove + 1] = edge_uuid
	end

	for _, edge_uuid in ipairs(to_remove) do
		local edge = utils.get_edge(edge_uuid)
		if edge then
			utils.remove_edge(edge)
		end
	end
end

function utils.update_node(node_position)
	-- Set the up axis to 0
	if const.IS_XZ_PLANE then
		node_position.y = 0
	else
		node_position.z = 0
	end

	data.selected_node.position = node_position
	go.set_position(node_position, data.selected_node.url)

	local path_x, path_y = utils.vec3_to_pathfinder(node_position)
	pathfinder.move_node(data.selected_node.pathfinder_node_id, path_x, path_y)

	update_collision_edges(data.selected_node)
end

function utils.move_selected_node(node_position)
	local node_edges = utils.get_node_edges(data.selected_node, false)

	for _, edge in pairs(node_edges) do
		utils.set_directional_transform(edge)
	end

	utils.update_node(node_position)
end

-- Set window title
function utils.set_title(text)
	text = text and text or "Graph Pathfinder Editor"
	window.set_title(text)
end

return utils
