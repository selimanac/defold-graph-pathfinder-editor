local data            = require("graph_editor.scripts.data")
local const           = require("graph_editor.scripts.const")

-- =======================================
-- MODULE
-- =======================================
local agents          = {}

-- =======================================
-- VARIABLES
-- =======================================
local agent_container = {}
local EPSILON         = 0.0001
local agent_states    = {
	INACTIVE   = 0, -- Not in navigation system
	ACTIVE     = 1, -- Following path
	PAUSED     = 2, -- Paused by application
	REPLANNING = 3, -- Detected invalidation, finding new path
	ARRIVED    = 4 -- Reached goal
}

function agents.add()
	local path = data.path[const.AGENT_TO_PATH[data.agent_mode]].path
	local path_status = data.path[const.AGENT_TO_PATH[data.agent_mode]].status

	if path_status ~= pathfinder.PathStatus.SUCCESS then
		data.action_status = const.EDITOR_STATUS.NO_PATH_FOR_AGENT

		timer.delay(1.5, false, function()
			data.action_status = const.EDITOR_STATUS.ADD_AGENT
		end)

		return
	end
	local path_size = data.path[const.AGENT_TO_PATH[data.agent_mode]].size

	local initial_posiiton = vmath.vector3(0.9)

	if data.agent_mode == const.AGEND_MODE.NODE_TO_NODE or data.agent_mode == const.AGEND_MODE.NODE_TO_PROJECTED then
		initial_posiiton.x = path[1].x
		initial_posiiton.y = path[1].y
	end

	if data.agent_mode == const.AGEND_MODE.PROJECTED_TO_NODE then
		initial_posiiton.x = data.mouse_position.x
		initial_posiiton.y = data.mouse_position.y
	end

	if data.agent_mode == const.AGEND_MODE.PROJECTED_TO_PROJECTED then
		initial_posiiton.x = data.options.projected_to_projected.start_position.x
		initial_posiiton.y = data.options.projected_to_projected.start_position.y
	end

	local agent = {
		position            = initial_posiiton,
		velocity            = vmath.vector3(),
		max_speed           = 300,
		speed               = 0,
		rotation            = 0,
		path                = path,
		path_size           = path_size,
		current_waypoint_id = 1,
		instance            = factory.create(const.FACTORIES.AGENT, initial_posiiton),
		state               = agent_states.ACTIVE,
		id                  = 0
	}

	table.insert(agent_container, agent)
	agent_container[#agent_container].id = #agent_container

	print("AGEND ADEED: ", agent_container[#agent_container].id)
end

local function get_current_waypoint_position(agent)
	if agent.current_waypoint_id > agent.path_size then
		return agent.position -- No waypoint, stay in place
	end

	local node = agent.path[agent.current_waypoint_id] -- Only for static nodes
	return vmath.vector3(node.x, node.y, 0)
end

local function check_waypoint_arrival(agent)
	if agent.current_waypoint_id > agent.path_size then
		return false -- No more waypoint
	end

	local waypoint_position = get_current_waypoint_position(agent)
	local waypoint_distance = vmath.length(agent.position - waypoint_position)

	-- Simple arrival threshold - very tight for point-to-point movement
	local arrival_threshold = 0.5

	if waypoint_distance <= arrival_threshold then
		--  Reached waypoint, advance to next
		agent.current_waypoint_id = agent.current_waypoint_id + 1

		if agent.current_waypoint_id > agent.path_size then
			agent.state      = agent_states.ARRIVED
			agent.velocity.x = 0
			agent.velocity.y = 0
			agent.speed      = 0
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

				if distance >= EPSILON then
					-- Calculate direction unit vector
					local direction = to_target * (1.0 / distance)

					-- Set rotation immediately to face target
					agent.rotation = math.atan2(direction.y, direction.x) % (2 * math.pi)

					-- Calculate movement for this frame and clamp
					local movement_distance = math.min(agent.max_speed * dt, distance)

					-- Update position and rotation
					agent.position = agent.position + (direction * movement_distance)
					agent.position.z = 0.1
					go.set_position(agent.position, agent.instance)
					go.set_rotation(vmath.quat_rotation_z(agent.rotation), agent.instance)
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
