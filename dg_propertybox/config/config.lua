Config = {}

Config.Deposit = {
  coords = vec3(439.85, -978.98, 29.69), -- Police deposit counter
  radius = 1.5
}

Config.Pickup = {
  coords = vec3(437.78, -983.56, 29.69), -- Public pickup counter
  radius = 1.5
}
-- IMPORTANT:DO NOT Change
Config.StashId = 'pd_property_pin'
Config.StashLabel = 'Property Box'
Config.StashSlots = 80
Config.StashMaxWeight = 200000

-- Jobs allowed for despotist item into stashes
Config.PoliceJobs = {
  police = true,
  sheriff = true,
}

Config.RequireNear = true
