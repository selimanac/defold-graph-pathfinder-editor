local validation = {}

-- Validate that a value is a table
function validation.is_table(value)
	return type(value) == "table"
end

-- Validate node structure
function validation.is_valid_node(node)
	if not validation.is_table(node) then
		return false, "Node is not a table"
	end

	if not node.uuid or type(node.uuid) ~= "string" then
		return false, "Node missing or invalid uuid"
	end

	if not node.pathfinder_node_id or type(node.pathfinder_node_id) ~= "number" then
		return false, "Node missing or invalid pathfinder_node_id"
	end

	-- Position can be either a table or userdata (vmath.vector3)
	if not node.position then
		return false, "Node missing position"
	end

	local pos_type = type(node.position)
	if pos_type ~= "table" and pos_type ~= "userdata" then
		return false, "Node position has invalid type"
	end

	-- Check if position has x and y (works for both table and userdata)
	if type(node.position.x) ~= "number" or type(node.position.y) ~= "number" then
		return false, "Node position missing x or y coordinates"
	end

	if not node.edges or not validation.is_table(node.edges) then
		return false, "Node missing or invalid edges table"
	end

	return true
end

-- Validate edge structure
function validation.is_valid_edge(edge)
	if not validation.is_table(edge) then
		return false, "Edge is not a table"
	end

	if not edge.uuid or type(edge.uuid) ~= "string" then
		return false, "Edge missing or invalid uuid"
	end

	if not edge.from_node_id or type(edge.from_node_id) ~= "number" then
		return false, "Edge missing or invalid from_node_id"
	end

	if not edge.to_node_id or type(edge.to_node_id) ~= "number" then
		return false, "Edge missing or invalid to_node_id"
	end

	if edge.bidirectional ~= nil and type(edge.bidirectional) ~= "boolean" then
		return false, "Edge has invalid bidirectional field"
	end

	return true
end

-- Validate loaded data structure
function validation.validate_loaded_data(data)
	if not validation.is_table(data) then
		return false, "Data is not a table"
	end

	if not data.nodes or not validation.is_table(data.nodes) then
		return false, "Data missing or invalid nodes table"
	end

	if not data.edges or not validation.is_table(data.edges) then
		return false, "Data missing or invalid edges table"
	end

	-- Validate each node
	for uuid, node in pairs(data.nodes) do
		local valid, err = validation.is_valid_node(node)
		if not valid then
			return false, string.format("Invalid node '%s': %s", uuid, err)
		end
	end

	-- Validate each edge
	for uuid, edge in pairs(data.edges) do
		local valid, err = validation.is_valid_edge(edge)
		if not valid then
			return false, string.format("Invalid edge '%s': %s", uuid, err)
		end
	end

	return true
end

-- Validate data structure before saving
function validation.validate_save_data(nodes, edges)
	if not validation.is_table(nodes) then
		return false, "Nodes is not a table"
	end

	if not validation.is_table(edges) then
		return false, "Edges is not a table"
	end

	return true
end

return validation
