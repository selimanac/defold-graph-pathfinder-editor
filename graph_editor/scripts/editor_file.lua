local data       = require("graph_editor.scripts.editor_data")
local const      = require("graph_editor.scripts.editor_const")
local utils      = require("graph_editor.scripts.editor_utils")
local graph      = require("graph_editor.scripts.editor_graph")
local validation = require("graph_editor.scripts.editor_validation")

-- =======================================
-- MODULE
-- =======================================
local file       = {}

-- =======================================
-- Save
-- =======================================
function file.add(filename)
	for i, v in ipairs(const.GRAPH_EDITOR.FILES) do
		if v == filename then
			return i
		end
	end
	table.insert(const.GRAPH_EDITOR.FILES, filename)
	return #const.GRAPH_EDITOR.FILES
end

function file.save()
	local save_status = true
	local error_message = nil

	-- Validate file selection
	if data.selected_file <= 0 or data.selected_file > #const.GRAPH_EDITOR.FILES then
		data.save_load_text = const.FILE_STATUS.SAVE_ERROR
		timer.delay(const.TIMER_DELAYS.STATUS_MESSAGE, false, function()
			data.save_load_text = ""
		end)
		return
	end

	local file_name = const.GRAPH_EDITOR.FILES[data.selected_file]
	local file_path = const.GRAPH_EDITOR.FOLDER .. "/" .. file_name

	-- Validate data before saving
	local valid, err = validation.validate_save_data(data.nodes, data.edges)
	if not valid then
		pprint("Validation error before save:", err)
		save_status = false
		error_message = err
	else
		-- Serialize data with error handling
		local success, json_data = pcall(sys.serialize, { nodes = data.nodes, edges = data.edges, options = data.options })

		if not success then
			pprint("Serialization error:", json_data)
			save_status = false
			error_message = "Serialization failed"
		else
			-- Write to file
			local file_handle = io.open(file_path, "w")
			if file_handle then
				local write_success, write_error = pcall(function()
					file_handle:write(json_data)
					file_handle:close()
				end)

				if not write_success then
					pprint("Write error:", write_error)
					save_status = false
					error_message = "Write failed"
					pcall(function() file_handle:close() end)
				else
					utils.set_title(file_path)
					pprint("Graph saved successfully to:", file_path)
				end
			else
				save_status = false
				error_message = "Cannot open file for writing"
			end
		end
	end

	data.save_load_text = save_status and const.FILE_STATUS.SAVE_SUCCESS or const.FILE_STATUS.SAVE_ERROR

	timer.delay(const.TIMER_DELAYS.STATUS_MESSAGE, false, function()
		data.save_load_text = ""
	end)
end

function file.load()
	local load_status = true
	local error_message = nil

	-- Validate file selection
	local file_name = const.GRAPH_EDITOR.FILES[data.selected_file]
	if file_name == nil then
		pprint("No file selected for loading")
		return
	end

	local file_path = const.GRAPH_EDITOR.FOLDER .. "/" .. file_name

	-- Open and read file
	local file_handle = io.open(file_path, "r")
	if not file_handle then
		load_status = false
		error_message = "Cannot open file for reading"
		pprint("Load error:", error_message, file_path)
	else
		local read_success, content = pcall(function()
			local c = file_handle:read("*a")
			file_handle:close()
			return c
		end)

		if not read_success then
			load_status = false
			error_message = "Cannot read file"
			pprint("Read error:", content)
			pcall(function() file_handle:close() end)
		else
			-- Deserialize with error handling
			local deserialize_success, loaded_data = pcall(sys.deserialize, content)

			if not deserialize_success then
				load_status = false
				error_message = "Deserialization failed"
				pprint("Deserialization error:", loaded_data)
			else
				-- Validate loaded data structure
				local valid, validation_error = validation.validate_loaded_data(loaded_data)

				if not valid then
					load_status = false
					error_message = validation_error
					pprint("Validation error:", validation_error)
				else
					-- Data is valid, proceed with loading
					if loaded_data.options then
						data.options = loaded_data.options
					end

					pprint("Loading graph from:", file_path)
					graph.load(loaded_data)
					utils.set_title(file_path)
				end
			end
		end
	end

	data.save_load_text = load_status and const.FILE_STATUS.LOAD_SUCCESS or const.FILE_STATUS.LOAD_ERROR

	timer.delay(const.TIMER_DELAYS.STATUS_MESSAGE, false, function()
		data.save_load_text = ""
	end)
end

function file.save_exports(nodes, edges)
	if data.selected_file <= 0 then
		data.modals.open_export = true
		return
	end

	local save_status = true
	local file_name = const.GRAPH_EDITOR.FILES[data.selected_file]

	-- Save nodes file
	local nodes_file_name = file_name:gsub("%.json$", "") .. "_nodes.json"
	local file_path = const.GRAPH_EDITOR.FOLDER .. "/" .. nodes_file_name

	local file_handle = io.open(file_path, "w")
	if file_handle then
		local write_success, write_error = pcall(function()
			file_handle:write(nodes)
			file_handle:close()
		end)

		if not write_success then
			pprint("Error writing nodes export:", write_error)
			save_status = false
			pcall(function() file_handle:close() end)
		else
			pprint("Nodes exported to:", file_path)
		end
	else
		pprint("Cannot open nodes file for writing:", file_path)
		save_status = false
	end

	-- Save edges file
	local edges_file_name = file_name:gsub("%.json$", "") .. "_edges.json"
	file_path = const.GRAPH_EDITOR.FOLDER .. "/" .. edges_file_name

	file_handle = io.open(file_path, "w")
	if file_handle then
		local write_success, write_error = pcall(function()
			file_handle:write(edges)
			file_handle:close()
		end)

		if not write_success then
			pprint("Error writing edges export:", write_error)
			save_status = false
			pcall(function() file_handle:close() end)
		else
			pprint("Edges exported to:", file_path)
		end
	else
		pprint("Cannot open edges file for writing:", file_path)
		save_status = false
	end

	data.save_load_text = save_status and const.FILE_STATUS.EXPORT_SUCCESS or const.FILE_STATUS.EXPORT_ERROR

	timer.delay(const.TIMER_DELAYS.STATUS_MESSAGE, false, function()
		data.save_load_text = ""
	end)
end

function file.export_json()
	-- Validate data before export
	local valid, err = validation.validate_save_data(data.nodes, data.edges)
	if not valid then
		pprint("Validation error before export:", err)
		data.save_load_text = const.FILE_STATUS.EXPORT_ERROR
		timer.delay(const.TIMER_DELAYS.STATUS_MESSAGE, false, function()
			data.save_load_text = ""
		end)
		return
	end

	-- Prepare nodes for export with error handling
	local nodes = {}
	local export_success = true

	for uuid, node in pairs(data.nodes) do
		local success, result = pcall(function()
			local path_x, path_y = utils.vec3_to_pathfinder(node.position)
			local temp_node = {
				edges = node.edges,
				uuid = uuid,
				position = {
					x = utils.round3(path_x), y = utils.round3(path_y)
				},
				pathfinder_node_id = node.pathfinder_node_id
			}
			return temp_node
		end)

		if not success then
			pprint("Error preparing node for export:", uuid, result)
			export_success = false
			break
		end

		nodes[uuid] = result
	end

	if not export_success then
		data.save_load_text = const.FILE_STATUS.EXPORT_ERROR
		timer.delay(const.TIMER_DELAYS.STATUS_MESSAGE, false, function()
			data.save_load_text = ""
		end)
		return
	end

	-- Encode with error handling
	local encode_success_nodes, encoded_nodes = pcall(json.encode, nodes)
	local encode_success_edges, encoded_edges = pcall(json.encode, data.edges)

	if not encode_success_nodes then
		pprint("JSON encode error for nodes:", encoded_nodes)
		data.save_load_text = const.FILE_STATUS.EXPORT_ERROR
		timer.delay(const.TIMER_DELAYS.STATUS_MESSAGE, false, function()
			data.save_load_text = ""
		end)
		return
	end

	if not encode_success_edges then
		pprint("JSON encode error for edges:", encoded_edges)
		data.save_load_text = const.FILE_STATUS.EXPORT_ERROR
		timer.delay(const.TIMER_DELAYS.STATUS_MESSAGE, false, function()
			data.save_load_text = ""
		end)
		return
	end

	data.export.nodes = encoded_nodes
	data.export.edges = encoded_edges

	file.save_exports(data.export.nodes, data.export.edges)
end

return file
