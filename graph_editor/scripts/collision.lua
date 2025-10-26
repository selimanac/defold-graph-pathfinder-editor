local const              = require("graph_editor.scripts.const")

local collision          = {}

collision.COLLISION_BITS = {
	NODE  = 1,
	EDGE  = 2,
	MOUSE = 4,
	ALL   = bit.bnot(0) -- -1 for all results
}

local aabb_group_id      = 0
collision.pointer_id     = 0
function collision.init()
	aabb_group_id = daabbcc.new_group(daabbcc.UPDATE_PARTIALREBUILD)
	collision.pointer_id = collision.insert_gameobject(const.MOUSE, 16, 16, collision.COLLISION_BITS.MOUSE)
end

function collision.insert_aabb(x, y, width, height, collision_bit)
	collision_bit = collision_bit and collision_bit or nil
	return daabbcc.insert_aabb(aabb_group_id, x, y, width, height, collision_bit)
end

function collision.insert_gameobject(go_url, width, height, collision_bit)
	collision_bit = collision_bit and collision_bit or nil
	return daabbcc.insert_gameobject(aabb_group_id, go_url, width, height, collision_bit)
end

function collision.query_aabb(x, y, width, height, collision_bit, get_manifold)
	local mask_bits = collision_bit and collision_bit or nil
	get_manifold    = get_manifold and get_manifold or nil
	return daabbcc.query_aabb(aabb_group_id, x, y, width, height, mask_bits, get_manifold)
end

function collision.query_id(aabb_id, collision_bit, get_manifold)
	local mask_bits = collision_bit and collision_bit or nil
	get_manifold    = get_manifold and get_manifold or nil
	return daabbcc.query_id(aabb_group_id, aabb_id, mask_bits, get_manifold)
end

function collision.query_mouse_node()
	return daabbcc.query_id(aabb_group_id, collision.pointer_id, collision.COLLISION_BITS.NODE)
end

function collision.query_mouse_edge()
	return daabbcc.query_id_sort(aabb_group_id, collision.pointer_id, collision.COLLISION_BITS.EDGE)
end

function collision.query_id_sort(aabb_id, collision_bit, get_manifold)
	local mask_bits = collision_bit and collision_bit or nil
	get_manifold    = get_manifold and get_manifold or nil
	return daabbcc.query_id_sort(aabb_group_id, aabb_id, mask_bits, get_manifold)
end

function collision.query_aabb_sort(x, y, width, height, collision_bit, get_manifold)
	local mask_bits = collision_bit and collision_bit or nil
	get_manifold    = get_manifold and get_manifold or nil
	return daabbcc.query_aabb_sort(aabb_group_id, x, y, width, height, mask_bits, get_manifold)
end

function collision.raycast(ray_start, ray_end, collision_bit, get_manifold)
	local mask_bits = collision_bit and collision_bit or nil
	get_manifold    = get_manifold and get_manifold or nil
	return daabbcc.raycast(aabb_group_id, ray_start.x, ray_start.y, ray_end.x, ray_end.y, mask_bits, get_manifold)
end

function collision.raycast_sort(ray_start, ray_end, collision_bit, get_manifold)
	local mask_bits = collision_bit and collision_bit or nil
	get_manifold    = get_manifold and get_manifold or nil
	return daabbcc.raycast_sort(aabb_group_id, ray_start.x, ray_start.y, ray_end.x, ray_end.y, mask_bits, get_manifold)
end

function collision.update_aabb(aabb)
	daabbcc.update_aabb(aabb_group_id, aabb.aabb_id, aabb.position.x, aabb.position.y, aabb.size.width, aabb.size.height)
end

function collision.reset()
	daabbcc.reset()
end

function collision.remove(aabb_id)
	daabbcc.remove(aabb_group_id, aabb_id)
end

return collision
