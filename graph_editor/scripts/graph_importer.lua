-- =======================================
-- GRAPH IMPORTER MODULE
-- Imports exported graph data (nodes and edges) into the pathfinder system
--
-- PURPOSE:
-- This module allows users to easily import graph data that was exported
-- from the editor (JSON format) into their game at runtime.
--
-- USAGE:
-- 1. Export graph from editor (File -> Export JSON)
--    This creates *_nodes.json and *_edges.json files
-- 2. Load the JSON files in your game script
-- 3. Call importer.generate(loaded_nodes, loaded_edges) to initialize pathfinder
-- 4. Use the returned nodes and edges for rendering/gameplay
--
-- EXAMPLE:
--   local graph_importer = require "graph_editor.scripts.graph_importer"
--
--   -- Load exported JSON files
--   local loaded_data = {
--     nodes = json.decode(sys.load_resource("/assets/graph_nodes.json")),
--     edges = json.decode(sys.load_resource("/assets/graph_edges.json"))
--   }
--
--   -- Initialize pathfinder with the graph data
--   pathfinder.init(max_nodes, max_gameobject_nodes, max_edges_per_node, heap_pool_block_size, max_cache_path_length)
--
--   -- Generate pathfinder nodes and edges
--   local nodes, edges = graph_importer.generate(loaded_data.nodes, loaded_data.edges)
--
--   -- Now you can use nodes and edges for rendering or pathfinding
-- =======================================
local importer = {}

--- Generate pathfinder nodes and edges from exported graph data
-- @param loaded_nodes Table of node data from exported JSON (indexed by UUID)
-- @param loaded_edges Table of edge data from exported JSON (indexed by UUID)
-- @return nodes Table of nodes indexed by pathfinder_node_id
-- @return edges Table of edges with updated node IDs
--
-- This function:
-- 1. Sorts nodes by their pathfinder_node_id to maintain consistent ordering
-- 2. Adds each node to the pathfinder system (assigns new pathfinder node IDs)
-- 3. Updates edge references to use the new pathfinder node IDs
-- 4. Adds all edges to the pathfinder system
function importer.generate(loaded_nodes, loaded_edges)
	-- Step 1: Collect and sort node UUIDs by pathfinder_node_id
	-- This ensures nodes are added in a consistent order
	local ordered_nodes = {}
	for uuid, _ in pairs(loaded_nodes) do
		ordered_nodes[#ordered_nodes + 1] = uuid
	end

	table.sort(ordered_nodes, function(a, b)
		return loaded_nodes[a].pathfinder_node_id < loaded_nodes[b].pathfinder_node_id
	end)

	-- Step 2: Initialize result tables
	local nodes = {}
	local edges = loaded_edges

	-- Step 3: Add nodes to pathfinder and build lookup table
	-- Note: pathfinder.add_node() assigns new IDs, so we need to update references
	for _, uuid in ipairs(ordered_nodes) do
		local node = loaded_nodes[uuid]

		-- Add node to pathfinder (returns new pathfinder_node_id)
		node.pathfinder_node_id = pathfinder.add_node(node.position.x, node.position.y)

		-- Store node indexed by its pathfinder ID for easy lookup
		nodes[node.pathfinder_node_id] = node

		-- Update edge references to use new pathfinder node IDs
		if node.edges then
			for edge_uuid, edge_type in pairs(node.edges) do
				edges[edge_uuid][edge_type] = node.pathfinder_node_id
			end
		end
	end

	-- Step 4: Add all edges to pathfinder
	-- Convert edge table to array format required by pathfinder.add_edges()
	local temp_edges = {}
	for _, edge in pairs(edges) do
		table.insert(temp_edges, edge)
	end

	pathfinder.add_edges(temp_edges)

	-- Return nodes indexed by pathfinder_node_id and updated edges
	return nodes, edges
end

return importer
