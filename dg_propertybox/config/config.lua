Config = {}

-- Two separate places (CHANGE THESE COORDS)
Config.Deposit = {
  coords = vec3(439.85, -978.98, 29.69), -- Police deposit counter
  radius = 1.5
}

Config.Pickup = {
  coords = vec3(437.78, -983.56, 29.69), -- Public pickup counter
  radius = 1.5
}

-- Stash settings
-- IMPORTANT: This stash is shared, but we use "owner = PIN" to create one stash per PIN
Config.StashId = 'pd_property_pin'
Config.StashLabel = 'Property Box'
Config.StashSlots = 80
Config.StashMaxWeight = 200000

-- Jobs allowed to create/open deposit stashes
Config.PoliceJobs = {
  police = true,
  sheriff = true,
}

Config.RequireNear = true
