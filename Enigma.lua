local Enigma = {}

Enigma.optionEnable = Menu.AddOptionBool({"Hero Specific","Enigma"}, "Enabled", false)
Enigma.blinkOnly = Menu.AddOptionBool({"Hero Specific","Enigma"},"Blink only",false)
Enigma.bkb = Menu.AddOptionBool({"Hero Specific","Enigma"},"BKB",false)
Enigma.shiva = Menu.AddOptionBool({"Hero Specific","Enigma"},"Shiva",false)
Enigma.refresher = Menu.AddOptionBool({"Hero Specific","Enigma"},"Refresher",false)
Menu.AddMenuIcon({"Hero Specific", "Enigma"}, "panorama/images/heroes/icons/npc_dota_hero_enigma_png.vtex_c")
Enigma.optionKey = Menu.AddKeyOption({"Hero Specific","Enigma"}, "Auto Procast", Enum.ButtonCode.KEY_C)
Enigma.enemyCount = Menu.AddOptionSlider({"Hero Specific","Enigma"}, "Enemy count", 1, 5, 1)

Enigma.Hero = nil
Enigma.GameDelay = 0

function Enigma.OnUpdate()
	if Enigma.Hero == nil then Enigma.Hero = Heroes.GetLocal() end
	if NPC.GetUnitName(Enigma.Hero) ~= 'npc_dota_hero_enigma' then return true end
    if not Menu.IsEnabled(Enigma.optionEnable) then return true end
	if Menu.IsKeyDown(Enigma.optionKey) then Enigma.Combo() end
end	

function Enigma.Combo()
	
	local blink = NPC.GetItem(Enigma.Hero, "item_blink")
	local shiva = NPC.GetItem(Enigma.Hero, "item_shivas_guard")
	local bkb = NPC.GetItem(Enigma.Hero, "item_black_king_bar")
	local rfr = NPC.GetItem(Enigma.Hero, "item_refresher")	--refresher
	
	local pulse = NPC.GetAbility(Enigma.Hero, "enigma_midnight_pulse")
	local blackHole = NPC.GetAbility(Enigma.Hero, "enigma_black_hole")
	local heroMana = NPC.GetMana(Enigma.Hero)
	
	local blink_radius = 1200
	local black_hole_radius = 420	
	local enemyHeroes = Entity.GetHeroesInRadius(Enigma.Hero, blink_radius + black_hole_radius, Enum.TeamType.TEAM_ENEMY)
	
	if #enemyHeroes < Menu.GetValue(Enigma.enemyCount) then return end
	if not Ability.IsReady(blackHole) or not Ability.IsCastable(blackHole, heroMana) then 		
		if not rfr or not Ability.IsReady(rfr) or not Ability.IsCastable(rfr, heroMana - Ability.GetManaCost(blackHole)) then return end
	end	
	if Menu.IsEnabled(Enigma.Refresher) and not Ability.IsReady(blackHole) and os.clock() > Enigma.GameDelay + 0.1 then Ability.CastNoTarget(rfr) Enigma.GameDelay = os.clock() end
	
	local bestPos = Enigma.BestPosition(enemyHeroes, black_hole_radius)
	local distance = math.floor(math.abs((Entity.GetAbsOrigin(Enigma.Hero) - bestPos) : Length2D())) - black_hole_radius * 0.5 - 61 --костыль
	Log.Write(distance)
	if blink and Ability.IsReady(blink) and os.clock() > Enigma.GameDelay + 0.1 then Ability.CastPosition(blink, bestPos) Enigma.GameDelay = os.clock() end
	if distance < 10 then
	if os.clock() > Enigma.GameDelay + 0.1 and pulse and Ability.IsReady(pulse) and Ability.IsCastable(pulse, heroMana - Ability.GetManaCost(blackHole)) 
			then Ability.CastPosition(pulse, bestPos) Enigma.GameDelay = os.clock() end
		if Menu.IsEnabled(Enigma.BKB) and bkb and Ability.IsReady(bkb) and os.clock() > Enigma.GameDelay + 0.1 then Ability.CastNoTarget(bkb) Enigma.GameDelay = os.clock() end
		if Menu.IsEnabled(Enigma.Shiva) and shiva and Ability.IsReady(shiva) and Ability.IsCastable(shiva, heroMana - Ability.GetManaCost(blackHole)) then Ability.CastNoTarget(shiva) end 
	end
	if os.clock() > Enigma.GameDelay + 0.1 then Ability.CastPosition(blackHole, bestPos) Enigma.GameDelay = os.clock() end
	
end

function Enigma.BestPosition(unitsAround, radius)
    if not unitsAround or #unitsAround <= 0 then return nil end
    local enemyNum = #unitsAround

	if enemyNum == 1 then return Entity.GetAbsOrigin(unitsAround[1]) end
	local maxNum = 1
	local bestPos = Entity.GetAbsOrigin(unitsAround[1])
	for i = 1, enemyNum-1 do
		for j = i+1, enemyNum do
			if unitsAround[i] and unitsAround[j] then
				local pos1 = Entity.GetAbsOrigin(unitsAround[i])
				local pos2 = Entity.GetAbsOrigin(unitsAround[j])
				local mid = pos1:__add(pos2):Scaled(0.5)

				local heroesNum = 0
				for k = 1, enemyNum do
					if NPC.IsPositionInRange(unitsAround[k], mid, radius, 0) then
						heroesNum = heroesNum + 1
					end
				end

				if heroesNum > maxNum then
					maxNum = heroesNum
					bestPos = mid
				end
			end
		end
	end

	return bestPos
end

return Enigma