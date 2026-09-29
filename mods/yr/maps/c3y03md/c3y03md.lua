-- Coop Mission Script: c3y03md

local player
local objective
local won = false

WorldLoaded = function()
	player = Player.GetPlayer("Multi0")
	objective = player.AddPrimaryObjective("Destroy all enemy forces")

	Trigger.OnPlayerLost(player, function()
		Media.PlaySpeechNotification(player, "MissionFailed")
	end)

	Trigger.OnPlayerWon(player, function()
		Media.PlaySpeechNotification(player, "MissionAccomplished")
	end)

	Trigger.AfterDelay(DateTime.Seconds(30), function()
		local function checkWin()
			if won then
				return
			end

			local enemiesAlive = false
			for _, p in ipairs(Player.GetPlayers()) do
				if p ~= player and not p.NonCombatant and not player.IsAlliedWith(p) then
					if #p.GetActors() > 0 then
						enemiesAlive = true
						break
					end
				end
			end

			if not enemiesAlive then
				won = true
				player.MarkCompletedObjective(objective)
			else
				Trigger.AfterDelay(DateTime.Seconds(10), checkWin)
			end
		end
		checkWin()
	end)
end
