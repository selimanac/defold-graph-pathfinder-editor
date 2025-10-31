local const            = require("graph_editor.scripts.const")

-- =======================================
-- MODULE
-- =======================================

local data             = {}

-- =======================================
-- VARIABLES
-- =======================================
data.nodes             = {}
data.edges             = {}
data.editor_state      = 0
data.mouse_position    = vmath.vector3(0, 0, 1)
data.want_mouse_input  = false
data.path_smoothing_id = 0
data.action_status     = ""
data.is_node_selected  = false
data.selected_node     = {}
data.agent_mode        = const.AGEND_MODE.NODE_TO_NODE
data.stats             = {}
data.selected_file     = -1

data.options           = {
	-- Node to Node

	node_to_node           = {
		is_active     = false,
		start_node_id = 0,
		goal_node_id  = 0,
		max_path      = 32,
	},

	-- Projected to Node
	projected_to_node      = {
		is_active    = false,
		goal_node_id = 0,
		max_path     = 32,
	},

	-- Node to Projected
	node_to_projected      = {
		is_active     = false,
		start_node_id = 0,
		max_path      = 32,
	},

	-- Projected to Projected
	projected_to_projected = {
		is_active      = false,
		start_position = vmath.vector3(10, 10, 0.8),
		max_path       = 32,
	},



	-- Draw
	draw = {
		nodes       = true,
		edges       = true,
		paths       = true,
		smooth_path = true,
	},


	-- Smoothing
	smoothing_config = {
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

data.path              = {
	node_to_node = {
		size        = 0,
		status      = -100,
		status_text = "",
		path        = {}
	},

	projected_to_node = {
		size        = 0,
		status      = -100,
		status_text = "",
		entry_point = vmath.vector3(),
		path        = {}
	},

	node_to_projected = {
		size        = 0,
		status      = -100,
		status_text = "",
		exit_point  = vmath.vector3(),
		path        = {}
	},

	projected_to_projected = {
		size        = 0,
		status      = -100,
		status_text = "",
		entry_point = vmath.vector3(),
		exit_point  = vmath.vector3(),
		path        = {}
	}

}


return data
