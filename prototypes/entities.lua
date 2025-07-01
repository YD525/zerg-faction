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