local data = {}

data.editor_state = 0
data.mouse_position = vmath.vector3(0, 0, 1)

data.nodes = {}
data.edges = {}
data.is_window_hovered = false
data.is_window_focused = false
data.want_mouse_input = false

data.path_smoothing_id = 0

data.options = {
	-- Normal Paths
	find_path                        = false,
	find_path_start_node_id          = 0,
	find_path_goal_node_id           = 0,
	find_path_max_path               = 32,

	-- Projected Paths
	find_projected_path              = false,
	find_projected_path_goal_node_id = 0,
	find_projected_path_max_path     = 32,

	-- Draw
	draw_nodes                       = true,
	draw_edges                       = true,
	draw_path                        = true,
	draw_projected_path              = true,
	draw_smooth_path                 = true,
	draw_projected_smooth_path       = true,

	-- Smoothing
	smoothing_config                 = {
		style                               = pathfinder.PathSmoothStyle.BEZIER_QUADRATIC,
		bezier_sample_segment               = 8, -- Number of segments per curve
		bezier_control_point_offset         = 0.5, -- For bezier_cubic style
		bezier_curve_radius                 = 0.5, -- For bezier_quadratic style (active)
		bezier_adaptive_tightness           = 0.4, -- For bezier_adaptive style
		bezier_adaptive_roundness           = 0.4, -- For bezier_adaptive style
		bezier_adaptive_max_corner_distance = 50.0, -- For bezier_adaptive style
		bezier_arc_radius                   = 40.0, -- For circular_arc style
	}
}

data.path = {
	size = 0,
	status = 0,
	status_text = "",
	path = {}
}

data.projected_path = {
	size = 0,
	status = 0,
	status_text = "",
	entry_point = vmath.vector3(),
	path = {}
}


return data
