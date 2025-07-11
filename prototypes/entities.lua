local item_sounds = require("__base__.prototypes.item_sounds")

local ent = table.deepcopy(data.raw["lamp"]["small-lamp"])
ent.name = "biter-spawner-placeholder"
ent.icons = {
  {
    icon = "__base__/graphics/icons/biter-spawner.png",
    icon_size = 64
  },
  {
    icon = "__base__/graphics/icons/biter-spawner.png",
    icon_size = 64,
    tint = {r=0, g=0.3, b=1, a=0.6},
    scale = 1.1
  }
}
ent.minable = {mining_time = 0.5, result = "biter-spawner-placeholder"}
ent.flags = {"placeable-player", "player-creation", "not-on-map"}
ent.collision_box = {{-2.5,-2.5},{2.5,2.5}}
ent.selection_box = {{-2.5,-2.5},{2.5,2.5}}
ent.max_health = 200

local itm = table.deepcopy(data.raw["item"]["small-lamp"])
itm.name = "biter-spawner-placeholder"
itm.place_result = ent.name
itm.icons = ent.icons
itm.stack_size = 10

local recipe_placeholder = {
  type = "recipe",
  name = "biter-spawner-placeholder",
  enabled = true,
  ingredients = {
    {type = "item", name = "biter-egg", amount = 15}
  },
  results = {
    {type="item", name=ent.name, amount=1}
  }
}

data:extend{ent, itm, recipe_placeholder}

local capsule_ent = table.deepcopy(data.raw["lamp"]["small-lamp"])
capsule_ent.name = "spawner-remove-capsule-entity"
capsule_ent.icons = {
  {
    icon = "__base__/graphics/icons/biter-spawner.png",
    icon_size = 64
  },
  {
    icon = "__base__/graphics/icons/biter-spawner.png",
    icon_size = 64,
    tint = {r=0, g=0.3, b=1, a=0.6},
    scale = 1.1
  }
}
capsule_ent.minable = {mining_time = 0.5, result = "spawner-remove-capsule"}
capsule_ent.flags = {"placeable-player", "player-creation", "not-on-map"}
capsule_ent.collision_box = {{-0.0, -0.0}, {0.0, 0.0}} 
capsule_ent.selection_box = {{-0.0, -0.0}, {0.0, 0.0}} 
capsule_ent.max_health = 200

local capsule_itm = table.deepcopy(data.raw["item"]["small-lamp"])
capsule_itm.name = "spawner-remove-capsule"
capsule_itm.place_result = capsule_ent.name
capsule_itm.icons = capsule_ent.icons
capsule_itm.stack_size = 10

local capsule_recipe = {
  type = "recipe",
  name = "spawner-remove-capsule",
  enabled = true,
  ingredients = { 
     {type = "item", name = "iron-plate", amount = 10}
     },
  results = {
    {type="item", name=capsule_itm.name, amount=1}
  }
}

data:extend{capsule_ent, capsule_itm, capsule_recipe}


data:extend({
  {
    type = "selection-tool",
    name = "zfswarm-assembly-point",
    icon = "__zerg-faction__/graphics/icons/swarm-target.png",
    icon_size = 50,
    flags = {"not-stackable", "only-in-cursor", "spawnable"},
    subgroup = "spawnables",
    order = "c[automated-construction]-e[zfswarm-assembly-point]",
    stack_size = 1,
    select = {
            border_color = {r = 0.3, g = 0.9, b = 0.3},
            mode = {"any-entity"},
            cursor_box_type = "copy",
   },
  alt_select = {
            border_color = {r = 0.9, g = 0.9, b = 0.3},
            mode = {"any-entity"},
            cursor_box_type = "entity",
  },
  pick_sound = item_sounds.combinator_inventory_pickup,
  drop_sound = item_sounds.combinator_inventory_move,
  inventory_move_sound = item_sounds.combinator_inventory_move,
  }
})

data:extend({
  {
    type = "shortcut",
    name = "zfswarm-assembly-point",
    localised_name = { "item-name.zfswarm-assembly-point"},
    order = "a",
    action = "spawn-item",
    item_to_spawn = "zfswarm-assembly-point",
    icon = "__zerg-faction__/graphics/icons/swarm-target.png",
    icon_size = 50,
    small_icon = "__zerg-faction__/graphics/icons/swarm-target.png",
    small_icon_size = 50,
  }
})
