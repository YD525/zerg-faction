local SpawnerBuilder = require("scripts.spawner_builder")
local SpawnerManager = require("scripts.spawner_manager")

script.on_init(function()
    
end)

script.on_event(defines.events.on_built_entity, function(event)
    SpawnerBuilder.onEntityBuilt(event)
end)

script.on_nth_tick(3000, function(event)
    SpawnerManager.SpawnUnits(event)
   -- SpawnerManager.SpawnBuildings(event)
end)

script.on_nth_tick(5000, function(event)
    SpawnerManager.SpawnBuildings(event)
   -- SpawnerManager.SpawnBuildings(event)
end)



script.on_event(defines.events.on_entity_died, function(event)
    local entity = event.entity
    if not entity or not entity.valid then return end

    if entity.type ~= "unit-spawner" then return end

    local cause = event.cause
    if not cause or not cause.valid or not cause.force then return end

    if entity.force == cause.force then return end

    if not cause.force.name:find("^friendly%-zerg") then
        return
    end

    if math.random() > 0.7 then
        return
    end

    if event.loot then
        event.loot.clear()
    end

    local clone_data = {
        position = entity.position,
        force = cause.force,
        surface = entity.surface,
    }

    local new_entity = entity.clone(clone_data)
    if new_entity and new_entity.valid then
        local max_hp = 200 

        local success, result = pcall(function()
            return new_entity.prototype.max_health
        end)

        if success and result then
            max_hp = result
        end

        new_entity.health = max_hp / 2
    end

    if entity.valid then
        entity.destroy()
    end
end)