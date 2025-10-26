local style          = require("graph_editor.scripts.imgui_style")
local data           = require("graph_editor.scripts.data")
local const          = require("graph_editor.scripts.const")
local graph          = require("graph_editor.scripts.graph")
local graph_imgui    = {}

-- =======================================
-- VARS
-- =======================================
local flags          = bit.bor(imgui.WINDOWFLAGS_NOTITLEBAR)
local changed        = false
local checked        = false
local int_value      = 0
local float_value    = 0.0

local save_load_text = ""
-- =======================================
-- Save
-- =======================================

local function prepare_for_save()
	for key, node in pairs(data.nodes) do
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

	pprint(data.nodes)
end


local function save()
	save_load_text = const.FILE_STATUS.SAVE_SUCCESS
	prepare_for_save()


	local filename = sys.get_save_file("defold-graph-pathfinder-editor", "editor")
	local loaded_data = sys.save(filename, { nodes = data.nodes, edges = data.edges })

	save_load_text = loaded_data and const.FILE_STATUS.SAVE_SUCCESS or const.FILE_STATUS.SAVE_ERROR

	timer.delay(0.7, false, function()
		save_load_text = ""
	end)
end

local function load()
	local filename = sys.get_save_file("defold-graph-pathfinder-editor", "editor")
	local loaded_data = sys.load(filename)

	save_load_text = loaded_data and const.FILE_STATUS.LOAD_SUCCESS or const.FILE_STATUS.LOAD_ERROR

	if loaded_data then
		graph.load(loaded_data)
	end

	timer.delay(0.7, false, function()
		save_load_text = ""
	end)
end

local function export_json()
	-- body
end

local function export_lua()
	-- body
end

-- =======================================
-- Main Menu
-- =======================================
local function main_menu_bar(self)
	if imgui.begin_main_menu_bar() then
		if imgui.begin_menu("File") then
			if imgui.menu_item("Load", "Ctrl+L") then
				load()
			end

			if imgui.menu_item("Save", "Ctrl+S") then
				save()
			end

			if imgui.menu_item("Export JSON", "Ctrl+J") then
				export_json()
			end

			if imgui.menu_item("Export LUA", "Ctrl+L") then
				export_lua()
			end

			if imgui.menu_item("Quit", "Ctrl+Q") then
				sys.exit(0)
			end


			imgui.end_menu()
		end

		if imgui.begin_menu("Edit") then
			local clicked = imgui.menu_item("Reset", nil, nil)
			if clicked then
				graph.reset()
				graph.init()
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
		print("window.WINDOW_EVENT_FOCUS_LOST")
	elseif event == window.WINDOW_EVENT_FOCUS_GAINED then
		print("window.WINDOW_EVENT_FOCUS_GAINED")
	elseif event == window.WINDOW_EVENT_ICONFIED then
		print("window.WINDOW_EVENT_ICONFIED")
	elseif event == window.WINDOW_EVENT_DEICONIFIED then
		print("window.WINDOW_EVENT_DEICONIFIED")
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

	window.set_listener(window_callback)
end

-- =======================================
-- Imgui Update
-- =======================================

function graph_imgui.update()
	--	print("want_mouse_input", imgui.want_mouse_input())
	data.want_mouse_input = imgui.want_mouse_input()
	main_menu_bar()
	--imgui.demo()

	imgui.set_next_window_size(180, 250)
	-- =======================================
	-- TOOLS
	-- =======================================

	imgui.begin_window("TOOLS", nil, flags)

	--	data.is_window_hovered = imgui.is_window_hovered()
	--	data.is_window_focused = imgui.is_window_focused()
	--	print("data.is_window_hovered", data.is_window_hovered)
	--	print("is_window_focused", imgui.is_window_focused())


	if imgui.radio_button("Add Node", data.editor_state == const.EDITOR_STATES.ADD_NODE) then
		data.editor_state = const.EDITOR_STATES.ADD_NODE
	end
	if imgui.radio_button("Remove Node", data.editor_state == const.EDITOR_STATES.REMOVE_NODE) then
		data.editor_state = const.EDITOR_STATES.REMOVE_NODE
	end

	if imgui.radio_button("Move Node", data.editor_state == const.EDITOR_STATES.MOVE_NODE) then
		data.editor_state = const.EDITOR_STATES.MOVE_NODE
	end

	imgui.separator()

	if imgui.radio_button("Add Edge", data.editor_state == const.EDITOR_STATES.ADD_EDGE) then
		data.editor_state = const.EDITOR_STATES.ADD_EDGE
	end

	imgui.separator()

	if imgui.radio_button("Add Agent", data.editor_state == const.EDITOR_STATES.ADD_AGENT) then
		data.editor_state = const.EDITOR_STATES.ADD_AGENT
	end


	imgui.end_window()


	-- =======================================
	-- STATUS
	-- =======================================
	imgui.begin_window("STATUS", nil, flags)
	imgui.text("Path Status: ")
	imgui.same_line()
	local status_color = data.path.status == pathfinder.PathStatus.SUCCESS and const.COLORS.GREEN or const.COLORS.RED
	imgui.text_colored(data.path.status_text, status_color.x, status_color.y, status_color.z, 1)


	imgui.text("Projected Path Status: ")
	imgui.same_line()
	local status_color = data.projected_path.status == pathfinder.PathStatus.SUCCESS and const.COLORS.GREEN or const.COLORS.RED
	imgui.text_colored(data.projected_path.status_text, status_color.x, status_color.y, status_color.z, 1)


	imgui.end_window()

	-- =======================================
	-- SETTINGS
	-- =======================================

	imgui.begin_window("SETTINGS", nil, flags)
	--print(imgui.is_window_focused())
	data.is_window_hovered = imgui.is_window_hovered()

	imgui.text_colored("-> PATHS", 1, 0, 0, 1)
	imgui.separator()

	changed, checked = imgui.checkbox("Find Path", data.options.find_path)
	if changed then
		data.options.find_path = checked
	end

	imgui.set_next_item_width(250)
	changed, int_value = imgui.input_int("Start Node Id", data.options.find_path_start_node_id)
	if changed then
		data.options.find_path_start_node_id = int_value
	end

	imgui.set_next_item_width(250)
	changed, int_value = imgui.input_int("Goal Node Id", data.options.find_path_goal_node_id)
	if changed then
		data.options.find_path_goal_node_id = int_value
	end

	imgui.set_next_item_width(250)
	changed, int_value = imgui.input_int("Max Path Lenght", data.options.find_path_max_path)
	if changed then
		data.options.find_path_max_path = int_value
	end

	imgui.separator()
	imgui.text_colored("-> PROJECTED PATHS", 1, 0, 0, 1)
	imgui.separator()

	changed, checked = imgui.checkbox("Find Projected Path", data.options.find_projected_path)
	if changed then
		data.options.find_projected_path = checked
	end

	imgui.set_next_item_width(250)
	changed, int_value = imgui.input_int("Projected Goal Node Id", data.options.find_projected_path_goal_node_id)
	if changed then
		data.options.find_projected_path_goal_node_id = int_value
	end

	imgui.set_next_item_width(250)
	changed, int_value = imgui.input_int("Projected Max Path Lenght", data.options.find_projected_path_max_path)
	if changed then
		data.options.find_projected_path_max_path = int_value
	end

	imgui.separator()
	imgui.text_colored("-> DRAW", 1, 0, 0, 1)
	imgui.separator()

	-- =======================================
	-- DRAW
	-- =======================================

	changed, checked = imgui.checkbox("Draw Nodes", data.options.draw_nodes)
	if changed then
		data.options.draw_nodes = checked
		graph.set_nodes_visiblity()
	end

	imgui.same_line()
	changed, checked = imgui.checkbox("Draw Edges", data.options.draw_edges)
	if changed then
		data.options.draw_edges = checked
	end


	changed, checked = imgui.checkbox("Draw Path", data.options.draw_path)
	if changed then
		data.options.draw_path = checked
	end

	imgui.same_line()

	changed, checked = imgui.checkbox("Draw Projected Path", data.options.draw_projected_path)
	if changed then
		data.options.draw_projected_path = checked
	end

	changed, checked = imgui.checkbox("Draw Smooth Path", data.options.draw_smooth_path)
	if changed then
		data.options.draw_smooth_path = checked
	end

	imgui.same_line()

	changed, checked = imgui.checkbox("Draw Projected Smooth Path", data.options.draw_projected_smooth_path)
	if changed then
		data.options.draw_projected_smooth_path = checked
	end

	imgui.separator()
	imgui.text_colored("-> SHOOTHING", 1, 0, 0, 1)
	imgui.separator()

	-- =======================================
	-- SHOOTHING
	-- =======================================
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


	imgui.end_window()
end

return graph_imgui
