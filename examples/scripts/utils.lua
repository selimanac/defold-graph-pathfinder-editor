-- =======================================
-- EXAMPLE UTILITIES MODULE
-- Minimal utilities for loading and drawing exported graph data
-- in user applications (runtime graph loading and visualization)
--
-- PURPOSE:
-- Provides simplified functions for loading and rendering graph data
-- that was exported from the editor for use in game projects.
--
-- FEATURES:
-- - Error handling for file loading and parsing
-- - Support for both XY and XZ plane configurations
-- - Simple drawing functions for nodes, edges, and direction indicators
--
-- USAGE:
-- See load_2D.script and load_3D.script for example usage
-- =======================================

local editor_utils = require "graph_editor.scripts.editor_utils"
local validation   = require "graph_editor.scripts.editor_validation"
local const        = require "graph_editor.scripts.editor_const"

local utils        = {}

-- =======================================
-- DRAWING FUNCTIONS
-- =======================================

--- Draw all edges in the graph
-- Should be called in update() for continuous rendering
-- @param edges Table of edge data indexed by UUID
function utils.draw_edges(edges)
	for _, edge in pairs(edges) do
		local from, to = editor_utils.get_edge_positions(edge.from_node_id, edge.to_node_id)
		msg.post("@render:", "draw_line", { start_point = from, end_point = to, color = vmath.vector4(1, 0, 0, 1) })
	end
end

--- Draw all nodes in the graph
-- Creates visual game objects at each node position with labels
-- Should be called once during initialization
-- @param nodes Table of node data indexed by UUID or pathfinder_node_id
function utils.draw_nodes(nodes)
	for key, node in pairs(nodes) do
		-- Use editor_utils for plane-aware positioning
		local position = editor_utils.pathfinder_to_vec3(node.position.x, node.position.y)
		local node_url = factory.create("/factories#node", position)
		local label_url = msg.url(node_url)
		label_url.fragment = "label"
		label.set_text(label_url, tostring(node.pathfinder_node_id))
	end
end

--- Draw direction indicators for directional (non-bidirectional) edges
-- Creates visual game objects showing edge direction
-- Should be called once during initialization
-- @param edges Table of edge data indexed by UUID
function utils.draw_edge_directions(edges)
	for _, edge in pairs(edges) do
		if not edge.bidirectional then
			local center, angle = editor_utils.get_directional_transform(edge)
			-- Use plane-aware rotation based on const.IS_XZ_PLANE
			local quat = const.IS_XZ_PLANE and vmath.quat_rotation_y(angle) or vmath.quat_rotation_z(angle)
			local direction_url = factory.create("/factories#direction", center, quat)
			edge.url = direction_url
		end
	end
end

-- =======================================
-- FILE LOADING WITH ERROR HANDLING
-- =======================================

--- Load and validate graph data from exported JSON files
-- Loads both nodes and edges files with error handling
-- @param file_name Base filename (without _nodes.json or _edges.json suffix)
-- @return table|nil Loaded data {nodes = ..., edges = ...} or nil on error
-- @return string|nil Error message if loading failed
--
-- Example:
--   local data, err = utils.load("test2D")
--   if not data then
--       print("Load error:", err)
--       return
--   end
function utils.load(file_name)
	if not file_name or type(file_name) ~= "string" or not string.find(file_name, '%S') then
		local error_msg = "Invalid file_name parameter (empty or whitespace)"
		pprint("Load error:", error_msg)
		return nil, error_msg
	end

	local edges_path = "/data/" .. file_name .. "_edges.json"
	local nodes_path = "/data/" .. file_name .. "_nodes.json"

	-- Load edges file
	local edges_json, edges_load_error = sys.load_resource(edges_path)
	if edges_load_error then
		local error_msg = string.format("Cannot load edges file '%s': %s", edges_path, edges_load_error)
		pprint("Load error:", error_msg)
		return nil, error_msg
	end

	-- Load nodes file
	local nodes_json, nodes_load_error = sys.load_resource(nodes_path)
	if nodes_load_error then
		local error_msg = string.format("Cannot load nodes file '%s': %s", nodes_path, nodes_load_error)
		pprint("Load error:", error_msg)
		return nil, error_msg
	end

	-- Decode JSON with error handling
	local nodes_success, nodes_data = pcall(json.decode, nodes_json)
	if not nodes_success then
		local error_msg = string.format("JSON decode error for nodes: %s", nodes_data)
		pprint("Parse error:", error_msg)
		return nil, error_msg
	end

	local edges_success, edges_data = pcall(json.decode, edges_json)
	if not edges_success then
		local error_msg = string.format("JSON decode error for edges: %s", edges_data)
		pprint("Parse error:", error_msg)
		return nil, error_msg
	end

	pprint("Successfully loaded graph:", file_name)

	return { nodes = nodes_data, edges = edges_data }, nil
end

return utils
