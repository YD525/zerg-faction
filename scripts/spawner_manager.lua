local SpawnerManager = {}


local BASE_CHECK_RADIUS = 10  -- Base detection radius for each spawner  
local RELATED_SPAWNER_RANGE = 20  -- Distance threshold to consider spawners as related (within this range they are clustered)  
local MAX_CLUSTER_RADIUS_BONUS = 20  -- Maximum additional radius based on cluster size  
local UNITS_PER_SPAWNER_THRESHOLD = 8  -- Desired number of units per spawner in a cluster  
local TURRET_SPAWN_RADIUS = 5  -- Radius for spawning turrets around the cluster  


local function distance_squared(pos1, pos2)
    local dx = pos1.x - pos2.x
    local dy = pos1.y - pos2.y
    return dx*dx + dy*dy
end

local function cluster_spawners(spawners)
    local clusters = {}
    local processed_spawners = {}  

    for i = 1, #spawners do
        if not processed_spawners[i] then
            local current_spawner = spawners[i]
            local new_cluster = {current_spawner}
            processed_spawners[i] = true

            for j = i + 1, #spawners do
                if not processed_spawners[j] then
                    local other_spawner = spawners[j]
                    if distance_squared(current_spawner.position, other_spawner.position) < (RELATED_SPAWNER_RANGE * RELATED_SPAWNER_RANGE) then
                        table.insert(new_cluster, other_spawner)
                        processed_spawners[j] = true
                    end
                end
            end
            table.insert(clusters, new_cluster)
        end
    end
    return clusters
end

local function get_cluster_center(cluster)
    if #cluster == 0 then return nil end

    local sum_x = 0
    local sum_y = 0
    for _, spawner in pairs(cluster) do
        sum_x = sum_x + spawner.position.x
        sum_y = sum_y + spawner.position.y
    end
    return {x = sum_x / #cluster, y = sum_y / #cluster}
end

local function calculate_adjusted_radius(cluster_size)
    local radius_bonus = math.min(cluster_size * 2, MAX_CLUSTER_RADIUS_BONUS)
    return BASE_CHECK_RADIUS + radius_bonus
end

local function CountUnitsInArea(Surface, CenterPosition, Radius, ForceName)
    local search_area = {
        {CenterPosition.x - Radius, CenterPosition.y - Radius},
        {CenterPosition.x + Radius, CenterPosition.y + Radius}
    }

    local nearby_friendly_units = Surface.find_units({
        area = search_area,
        force = ForceName,
        condition = "same"
    })

    return #nearby_friendly_units
end


local function Contains(msg,substring)
    return string.find(msg, substring, 1, true) ~= nil
end

local function GetEntityNames(surface, entity_type, keyword)
    local entity_names = {}
    local seen = {} 

    for _, entity in pairs(surface.find_entities_filtered{type = entity_type}) do
        --game.print(entity.name)
        if Contains(entity.name, keyword) then
            if not seen[entity.name] then
                seen[entity.name] = true
                table.insert(entity_names, entity.name)
            end
        end
    end

    return entity_names
end

local function SpawnRandomEntity(surface, spawn_pos, cluster_force_name, entity_type, keyword)
    local entity_names = GetEntityNames(surface, entity_type, keyword)
    
    if #entity_names > 0 then
        local random_name = entity_names[math.random(#entity_names)] 
        --game.print(random_name)
        if surface.can_place_entity({name = random_name, position = spawn_pos, force = cluster_force_name}) then
            local entity = surface.create_entity{
                name = random_name,
                position = spawn_pos,
                force = cluster_force_name,
                raise_built = true
            }

            if entity and entity.valid then
                return entity
            else
                --Log("Failed to create entity: " .. random_name .. " at position: " .. serpent.line(spawn_pos))
            end
        else
           --Log("Cannot place entity: " .. random_name .. " at position: " .. serpent.line(spawn_pos))
        end
    else
       --Log("No entities found matching keyword: " .. keyword)
    end

    return nil
end

local function GetDirectionalSpawnPos(surface, cluster_center_pos, cluster_radius, force_name)
    local search_radius = cluster_radius + 300
    local area = {
        {cluster_center_pos.x - search_radius, cluster_center_pos.y - search_radius},
        {cluster_center_pos.x + search_radius, cluster_center_pos.y + search_radius}
    }

    local all_units = surface.find_entities_filtered{
        area = area,
        type = "unit-spawner"
    }

    local closest_enemy = nil
    local closest_dist_sq = nil

    for _, unit in pairs(all_units) do
        if unit.force.name ~= force_name then
            local dx = unit.position.x - cluster_center_pos.x
            local dy = unit.position.y - cluster_center_pos.y
            local dist_sq = dx*dx + dy*dy
            if not closest_dist_sq or dist_sq < closest_dist_sq then
                closest_dist_sq = dist_sq
                closest_enemy = unit
            end
        end
    end

    if closest_enemy then
        local dx = closest_enemy.position.x - cluster_center_pos.x
        local dy = closest_enemy.position.y - cluster_center_pos.y
        local base_angle = math.atan2(dy, dx)

        -- Random angle offset, ±20 degrees
        local angle_offset = (math.random() - 0.5) * (math.pi / 9)
        local final_angle = base_angle + angle_offset

        -- Random distance, varies within ±10 around cluster_radius
        local dist_offset = (math.random() * 20) - 15
        local dist = cluster_radius + dist_offset
        if dist < 0 then dist = 0 end -- Prevent negative distance

        return {
            x = cluster_center_pos.x + math.cos(final_angle) * dist,
            y = cluster_center_pos.y + math.sin(final_angle) * dist
        }
    else
        local angle = math.random() * 2 * math.pi
        local dist = cluster_radius + (math.random() * 20 - 10)
        if dist < 0 then dist = 0 end

        return {
            x = cluster_center_pos.x + math.cos(angle) * dist,
            y = cluster_center_pos.y + math.sin(angle) * dist
        }
    end
end

function SpawnerManager.SpawnUnits(Event)
    local surface = game.surfaces.nauvis
    if not surface or not surface.valid then return end

    local total_units_spawned_this_tick = 0

    for player_index, player in pairs(game.players) do
        if player and player.valid then
            local force_name = "friendly-zerg-" .. tostring(player_index)
            local force = game.forces[force_name]
            if not force then
                goto continue_player
            end

            local current_friendly_spawners_on_map = surface.find_entities_filtered{
                type = "unit-spawner",
                force = force_name
            }

            local valid_spawners = {}
            for _, spawner_entity in pairs(current_friendly_spawners_on_map) do
                if spawner_entity.valid then
                    table.insert(valid_spawners, spawner_entity)
                end
            end

            if #valid_spawners == 0 then
                goto continue_player
            end

            local spawner_clusters = cluster_spawners(valid_spawners)

            for _, cluster in pairs(spawner_clusters) do
                local cluster_center_pos = get_cluster_center(cluster)
                local adjusted_radius = calculate_adjusted_radius(#cluster)
                local cluster_force_name = cluster[1].force.name

                local nearby_unit_count_for_cluster = CountUnitsInArea(surface, cluster_center_pos, adjusted_radius, cluster_force_name)
                local desired_units_in_cluster = #cluster * UNITS_PER_SPAWNER_THRESHOLD

                if nearby_unit_count_for_cluster < desired_units_in_cluster then

                    local spawn_pos = GetDirectionalSpawnPos(surface, cluster_center_pos, adjusted_radius, cluster_force_name)
                    local Unit = SpawnRandomEntity(surface, spawn_pos, cluster_force_name, "unit", "biter")
                    if Unit and Unit.valid then
                        total_units_spawned_this_tick = total_units_spawned_this_tick + 1
                    end
                end
            end

            ::continue_player::
        end
    end

    if total_units_spawned_this_tick > 0 then
        -- Log(string.format("Successfully spawned %d units this tick.", total_units_spawned_this_tick))
    end
end


local MAX_SPAWN_ATTEMPTS = 10

local function try_spawn_spawner(surface, cluster_center_pos, cluster_radius, force_name)
    for attempt = 1, MAX_SPAWN_ATTEMPTS do
        local spawn_pos = GetDirectionalSpawnPos(surface, cluster_center_pos, cluster_radius, force_name)
        local spawner = SpawnRandomEntity(surface, spawn_pos, force_name, "unit-spawner", "spawner")
        if spawner then
            return true
        end
    end
    return false
end

spawner_growth_timer = spawner_growth_timer or {}

local TICKS_PER_CALL = 5000  
local seconds_per_call = TICKS_PER_CALL / 60
local BASE_GROWTH_SECONDS = 60  

function SpawnerManager.SpawnBuildings(Event)
    local surface = game.surfaces.nauvis
    if not surface or not surface.valid then return end

    local total_clusters_processed = 0

    for player_index, player in pairs(game.players) do
        if player and player.valid then
            local force_name = "friendly-zerg-" .. tostring(player_index)
            local force = game.forces[force_name]
            if not force then
                goto continue_player
            end

            local valid_spawners = {}
            local current_friendly_spawners_on_map = surface.find_entities_filtered{
                type = "unit-spawner",
                force = force_name
            }

            for _, spawner_entity in pairs(current_friendly_spawners_on_map) do
                if spawner_entity.valid then
                    table.insert(valid_spawners, spawner_entity)
                end
            end

            if #valid_spawners == 0 then
                goto continue_player
            end

            local spawner_clusters = cluster_spawners(valid_spawners)

            for cluster_index, cluster in ipairs(spawner_clusters) do
                local cluster_center_pos = get_cluster_center(cluster)
                local cluster_radius = calculate_adjusted_radius(#cluster)
                local cluster_force_name = cluster[1].force.name
                local spawn_pos = GetDirectionalSpawnPos(surface, cluster_center_pos, cluster_radius, cluster_force_name)

                local turrets_in_cluster = surface.count_entities_filtered{
                    position = cluster_center_pos,
                    radius = cluster_radius,
                    force = cluster_force_name,
                    type = "turret"
                }

                local spawner_count = #cluster
                local max_turrets = math.floor(spawner_count * 1)

                if turrets_in_cluster < max_turrets then
                    SpawnRandomEntity(surface, spawn_pos, cluster_force_name, "turret", "worm-turret")
                end

                local cluster_id = force_name .. "-" .. tostring(cluster_index)

                if not spawner_growth_timer[cluster_id] then
                    spawner_growth_timer[cluster_id] = 0
                end

                spawner_growth_timer[cluster_id] = spawner_growth_timer[cluster_id] + seconds_per_call

                local growth_interval_seconds = spawner_count * BASE_GROWTH_SECONDS

                if spawner_growth_timer[cluster_id] >= growth_interval_seconds then
                    local spawner_created = try_spawn_spawner(surface, cluster_center_pos, cluster_radius, cluster_force_name)
                    if spawner_created then
                        spawner_growth_timer[cluster_id] = 0
                    end
                end
            end

            ::continue_player::
        end
    end
end

return SpawnerManager