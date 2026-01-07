local data        = require("graph_editor.scripts.editor_data")
local const       = require("graph_editor.scripts.editor_const")
local graph       = require("graph_editor.scripts.editor_graph")
local graph_imgui = require("graph_editor.scripts.graph_imgui")
local agents      = require("graph_editor.scripts.editor_agents")
local draw        = require("graph_editor.scripts.editor_draw")
local utils       = require("graph_editor.scripts.editor_utils")

-- =======================================
-- MODULE
-- =======================================
local editor      = {}


--- Initialize the editor
-- Sets up ImGui and the graph system
function editor.init()
	-- Initialize project folder path with error handling
	local path, err = project_path.get()
	if not path then
		error(string.format("Failed to get project root path: %s", err or "unknown error"))
	end
	const.GRAPH_EDITOR.FOLDER = path .. "/" .. sys.get_config_string("graph_editor.folder")

	graph_imgui.init()
	graph.init()
end

function editor.update(dt)
	graph_imgui.update()

	if data.options.draw.edges then
		draw.edges()
	end

	if data.options.node_to_node.is_active then
		draw.node_to_node()
	end

	if data.options.projected_to_node.is_active then
		draw.projected_to_node()
	end

	if data.options.node_to_projected.is_active then
		draw.node_to_projected()
	end

	if data.options.projected_to_projected.is_active then
		draw.projected_to_projected()
	end

	data.stats = pathfinder.get_stats()
	agents.update(dt)
end

function editor.input(action_id, action)
	if action.screen_x then
		data.mouse_position = utils.screen_to_plane(const.VIEWPORT_CAMERA, action.screen_x, action.screen_y)

		if data.mouse_position ~= nil then
			go.set_position(data.mouse_position, const.MOUSE)
		end
	end

	graph.input(action_id, action)
end

return editor
