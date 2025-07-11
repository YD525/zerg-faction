local SwarmController = {}

local function get_direction_to_target(from_position, to_position)
    local dx = to_position.x - from_position.x
    local dy = to_position.y - from_position.y
    local angle_rad = math.atan2(dy, dx)
    local factorio_angle_deg = (math.deg(angle_rad) + 90 + 360) % 360
    local factorio_direction = math.floor((factorio_angle_deg / 45) + 0.5) % 8
    return factorio_direction
end

function SwarmController.MoveToFollowEntity(unit_list,player_index)
    if not unit_list or #unit_list == 0 then return false end

    local commanded_count = 0
    local force_name = "friendly-zerg-" .. tostring(player_index)
    local Player = game.get_player(player_index)
    local Surface = Player.surface

    local Position = {
        x =  Player.character.position.x,
        y =  Player.character.position.y
    }
    
    local Group = Surface.create_unit_group{
        position = Position,
        force = game.forces[force_name]
    }

    for i = 1, #unit_list do
        local unit_entity = unit_list[i]

        if unit_entity and unit_entity.valid and unit_entity.type == "unit" and unit_entity.force.name == force_name then
            Group.add_member(unit_entity)
            commanded_count = commanded_count + 1
        end
    end

    Group.set_command
    {
        type = defines.command.go_to_location,
        destination = Player.character.position,
        radius = 0.1
    }

    return commanded_count > 0
end

return SwarmController
