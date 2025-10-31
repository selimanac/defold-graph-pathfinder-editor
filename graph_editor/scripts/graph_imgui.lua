local style             = require("graph_editor.scripts.imgui_style")
local data              = require("graph_editor.scripts.data")
local const             = require("graph_editor.scripts.const")
local graph             = require("graph_editor.scripts.graph")
local graph_imgui       = {}

-- =======================================
-- VARS
-- =======================================
local flags             = bit.bor(imgui.WINDOWFLAGS_NOTITLEBAR)
local changed           = false
local checked           = false
local int_value         = 0
local float_value       = 0.0
local x, y, z           = 0.0, 0.0, 0.0
local open_file_modal   = false
local open_save_modal   = false
local open_export_modal = false
local save_load_text    = ""
local save_file_name    = ""
local export_nodes      = {}
local export_edges      = {}
-- =======================================
-- Save
-- =======================================
local function vec3_to_table(v)
	return { v.x, v.y, v.z }
end

local function add_file(filename)
	for i, v in ipairs(const.GRAPH_EDITOR.FILES) do
		if v == filename then
			return i
		end
	end
	table.insert(const.GRAPH_EDITOR.FILES, filename)
	return #const.GRAPH_EDITOR.FILES
end

local function set_title(text)
	text = text and text or "Graph Pathfinder Editor"
	window.set_title(text)
end



local function prepare_for_save()
	local duplicate = sys.serialize(data.nodes)
	duplicate = sys.deserialize(duplicate)

	for _, node in pairs(duplicate) do
		--node.position = vec3_to_table(node.position)
		for i, edge in ipairs(data.edges) do
			if edge.from_node_id == node.pathfinder_node_id or edge.to_node_id == node.pathfinder_node_id then
				node.edges[i] = {}
				if edge.from_node_id == node.pathfinder_node_id then
					node.edges[i].from_node_id = node.pathfinder_node_id
				end
				if edge.to_node_id == node.pathfinder_node_id then
					node.edges[i].to_node_id = node.pathfinder_node_id
				end
			end
		end
	end
	return duplicate
end

local function save()
	save_load_text = const.FILE_STATUS.SAVE_SUCCESS
	local json_nodes = prepare_for_save()

	local save_status = true
	local file_name = const.GRAPH_EDITOR.FILES[data.selected_file]
	local file_path = const.GRAPH_EDITOR.FOLDER .. "/" .. file_name


	local json_data = sys.serialize({ nodes = json_nodes, edges = data.edges })
	local file = io.open(file_path, "w")
	if file then
		file:write(json_data)
		file:close()
		set_title(file_path)
	else
		save_status = false
	end

	save_load_text = save_status and const.FILE_STATUS.SAVE_SUCCESS or const.FILE_STATUS.SAVE_ERROR

	timer.delay(0.7, false, function()
		save_load_text = ""
	end)
end

local function load()
	local load_status = true
	local file_name = const.GRAPH_EDITOR.FILES[data.selected_file]
	local file_path = const.GRAPH_EDITOR.FOLDER .. "/" .. file_name
	local file = io.open(file_path, "r")
	if not file then
		load_status = false
	else
		local content = file:read("*a") -- read entire file
		file:close()

		local loaded_data = sys.deserialize(content)
		graph.load(loaded_data)
		set_title(file_path)
	end

	save_load_text = load_status and const.FILE_STATUS.LOAD_SUCCESS or const.FILE_STATUS.LOAD_ERROR

	timer.delay(0.7, false, function()
		save_load_text = ""
	end)
end

local function save_exports(nodes, edges)
	if data.selected_file > -1 then
		save_load_text = const.FILE_STATUS.EXPORT_SUCCESS

		local save_status = true
		local file_name = const.GRAPH_EDITOR.FILES[data.selected_file]

		local nodes_file_name = file_name:gsub("%.json$", "")
		nodes_file_name = nodes_file_name .. "_nodes.json"

		local file_path = const.GRAPH_EDITOR.FOLDER .. "/" .. nodes_file_name

		local json_data = nodes
		local file = io.open(file_path, "w")
		if file then
			file:write(json_data)
			file:close()
		else
			save_status = false
		end

		save_load_text = save_status and const.FILE_STATUS.EXPORT_SUCCESS or const.FILE_STATUS.EXPORT_ERROR

		timer.delay(0.7, false, function()
			save_load_text = ""
		end)

		local edges_file_name = file_name:gsub("%.json$", "")
		edges_file_name = edges_file_name .. "_edges.json"


		file_path = const.GRAPH_EDITOR.FOLDER .. "/" .. edges_file_name

		json_data = edges
		file = io.open(file_path, "w")
		if file then
			file:write(json_data)
			file:close()
		else
			save_status = false
		end

		save_load_text = save_status and const.FILE_STATUS.EXPORT_SUCCESS or const.FILE_STATUS.EXPORT_ERROR

		timer.delay(0.7, false, function()
			save_load_text = ""
		end)
	else
		open_export_modal = true
	end
end

local function export_json()
	local temp_nodes = {}

	for _, node in pairs(data.nodes) do
		local temp_node = { x = node.position.x, y = node.position.y }
		table.insert(temp_nodes, temp_node)
	end
	export_nodes = json.encode(temp_nodes)


	local temp_edges = {}
	for _, edge in ipairs(data.edges) do
		local temp_edge = {
			from_node_id = edge.from_node_id,
			to_node_id = edge.to_node_id,
			bidirectional = edge.bidirectional
		}
		table.insert(temp_edges, temp_edge)
	end

	export_edges = json.encode(temp_edges)

	save_exports(export_nodes, export_edges)
end

local function export_lua()
	-- body
end


-- =======================================
-- Helpers
-- =======================================

local function get_key_for_value(t, value)
	for k, v in pairs(t) do
		if v == value then return k end
	end
	return "Select a Style"
end

-- =======================================
-- Window Callback
-- =======================================
local function window_callback(self, event, data)
	if event == window.WINDOW_EVENT_FOCUS_LOST then
		--	print("window.WINDOW_EVENT_FOCUS_LOST")
	elseif event == window.WINDOW_EVENT_FOCUS_GAINED then
		--print("window.WINDOW_EVENT_FOCUS_GAINED")
	elseif event == window.WINDOW_EVENT_ICONFIED then
		--	print("window.WINDOW_EVENT_ICONFIED")
	elseif event == window.WINDOW_EVENT_DEICONIFIED then
		--	print("window.WINDOW_EVENT_DEICONIFIED")
	elseif event == window.WINDOW_EVENT_RESIZED then
		print("Window resized: ", data.width, data.height)
		imgui.set_display_size(data.width, data.height)
	end
end

-- =======================================
-- Init
-- =======================================
function graph_imgui.init()
	imgui.set_display_size(1920, 1080)
	imgui.set_ini_filename("graph_editor.ini")
	style.set()
	set_title()

	window.set_listener(window_callback)
end

-- =======================================
-- Main Menu
-- =======================================
local function main_menu_bar(self)
	if imgui.begin_main_menu_bar() then
		if imgui.begin_menu("File") then
			if imgui.menu_item("New", nil) then
				data.selected_file = -1
				graph.reset()
				graph.init()
				set_title()
			end

			if imgui.menu_item("Load", nil) then
				open_file_modal = true
			end

			if imgui.menu_item("Save", nil) then
				if data.selected_file > -1 then
					save()
				else
					open_save_modal = true
				end
			end

			if imgui.menu_item("Export JSON", nil) then
				export_json()
			end

			if imgui.menu_item("Export LUA", nil) then
				export_lua()
			end

			if imgui.menu_item("Quit", nil) then
				sys.exit(0)
			end

			imgui.end_menu()
		end


		if imgui.begin_menu("View") then
			local clicked, selected = imgui.menu_item("Nodes", nil, data.options.draw.nodes)
			if clicked then
				data.options.draw.nodes = selected
				graph.set_nodes_visiblity()
			end

			local clicked, selected = imgui.menu_item("Edges", nil, data.options.draw.edges)
			if clicked then
				data.options.draw.edges = selected
			end

			local clicked, selected = imgui.menu_item("Paths", nil, data.options.draw.paths)
			if clicked then
				data.options.draw.paths = selected
			end

			local clicked, selected = imgui.menu_item("Smooth Paths", nil, data.options.draw.smooth_path)
			if clicked then
				data.options.draw.smooth_path = selected
			end

			imgui.end_menu()
		end

		if imgui.begin_menu("About") then
			imgui.menu_item("Defold v" .. sys.get_engine_info().version, nil, nil, false)

			imgui.end_menu()
		end

		imgui.text_colored(save_load_text, 0, 1, 0, 1)
		imgui.end_main_menu_bar()
	end
end

-- =======================================
-- TOOLS
-- =======================================
local function tools()
	imgui.set_next_window_size(180, 350)
	imgui.begin_window("TOOLS", nil, flags)

	if imgui.radio_button("Add Node", data.editor_state == const.EDITOR_STATES.ADD_NODE) then
		data.editor_state = const.EDITOR_STATES.ADD_NODE
		data.action_status = const.EDITOR_STATUS.ADD_NODE
	end

	if imgui.radio_button("Remove Node", data.editor_state == const.EDITOR_STATES.REMOVE_NODE) then
		data.editor_state = const.EDITOR_STATES.REMOVE_NODE
		data.action_status = const.EDITOR_STATUS.REMOVE_NODE
	end

	if imgui.radio_button("Move Node", data.editor_state == const.EDITOR_STATES.MOVE_NODE) then
		data.editor_state = const.EDITOR_STATES.MOVE_NODE
		data.action_status = const.EDITOR_STATUS.MOVE_NODE
	end

	imgui.separator()

	if imgui.radio_button("Add Edge", data.editor_state == const.EDITOR_STATES.ADD_EDGE) then
		data.editor_state = const.EDITOR_STATES.ADD_EDGE
		data.action_status = const.EDITOR_STATUS.ADD_EDGE_1
	end

	if imgui.radio_button("Add A->B Edge", data.editor_state == const.EDITOR_STATES.ADD_DIRECTIONAL_EDGE) then
		data.editor_state = const.EDITOR_STATES.ADD_DIRECTIONAL_EDGE
		data.action_status = const.EDITOR_STATUS.ADD_EDGE_1
	end

	imgui.separator()

	if imgui.radio_button("Add Agent", data.editor_state == const.EDITOR_STATES.ADD_AGENT) then
		data.editor_state = const.EDITOR_STATES.ADD_AGENT
		data.action_status = const.EDITOR_STATUS.ADD_AGENT
	end

	imgui.separator()

	imgui.end_window()
end

-- =======================================
-- STATS
-- =======================================

local function stats()
	imgui.set_next_window_size(700, 150)
	imgui.begin_window("STATS", nil, flags)

	imgui.text("Editor Status: ")
	imgui.same_line()
	imgui.text_colored(data.action_status, 0, 1, 0, 1)

	if data.stats.path_cache then
		imgui.text("Path Cache - Current Entries: " .. data.stats.path_cache.current_entries .. " | Max Capacity: " .. data.stats.path_cache.max_capacity .. " | Hit Rate: " .. data.stats.path_cache.hit_rate .. "%")
	end

	if data.stats.distance_cache then
		imgui.text("Distance Cache - Current Entries: " .. data.stats.distance_cache.current_size .. " | Hit Count: " .. data.stats.distance_cache.hit_count .. " | Miss Count: " .. data.stats.distance_cache.miss_count .. " | Hit Rate: " .. data.stats.distance_cache.hit_rate .. "%")
	end

	if data.stats.spatial_index then
		imgui.text("Spatial Index - Cell Count: " ..
			data.stats.spatial_index.cell_count .. " |  Edge Count: " .. data.stats.spatial_index.edge_count .. " | Avg. Edges per Cell: " .. data.stats.spatial_index.avg_edges_per_cell .. " | Max Edges per Cell: " .. data.stats.spatial_index.max_edges_per_cell)
	end
	imgui.separator()

	imgui.text_colored("Cache results are mixed. It's always better to test one path at a time!", 1, 0, 0, 1)

	imgui.end_window()
end

-- =======================================
-- NODE
-- =======================================
local function node()
	if not data.is_node_selected then
		return
	end

	imgui.set_next_window_size(400, 175)
	imgui.begin_window("NODE", nil)

	imgui.text("Pathfinder Node ID: " .. data.selected_node.pathfinder_node_id)
	imgui.text("AABB ID: " .. data.selected_node.aabb_id)
	imgui.text("URL: " .. data.selected_node.url)
	imgui.set_next_item_width(250)

	changed, x, y, z = imgui.input_float3("Position", data.selected_node.position.x, data.selected_node.position.y, data.selected_node.position.z)
	if changed then
		data.selected_node.position.x = x
		data.selected_node.position.y = y
		data.selected_node.position.z = 0.8

		graph.move_selected_node(data.selected_node.position)
		graph.update_node(data.selected_node.position)
	end


	imgui.end_window()
end

-- =======================================
-- SETTINGS
-- =======================================
local function settings()
	imgui.set_next_window_size(475, 755)
	imgui.begin_window("SETTINGS", nil)

	data.is_window_hovered = imgui.is_window_hovered()

	imgui.begin_tab_bar("tabs")

	-- =======================================
	-- PATHS
	-- =======================================
	local paths_tab_open = imgui.begin_tab_item("Paths")
	if paths_tab_open then
		-- =======================================
		-- AGENT
		-- =======================================
		imgui.spacing()
		imgui.text_colored("AGENT", 1, 0, 0, 1)
		imgui.separator()
		if imgui.begin_combo("AGENT MODE##selectable", get_key_for_value(const.AGEND_MODE, data.agent_mode)) then
			for key, mode in pairs(const.AGEND_MODE) do
				if imgui.selectable(key, mode == data.agent_mode) then
					data.agent_mode = mode
				end
			end
			imgui.end_combo()
		end

		-- =======================================
		-- NODE TO NODE
		-- =======================================

		imgui.spacing()
		imgui.text_colored("NODE TO NODE", 1, 0, 0, 1)
		imgui.separator()

		changed, checked = imgui.checkbox("Node to Node", data.options.node_to_node.is_active)
		if changed then
			data.options.node_to_node.is_active = checked
		end

		imgui.text("Status: ")
		imgui.same_line()
		local status_color = data.path.node_to_node.status == pathfinder.PathStatus.SUCCESS and const.COLORS.GREEN or const.COLORS.RED
		imgui.text_colored(data.path.node_to_node.status_text, status_color.x, status_color.y, status_color.z, 1)

		imgui.set_next_item_width(250)
		changed, int_value = imgui.input_int("Start Node Id##node_to_node", data.options.node_to_node.start_node_id)
		if changed then
			data.options.node_to_node.start_node_id = int_value
		end

		imgui.set_next_item_width(250)
		changed, int_value = imgui.input_int("Goal Node Id##node_to_node", data.options.node_to_node.goal_node_id)
		if changed then
			data.options.node_to_node.goal_node_id = int_value
		end

		imgui.set_next_item_width(250)
		changed, int_value = imgui.input_int("Max Path Lenght##node_to_node", data.options.node_to_node.max_path)
		if changed then
			data.options.node_to_node.max_path = int_value
		end

		-- =======================================
		-- PROJECTED TO NODE
		-- =======================================

		imgui.spacing()
		imgui.text_colored("PROJECTED TO NODE", 1, 0, 0, 1)
		imgui.separator()

		changed, checked = imgui.checkbox("Projected to Node", data.options.projected_to_node.is_active)
		if changed then
			data.options.projected_to_node.is_active = checked
		end

		imgui.text("Status: ")
		imgui.same_line()
		local status_color = data.path.projected_to_node.status == pathfinder.PathStatus.SUCCESS and const.COLORS.GREEN or const.COLORS.RED
		imgui.text_colored(data.path.projected_to_node.status_text, status_color.x, status_color.y, status_color.z, 1)

		imgui.set_next_item_width(250)
		changed, int_value = imgui.input_int("Goal Node Id##projected_to_node", data.options.projected_to_node.goal_node_id)
		if changed then
			data.options.projected_to_node.goal_node_id = int_value
		end

		imgui.set_next_item_width(250)
		changed, int_value = imgui.input_int("Max Path Lenght##projected_to_node", data.options.projected_to_node.max_path)
		if changed then
			data.options.projected_to_node.max_path = int_value
		end


		-- =======================================
		-- NODE TO PROJECTED
		-- =======================================

		imgui.spacing()
		imgui.text_colored("NODE TO PROJECTED", 1, 0, 0, 1)
		imgui.separator()

		changed, checked = imgui.checkbox("Node to Projected", data.options.node_to_projected.is_active)
		if changed then
			data.options.node_to_projected.is_active = checked
		end

		imgui.text("Status: ")
		imgui.same_line()
		local status_color = data.path.node_to_projected.status == pathfinder.PathStatus.SUCCESS and const.COLORS.GREEN or const.COLORS.RED
		imgui.text_colored(data.path.node_to_projected.status_text, status_color.x, status_color.y, status_color.z, 1)

		imgui.set_next_item_width(250)
		changed, int_value = imgui.input_int("Start Node Id##node_to_projected", data.options.node_to_projected.start_node_id)
		if changed then
			data.options.node_to_projected.start_node_id = int_value
		end

		imgui.set_next_item_width(250)
		changed, int_value = imgui.input_int("Max Path Lenght##node_to_projected", data.options.node_to_projected.max_path)
		if changed then
			data.options.node_to_projected.max_path = int_value
		end


		-- =======================================
		-- PROJECTED TO PROJECTED
		-- =======================================

		imgui.spacing()
		imgui.text_colored("PROJECTED TO PROJECTED", 1, 0, 0, 1)
		imgui.separator()

		changed, checked = imgui.checkbox("Projected to Projected", data.options.projected_to_projected.is_active)
		if changed then
			data.options.projected_to_projected.is_active = checked
		end

		imgui.text("Status: ")
		imgui.same_line()
		local status_color = data.path.projected_to_projected.status == pathfinder.PathStatus.SUCCESS and const.COLORS.GREEN or const.COLORS.RED
		imgui.text_colored(data.path.projected_to_projected.status_text, status_color.x, status_color.y, status_color.z, 1)

		imgui.set_next_item_width(250)
		changed, x, y, z = imgui.input_float3("Start Position", data.options.projected_to_projected.start_position.x, data.options.projected_to_projected.start_position.y, data.options.projected_to_projected.start_position.z)
		if changed then
			data.options.projected_to_projected.start_position.x = x
			data.options.projected_to_projected.start_position.x = y
			data.options.projected_to_projected.start_position.x = 0.8
		end

		imgui.set_next_item_width(250)
		changed, int_value = imgui.input_int("Max Path Lenght##projected_to_projected", data.options.projected_to_projected.max_path)
		if changed then
			data.options.projected_to_projected.max_path = int_value
		end
		imgui.spacing()

		imgui.end_tab_item()
	end

	-- =======================================
	-- SHOOTHING
	-- =======================================

	local smmothing_tab_open = imgui.begin_tab_item("Smmothing")
	if smmothing_tab_open then
		imgui.set_next_item_width(250)
		if imgui.begin_combo("Smooth Style##selectable", get_key_for_value(pathfinder.PathSmoothStyle, data.options.smoothing_config.style)) then
			for key, style in pairs(pathfinder.PathSmoothStyle) do
				if imgui.selectable(key, style == data.options.smoothing_config.style) then
					data.options.smoothing_config.style = style
					graph.update_smooth_config()
				end
			end

			imgui.end_combo()
		end

		imgui.set_next_item_width(250)
		changed, int_value = imgui.input_int("Sample for Segment", data.options.smoothing_config.bezier_sample_segment)
		if changed then
			data.options.smoothing_config.bezier_sample_segment = int_value
			graph.update_smooth_config()
		end

		if data.options.smoothing_config.style == pathfinder.PathSmoothStyle.BEZIER_QUADRATIC then
			imgui.set_next_item_width(250)
			changed, float_value = imgui.drag_float("Curve Radius", data.options.smoothing_config.bezier_curve_radius, 0.01, 0.0, 1.0, 1)
			if changed then
				data.options.smoothing_config.bezier_curve_radius = float_value
				graph.update_smooth_config()
			end
		end

		if data.options.smoothing_config.style == pathfinder.PathSmoothStyle.BEZIER_CUBIC then
			imgui.set_next_item_width(250)
			changed, float_value = imgui.drag_float("Control Point Offset", data.options.smoothing_config.bezier_control_point_offset, 0.01, 0.0, 1.0, 1)
			if changed then
				data.options.smoothing_config.bezier_control_point_offset = float_value
				graph.update_smooth_config()
			end
		end

		if data.options.smoothing_config.style == pathfinder.PathSmoothStyle.BEZIER_ADAPTIVE then
			imgui.set_next_item_width(250)
			changed, float_value = imgui.drag_float("Tightness", data.options.smoothing_config.bezier_adaptive_tightness, 0.01, 0.0, 1.0, 1)
			if changed then
				data.options.smoothing_config.bezier_adaptive_tightness = float_value
				graph.update_smooth_config()
			end

			imgui.set_next_item_width(250)
			changed, float_value = imgui.drag_float("Roundness", data.options.smoothing_config.bezier_adaptive_roundness, 0.01, 0.0, 1.0, 1)
			if changed then
				data.options.smoothing_config.bezier_adaptive_roundness = float_value
				graph.update_smooth_config()
			end

			imgui.set_next_item_width(250)
			changed, float_value = imgui.drag_float("Max Corner Distance", data.options.smoothing_config.bezier_adaptive_max_corner_distance, 0.1, 0.0, 100.0, 0.1)
			if changed then
				data.options.smoothing_config.bezier_adaptive_max_corner_distance = float_value
				graph.update_smooth_config()
			end
		end

		if data.options.smoothing_config.style == pathfinder.PathSmoothStyle.CIRCULAR_ARC then
			imgui.set_next_item_width(250)
			changed, float_value = imgui.drag_float("Arc Radius", data.options.smoothing_config.bezier_arc_radius, 0.1, 0.0, 100.0, 0.1)
			if changed then
				data.options.smoothing_config.bezier_arc_radius = float_value
				graph.update_smooth_config()
			end
		end
		imgui.end_tab_item()
	end

	imgui.end_tab_bar()
	imgui.end_window()
end

local function file_select_modal()
	if imgui.begin_popup_modal("Select File", imgui.WINDOWFLAGS_ALWAYSAUTORESIZE) then
		imgui.begin_child("listbox", 150, 100, true)
		for i, file in ipairs(const.GRAPH_EDITOR.FILES) do
			local is_selected = (i == data.selected_file)
			if imgui.selectable(file, is_selected) then
				data.selected_file = i
			end
		end
		imgui.end_child()

		open_file_modal = false

		imgui.separator()
		if imgui.button("CANCEL") then
			imgui.close_current_popup()
		end

		imgui.same_line()

		if imgui.button("LOAD") then
			imgui.close_current_popup()

			load()
		end
		imgui.end_popup()
	end
end


local function file_save_modal()
	if imgui.begin_popup_modal("Save File", imgui.WINDOWFLAGS_ALWAYSAUTORESIZE) then
		local changed, text = imgui.input_text(".json", save_file_name)
		if changed then
			save_file_name = text
		end
		open_save_modal = false

		imgui.separator()
		if imgui.button("CANCEL") then
			imgui.close_current_popup()
		end

		imgui.same_line()

		if imgui.button("SAVE") then
			data.selected_file = add_file(save_file_name .. ".json")
			imgui.close_current_popup()
			save()
		end
		imgui.end_popup()
	end
end

local function file_export_modal()
	if imgui.begin_popup_modal("Export File", imgui.WINDOWFLAGS_ALWAYSAUTORESIZE) then
		local changed, text = imgui.input_text(".json", save_file_name)

		if changed then
			save_file_name = text
		end

		imgui.text(save_file_name .. "_nodes.json")
		imgui.text(save_file_name .. "_edges.json")

		open_export_modal = false
		imgui.separator()
		if imgui.button("CANCEL") then
			imgui.close_current_popup()
		end

		imgui.same_line()

		if imgui.button("SAVE") then
			data.selected_file = add_file(save_file_name .. ".json")
			imgui.close_current_popup()
			save()
			save_exports(export_nodes, export_edges)
		end
		imgui.end_popup()
	end
end


-- =======================================
-- Imgui Update
-- =======================================

function graph_imgui.update()
	--	print("want_mouse_input", imgui.want_mouse_input())
	data.want_mouse_input = imgui.want_mouse_input()

	main_menu_bar()
	--imgui.demo()
	tools()
	settings()
	stats()
	node()

	if open_file_modal then
		imgui.open_popup("Select File", imgui.WINDOWFLAGS_ALWAYSAUTORESIZE)
	end

	if open_save_modal then
		imgui.open_popup("Save File", imgui.WINDOWFLAGS_ALWAYSAUTORESIZE)
	end

	if open_export_modal then
		imgui.open_popup("Export File", imgui.WINDOWFLAGS_ALWAYSAUTORESIZE)
	end

	file_select_modal()
	file_save_modal()
	file_export_modal()
end

return graph_imgui
