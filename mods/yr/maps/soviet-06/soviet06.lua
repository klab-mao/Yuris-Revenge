
--[[Soviet Mission 06: Flying to Moon Script]]

SovietInitForce1 = { "htnk" } --[[Rhino Tank x 1, Soviet MCV x 1, Cosmonaut x 5]]
SovietInitForce2 = { "smcv" } 
SovietInitForce3 = { "lunr", "lunr", "lunr", "lunr", "lunr" } 

YuriInitForce1 = { "tele" } --[[Magnetron x 1, Master Mind x 1]]
YuriInitForce2 = { "mind" }
YuriProductionTypeInfantry = { "lunr" } --[[ 70% percent chance ]]
YuriProductionTypeVehicle = { "ytnk", "ltnk" } --[[ 30% percent chance ]]

YuriIncome = 0
YuriProductionInitDelay = 0

if Map.LobbyOption("difficulty") == "easy" then
	YuriIncome = 10
	YuriProductionDelay = DateTime.Seconds(15)
	
elseif Map.LobbyOption("difficulty") == "normal" then
	YuriIncome = 50
	YuriProductionDelay = DateTime.Seconds(10)

elseif Map.LobbyOption("difficulty") == "hard" then
	YuriIncome = 100
	YuriProductionDelay = DateTime.Seconds(5)

else
	YuriIncome = 5
	YuriProductionDelay = DateTime.Seconds(20)
end

LaunchSovietForce = function()
	--[[TODO: Add a movement path for these actors]]
	Utils.Do(SovietInitForce1, function(unitType)
		Actor.Create(unitType, true, { Location = SovietSpawnPoint1.Location, Facing = Facing.NorthEast, Owner = player })
	end)

	Utils.Do(SovietInitForce2, function(unitType)
		Actor.Create(unitType, true, { Location = SovietSpawnPoint2.Location, Facing = Facing.NorthEast, Owner = player })
	end)

	Utils.Do(SovietInitForce3, function(unitType)
		Actor.Create(unitType, true, { Location = SovietSpawnPoint3.Location, Facing = Facing.NorthEast, Owner = player })
	end)
end

MoveCameraTo = function(position)
	Camera.Position = position
end

MissionAccomplished = function()
	Media.PlaySoundNotification(player, "Cheer")
	Media.PlaySoundNotification(player, "Cheer")
	Media.PlaySoundNotification(player, "Cheer")
	Media.PlaySoundNotification(player, "Cheer")
	Media.PlaySpeechNotification(player, "MissionAccomplished")
end

MissionFailed = function()
	Media.PlaySpeechNotification(player, "MissionFailed")
end

-- Tolerate trailing-colon descriptions left over in older saves
NormalizeDesc = function(desc)
	return desc:gsub("%s*:$", "")
end

FindObjective = function(description)
	local target = NormalizeDesc(description)
	for i = 0, 7 do
		local ok, desc = pcall(function() return player.GetObjectiveDescription(i) end)
		if ok and desc ~= nil and NormalizeDesc(desc) == target then
			return i
		end
	end
	return nil
end

PlayerHasBase = function()
	return Utils.Any(player.GetActors(), function(actor) return actor.Type == "nacnst" end)
end

CheckBaseHasBuilt = function()
	if isFinishObjective1 then
		return
	end

	actors = player.GetActors()
	isFinishObjective1 = Utils.Any(actors, function(actor) return actor.Type == "nacnst" end)
	if isFinishObjective1 and destroyYuriForces == nil then
		destroyYuriMoonCommandCenter = player.AddPrimaryObjective("Find and destroy Yuri's Moon command center")
		destroyYuriForces = player.AddPrimaryObjective("Destroy Yuri forces")
		player.Cash = 80000
		yuri.Cash = 1000000
		player.MarkCompletedObjective(buildBaseObjective)
	end
end

CheckYuriCommandCenter = function()
	if not isFinishObjective1 or destroyYuriMoonCommandCenter == nil then
		return
	end

	local neutralized = false
	pcall(function()
		neutralized = YuriCommandCenter.IsDead or YuriCommandCenter.Owner.Name ~= "Yuri"
	end)

	if neutralized then
		StopYuriProduction()
		player.MarkCompletedObjective(destroyYuriMoonCommandCenter)
	end
end

YuriBuildingTypes = {
	"yacnst", "yacomd", "yapowr", "yapsyt", "yabrck",
	"yaweap", "yatech", "yagrnd", "naclon", "napsis"
}

IsYuriBuilding = function(actor)
	return Utils.Any(YuriBuildingTypes, function(t) return actor.Type == t end)
end

CheckYuriHasDestroyed = function()
	if not isFinishObjective1 or destroyYuriForces == nil then
		return
	end

	-- GetActors() only returns living actors. The objective counts as done
	-- once every Yuri structure is destroyed or captured: hunting down every
	-- stray cosmonaut on this long map is not required.
	local actors = yuri.GetActors()
	local buildingsLeft = Utils.Where(actors, IsYuriBuilding)
	if #buildingsLeft == 0 then
		player.MarkCompletedObjective(destroyYuriForces)
	end
end

YuriIncomeTick = function()
	if YuriProductionStopped then
		return
	end

	yuri.Cash = yuri.Cash + YuriIncome
end

YuriProductionStopped = false

StopYuriProduction = function()
	YuriProductionStopped = true
end

YuriProductionTick = function()
	if YuriProductionStopped or YuriProductionScheduled then
		return
	end

	YuriProductionScheduled = true
	Trigger.AfterDelay(YuriProductionDelay, function()
		YuriProductionScheduled = false
		if YuriProductionStopped then
			return
		end

		-- 70% infantry, 30% vehicles
		if Utils.RandomInteger(0, 100) < 70 then
			YuriInfantryProduction()
		else
			YuriVehicleProduction()
		end
	end)
end

YuriInfantryProduction = function()
	local toBuild = { Utils.Random(YuriProductionTypeInfantry) }
	
	yuri.Build(toBuild, function(unit)
			local randomActor = GetPlayerRandomActor()
			if randomActor and unit.Attack then
				pcall(function() unit.Attack(randomActor) end)
			end
	end)
end

YuriVehicleProduction = function()
	local toBuild = { Utils.Random(YuriProductionTypeVehicle) }
	
	yuri.Build(toBuild, function(unit)
			local randomActor = GetPlayerRandomActor()
			if randomActor and unit.Attack then
				pcall(function() unit.Attack(randomActor) end)
			end
	end)
end

GetPlayerRandomActor = function()
	local actors = player.GetActors()
	local randomActor = Utils.Random(actors)
	return randomActor
end

Tick = function()
	if not isFinishObjective1 then
		CheckBaseHasBuilt()
	end
	CheckYuriCommandCenter()
	CheckYuriHasDestroyed()
	
	YuriProductionTick()
	YuriIncomeTick()
end

WorldLoaded = function()
	player = Player.GetPlayer("Soviet")
	yuri = Player.GetPlayer("Yuri")

	Trigger.OnObjectiveAdded(player, function(p, id)
		Media.PlaySpeechNotification(player, "NewMissionObjectiveReceived")
		Media.DisplayMessage(p.GetObjectiveDescription(id), "New " .. string.lower(p.GetObjectiveType(id)) .. " objective", player.Color)
	end)
	Trigger.OnObjectiveCompleted(player, function(p, id)
		Media.PlaySpeechNotification(player, "PrimaryObjectiveAchieved")
		Media.DisplayMessage(p.GetObjectiveDescription(id), "Objective completed", player.Color)
	end)
	Trigger.OnObjectiveFailed(player, function(p, id)
		Media.DisplayMessage(p.GetObjectiveDescription(id), "Objective failed", player.Color)
	end)

	Trigger.OnPlayerLost(player, MissionFailed)
	Trigger.OnPlayerWon(player, MissionAccomplished)

	buildBaseObjective = FindObjective("Find a suitable place and build base")

	-- A restored save already carries the objectives and the landed force:
	-- reuse them instead of adding duplicates or spawning a second force.
	local isSaveLoad = buildBaseObjective ~= nil

	if buildBaseObjective == nil then
		buildBaseObjective = player.AddPrimaryObjective("Find a suitable place and build base")
	end

	destroyYuriMoonCommandCenter = FindObjective("Find and destroy Yuri's Moon command center")
	destroyYuriForces = FindObjective("Destroy Yuri forces")

	isFinishObjective1 = destroyYuriForces ~= nil or PlayerHasBase()

	if isSaveLoad then
		-- Resume production state from the world we restored
		local neutralized = false
		pcall(function()
			neutralized = YuriCommandCenter.IsDead or YuriCommandCenter.Owner.Name ~= "Yuri"
		end)
		if neutralized then
			YuriProductionStopped = true
		end

		-- Some older saves lost their Objectives node entirely: rebuild the
		-- missing objectives from the actual world state instead of leaving
		-- the mission unwinnable. Rewards are NOT granted again.
		if isFinishObjective1 and destroyYuriForces == nil then
			destroyYuriMoonCommandCenter = player.AddPrimaryObjective("Find and destroy Yuri's Moon command center")
			destroyYuriForces = player.AddPrimaryObjective("Destroy Yuri forces")
			player.MarkCompletedObjective(buildBaseObjective)
			if neutralized then
				player.MarkCompletedObjective(destroyYuriMoonCommandCenter)
			end
		end

		return
	end

	--[[TODO: Add Init Yuri uints to play a show with us like the original]]
	--[[      And add flash effect]]

	MoveCameraTo(CommandCenterPoint.CenterPosition)

	Trigger.AfterDelay(DateTime.Minutes(8), function()
		MoveCameraTo(SovietSpawnPoint2.CenterPosition)
	end)


	LaunchSovietForce()
end
