local data            = require("graph_editor.scripts.editor_data")
local const           = require("graph_editor.scripts.editor_const")
local utils           = require("graph_editor.scripts.editor_utils")

-- =======================================
-- MODULE
-- =======================================
local agents          = {}

-- =======================================
-- VARIABLES
-- =======================================
local agent_container = {}
local agent_states    = {
	INACTIVE   = 0, -- Not in navigation system
	ACTIVE     = 1, -- Following path
	PAUSED     = 2, -- Paused by application
	REPLANNING = 3, -- Detected invalidation, finding new path
	ARRIVED    = 4 -- Reached goal
}

local agent_config    = const.IS_XZ_PLANE and const.AGENT_CONFIG_XZ or const.AGENT_CONFIG_XY

function agents.add()
	local path = data.path[const.AGENT_TO_PATH[data.agent_mode]].path
	local path_status = data.path[const.AGENT_TO_PATH[data.agent_mode]].status

	if path_status ~= pathfinder.PathStatus.SUCCESS then
		data.action_status = const.EDITOR_STATUS.NO_PATH_FOR_AGENT

		timer.delay(const.TIMER_DELAYS.AGENT_ERROR, false, function()
			data.action_status = const.EDITOR_STATUS.ADD_AGENT
		end)

		return
	end

	local path_size        = data.path[const.AGENT_TO_PATH[data.agent_mode]].size
	local initial_position = vmath.vector3(0.0)

	if data.agent_mode == const.AGENT_MODE.NODE_TO_NODE or data.agent_mode == const.AGENT_MODE.NODE_TO_PROJECTED then
		initial_position = utils.pathfinder_to_vec3(path[1].x, path[1].y)
	end

	if data.agent_mode == const.AGENT_MODE.PROJECTED_TO_NODE then
		initial_position = data.mouse_position
	end

	if data.agent_mode == const.AGENT_MODE.PROJECTED_TO_PROJECTED then
		initial_position = data.options.projected_to_projected.start_position
	end

	local target_pos_v2   = pathfinder.get_node_position(1)
	local target_pos      = utils.pathfinder_to_vec3(target_pos_v2.x, target_pos_v2.y)
	local to_target       = target_pos - initial_position
	local target_rotation = 0
	local target_quat     = vmath.quat()

	if const.IS_XZ_PLANE then
		target_rotation = math.atan2(to_target.x, to_target.z)
		target_quat     = vmath.quat_rotation_y(target_rotation)
	else
		target_rotation = math.atan2(to_target.y, to_target.x)
		target_quat     = vmath.quat_rotation_z(target_rotation)
	end

	local agent = {
		position            = initial_position,
		max_speed           = agent_config.MAX_SPEED,
		rotation_speed      = agent_config.ROTATION_SPEED,
		speed               = 0,
		rotation            = target_quat,
		rotation_angle      = 0,
		path                = path,
		path_size           = path_size,
		current_waypoint_id = 1,
		instance            = factory.create(const.FACTORIES.AGENT, initial_position),
		state               = agent_states.ACTIVE,
		id                  = 0
	}

	table.insert(agent_container, agent)
	agent_container[#agent_container].id = #agent_container
end

local function get_current_waypoint_position(agent)
	if agent.current_waypoint_id > agent.path_size then
		return agent.position -- No waypoint, stay in place
	end

	local node = agent.path[agent.current_waypoint_id] -- Only for static nodes

	return utils.pathfinder_to_vec3(node.x, node.y)
end

local function check_waypoint_arrival(agent)
	if agent.current_waypoint_id > agent.path_size then
		return false -- No more waypoint
	end

	local waypoint_position = get_current_waypoint_position(agent)
	local waypoint_distance = vmath.length(agent.position - waypoint_position)

	-- Simple arrival threshold
	if waypoint_distance <= agent_config.ARRIVAL_THRESHOLD then
		--  Reached waypoint, advance to next
		agent.current_waypoint_id = agent.current_waypoint_id + 1

		if agent.current_waypoint_id > agent.path_size then
			agent.state = agent_states.ARRIVED
			agent.speed = 0
			return true
		end

		return true -- Advanced to next waypoint
	end

	return false --  Not yet arrived
end

local function remove_agent(agent_id, agent)
	agent.state = agent_states.INACTIVE
	go.delete(agent.instance)
	table.remove(agent_container, agent_id)
end

function agents.update(dt)
	for agent_id, agent in ipairs(agent_container) do
		-- Only process active agents
		if agent.state == agent_states.ACTIVE then
			-- Check if agent reached current waypoint
			if not check_waypoint_arrival(agent) or agent.state ~= agent_states.ARRIVED then
				-- Get target waypoint position
				local target_pos = get_current_waypoint_position(agent)

				-- Calculate direction to target
				local to_target = target_pos - agent.position
				local distance = vmath.length(to_target)

				if distance >= const.EPSILON then
					-- Calculate direction unit vector
					local direction = to_target * (1.0 / distance)

					-- Calculate target rotation angle
					local target_rotation
					local target_quat

					if const.IS_XZ_PLANE then
						target_rotation = math.atan2(direction.x, direction.z)
						target_quat     = vmath.quat_rotation_y(target_rotation)
					else
						target_rotation = math.atan2(direction.y, direction.x)
						target_quat     = vmath.quat_rotation_z(target_rotation)
					end

					-- Get current rotation quaternion
					local current_quat = agent.rotation

					local t = math.min(1.0, agent.rotation_speed * dt)
					agent.rotation = vmath.slerp(t, current_quat, target_quat)

					agent.rotation_angle = target_rotation --  for reference (optional)

					-- Calculate movement for this frame and clamp
					local movement_distance = math.min(agent.max_speed * dt, distance)

					agent.position = agent.position + (direction * movement_distance)

					-- Set the up axis to 0
					if const.IS_XZ_PLANE then
						agent.position.y = 0.0
					else
						agent.position.z = 0.2
					end

					go.set_position(agent.position, agent.instance)
					go.set_rotation(agent.rotation, agent.instance)

					agent.speed = agent.max_speed
				end
			else
				remove_agent(agent_id, agent)
			end
		else
			remove_agent(agent_id, agent)
		end
	end
end

function agents.get_count()
	return #agent_container
end

return agents
