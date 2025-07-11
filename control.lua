local SpawnerBuilder = require("scripts.spawner_builder")
local SpawnerManager = require("scripts.spawner_manager")
local SwarmController = require("scripts.swarm_controller")

script.on_init(function()
    
end)

script.on_event(defines.events.on_built_entity, function(event)
    local new_entity = SpawnerBuilder.onEntityBuilt(event)
    if new_entity and new_entity.valid then
        local surface = new_entity.surface
        SpawnerManager.UpdateEntityCache(surface, "unit-spawner")
        SpawnerManager.UpdateEntityCache(surface, "turret")
        SpawnerManager.UpdateEntityCache(surface, "unit")
    end
end)

script.on_nth_tick(3000, function(event)
    SpawnerManager.InitNames(game.surfaces["nauvis"])
    SpawnerManager.SpawnUnits(event)
   -- SpawnerManager.SpawnBuildings(event)
end)

script.on_nth_tick(5000, function(event)
    SpawnerManager.InitNames(game.surfaces["nauvis"])
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

script.on_event(defines.events.on_player_selected_area, function(event)
  if event.item ~= "zfswarm-assembly-point" then return end

  local player_index = event.player_index
  local player = game.get_player(player_index)
  local selected_units = {}

  for _, entity in pairs(event.entities) do
    if entity.valid and entity.type == "unit" then
      if SpawnerManager.IsFriendlyZergUnit(entity, player_index) then
        table.insert(selected_units, entity)
      end
    end
  end

  SwarmController.MoveToFollowEntity(selected_units,player_index)
end)
