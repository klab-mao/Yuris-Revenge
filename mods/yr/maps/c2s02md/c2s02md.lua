-- Coop Mission Script: c2s02md

local player
local objective

WorldLoaded = function()
	player = Player.GetPlayer("Multi0")
	objective = player.AddPrimaryObjective("Destroy all enemy forces")

	Trigger.OnPlayerLost(player, function()
		Media.PlaySpeechNotification(player, "MissionFailed")
	end)

	Trigger.OnPlayerWon(player, function()
		Media.PlaySpeechNotification(player, "MissionAccomplished")
	end)

	-- Check for victory: all enemy actors dead
	-- Only start checking after 30 seconds to allow enemies to build
	Trigger.AfterDelay(DateTime.Seconds(30), function()
		local function checkWin()
			if player.WinState ~= WinState.Undefined then
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
				player.MarkCompletedObjective(objective)
			else
				Trigger.AfterDelay(DateTime.Seconds(10), checkWin)
			end
		end
		checkWin()
	end)
end
