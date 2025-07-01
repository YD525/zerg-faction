-- scripts/spawner_builder.lua
local SpawnerBuilder = {}

-- Ensures the "friendly-zerg" force exists and sets up friendly relations with players.
function SpawnerBuilder.EnsureFriendlyForce(player_index)
    if not player_index then return nil end

    local force_name = "friendly-zerg-" .. tostring(player_index)
    local FriendlyForce = game.forces[force_name]
    if not FriendlyForce then
        FriendlyForce = game.create_force(force_name)
        FriendlyForce.friendly_fire = false 
    end
    return FriendlyForce
end

function SpawnerBuilder.AllyWithPlayerForce(player_index)
    local FriendlyForce = game.forces["friendly-zerg"]
    local player = game.players[player_index]
    if not FriendlyForce or not player or not player.valid then return end

    local PlayerForce = player.force
    FriendlyForce.set_friend(PlayerForce, true)
    PlayerForce.set_friend(FriendlyForce, true)
    FriendlyForce.set_cease_fire(PlayerForce, true)
    PlayerForce.set_cease_fire(FriendlyForce, true)
end

-- Handles actions when an entity is built by the player.

function SpawnerBuilder.onEntityBuilt(event)
    local entity = event.created_entity or event.entity
    if not entity.valid then return end

    if entity.name == "biter-spawner-placeholder" then
        local surface = entity.surface
        local position = entity.position
        local player_index = event.player_index

        if player_index then
            local player = game.get_player(player_index)
            if player and player.valid then
                local force_name = "friendly-zerg-" .. tostring(player_index)
                SpawnerBuilder.EnsureFriendlyForce(player_index)
                local player_force = player.force
                local friendly_force = game.forces[force_name]

                if friendly_force then
                    friendly_force.set_friend(player_force, true)
                    player_force.set_friend(friendly_force, true)
                    friendly_force.set_cease_fire(player_force, true)
                    player_force.set_cease_fire(friendly_force, true)
                end

                local replace_entity = surface.create_entity{
                    name = "biter-spawner",
                    position = position,
                    force = force_name,
                    raise_built = true
                }
            end
        end

        entity.destroy()

    elseif entity.name == "spawner-remove-capsule-entity" then
    local surface = entity.surface
    local position = entity.position
    local player = game.get_player(event.player_index)
    local player_index = event.player_index
    if not player_index then return end

    local player_force_name = "friendly-zerg-" .. tostring(player_index)

    game.print("Removing capsule placed. Scanning nearby entities...")

    local scan_radius = 10

    local entities_in_area = surface.find_entities_filtered{
        area = {
            {position.x - scan_radius, position.y - scan_radius},
            {position.x + scan_radius, position.y + scan_radius}
        }
    }

    local removed_spawner_count = 0
    local removed_units_and_turrets_count = 0

    -- First remove the spawner and count it, then return a spawner placeholder
    for _, found_entity in pairs(entities_in_area) do
        if found_entity and found_entity.valid and found_entity.force and found_entity.force.name == player_force_name then
            if found_entity.name == "biter-spawner" then
                game.print("Found and removed " .. found_entity.force.name .. " biter spawner: " .. found_entity.name ..
                           " (Position: " .. found_entity.position.x .. ", " .. found_entity.position.y .. ").")
                found_entity.destroy()
                removed_spawner_count = removed_spawner_count + 1
            elseif (found_entity.type == "turret" or found_entity.type == "unit") then
                found_entity.destroy()
                removed_units_and_turrets_count = removed_units_and_turrets_count + 1
            end
        end
    end

    game.print("Scan complete. Removed " .. removed_spawner_count .. " friendly-zerg biter spawners and " ..
               removed_units_and_turrets_count .. " units/turrets.")

    entity.destroy()

    if player and player.valid then
        if removed_spawner_count > 0 then
            local spawner_item_name = "biter-spawner-placeholder"
            local inserted_spawner_count = player.insert{name = spawner_item_name, count = removed_spawner_count}
            if inserted_spawner_count < removed_spawner_count then
                local remaining = removed_spawner_count - inserted_spawner_count
                surface.spill_item_stack(position, {name = spawner_item_name, count = remaining}, true)
                game.print("Some spawner placeholders returned to inventory, " .. remaining .. " spilled on ground (inventory full).")
            else
                game.print("All spawner placeholders returned to player inventory.")
            end
        end

        if removed_units_and_turrets_count > 0 then
            local zerg_egg_item_name = "biter-egg"
            local inserted_egg_count = player.insert{name = zerg_egg_item_name, count = removed_units_and_turrets_count}
            if inserted_egg_count < removed_units_and_turrets_count then
                local remaining_eggs = removed_units_and_turrets_count - inserted_egg_count
                if remaining_eggs > 3  then
                    remaining_eggs = 3
                end
                surface.spill_item_stack(position, {name = zerg_egg_item_name, count = remaining_eggs}, true)
                game.print("Some zerg eggs returned to inventory, " .. remaining_eggs .. " spilled on ground (inventory full).")
            else
                game.print("All zerg eggs returned to player inventory.")
            end
        end
    else
        -- No players present, directly discard all returned items.
        if removed_spawner_count > 0 then
            surface.spill_item_stack(position, {name = "biter-spawner-placeholder", count = removed_spawner_count}, true)
        end
        if removed_units_and_turrets_count > 0 then
            surface.spill_item_stack(position, {name = "biter-egg", count = removed_units_and_turrets_count}, true)
        end
        game.print("Items spilled on ground (no player found).")
    end
    end
end

return SpawnerBuilder