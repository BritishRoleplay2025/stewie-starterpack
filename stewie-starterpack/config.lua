Config = {}
Config.TargetSystem = "ox_target" -- Choose target system: "qb-target" or "ox_target"
-- NPC model and coordinates
Config.NPC = {
    model = "a_m_y_stlat_01",  -- NPC model
    coords = vector4(-1035.02, -2733.19, 20.17, 151.16)  -- NPC coordinates
}
Config.vehicleCoords = vector4(-1038.02, -2733.19, 20.17, 151.16)
-- Starter pack items
Config.StarterPackItems = {
    { item = "driver_license", amount = 1 },
    { item = "sandwich", amount = 3 },
    { item = "water_bottle", amount = 1 },
    { item = "cash", amount = 500 },
    { item = "phone", amount = 1 }
}
-- Vehicle List with model names and prices
Config.Vehicles = {
    { label = "Sports Car", model = "adder", price = 500 },         -- Rent price 500
    { label = "Muscle Car", model = "dominator", price = 300 },     -- Rent price 300
    { label = "Luxury Car", model = "zentorno", price = 700 },      -- Rent price 700
    { label = "SUV", model = "cheetah", price = 400 }               -- Rent price 400
}
Config.RandomVehicles = { -- list of vehicles to be given randomly to the player
    "adder",
    "zentorno",
    "t20",
    "osiris",
    "reaper",
    "tempesta",
    "italigtb",
    "italigtb2",
    "nero",
    -- add more vehicles here
}