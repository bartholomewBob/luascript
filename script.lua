-- *Dont teleport to volcanic rock if lava golems are spawned 
-- -> (game.Workspace._WorldOrigin.EnemySpawns)
-- *Dont teleport to volcanic rock if no skills are available 
-- -> (Listen to all PlaySkillCooldownAnimation BindableEvents, store in table and after alloted time remove from table + prevent script from using any skills in the cooldown table)
-- local args = { [1] = "Z"; [2] = 7.5; }
-- game:GetService("ReplicatedStorage"):WaitForChild("Events", 9e9):WaitForChild("PlaySkillCooldownAnimation", 9e9):Fire(unpack(args)) -- Event
-- *Cycle through skills one by one when attacking rock, and check after each attack if rock stops glowing to save skills

-- Check if golems exist
function has_golem()
    local spawns = game.Workspace._WorldOrigin.EnemySpawns

    local exists = false
    for _, child in spawns:GetChildren() do
        if string.find(child.Name, 'Lava Golem') then
            exists = true
        end
    end
    
    if spawns:FindFirstChild('Lava Golem [Lv. 2500]') then
        exists = true
    end
	
    return exists
end

-- Get player character
function get_character()
	local player = game.Players.LocalPlayer
	local character = player.Character or player.CharacterAdded:Wait()
	return character
end

-- Get rock mesh (Position, CFrame)
function get_mesh(rock)
	return rock:FindFirstChildOfClass('MeshPart')
end

-- Cycle through all weapons, and use all skills
function attack(position) 		
	local weapons = {}
	
	local character
	pcall(function() character = get_character() end)
	if character == nil then
		print('ATTACK: Failed to find Character')
		return
	end

	local humanoid = character:FindFirstChildOfClass('Humanoid')		
	if not humanoid then
		print('ATTACK: Failed to find Humanoid')
		return
	end

	local backpack = game.Players.LocalPlayer:FindFirstChild('Backpack')
	if not backpack then
		print('ATTACK: Failed to find Backpack')
		return
	end

	-- Get all weapons from player's backpack
	local tools = backpack:GetChildren()
	
	print('ATTACK: Fetching weapons from ' .. #tools .. ' children...')
	for _, weapon in tools do
		if weapon:FindFirstChild('EquipEvent') then
			table.insert(weapons, weapon)
		end
	end
	print('ATTACK: Fetched ' .. #weapons .. ' weapon(s)')


	-- Equip each weapon and use abilities
	for index, weapon in weapons do
		print('ATTACK: Equipping weapon ' .. weapon.Name)

		humanoid:EquipTool(weapon)
		wait(0.5)

		print('ATTACK: Using abilities of weapon...')

		for i, ability in { "Z", "X", "C", "V"} do
			print('ATTACK: Using ability "' .. ability .. '"...')

			-- Fire client side
			game:GetService("ReplicatedStorage"):WaitForChild("Events", 9e9):WaitForChild("ActivatedSkill", 9e9):Fire(unpack({ [1] = ability }))


			-- Get all remote functions for weapon skills
			print('ATTACK: Fetching remote functions...')
			local remotes = {}
			for _, child in humanoid:GetChildren() do			
				if child:IsA('RemoteFunction') and #remotes < #weapons then
					table.insert(remotes, child)
				end
			end
			print('ATTACK: Fetched ' .. #remotes .. ' remote function(s)')

			-- Iterate through each remote and invoke
			for i, remote in remotes do
				print('ATTACK: Running remote ' .. i .. '...')
				local status, err = pcall(function() remote:InvokeServer(unpack({ [1] = ability, [2] = position})) end)
				print('ATTACK: Ran remote ' .. i .. ' with result ' .. tostring(status) .. ' (' .. tostring(err) .. ')')
			end				
		end

		wait(0.1)
	end
end

-- Get all rocks only if prehistoric island exists
function get_rocks()
	local rocks = {}

	-- Iterate through all rocks
	for index, rock in game:GetService('Workspace').Map.PrehistoricIsland.Core.VolcanoRocks:GetChildren() do
		-- Check if Glow exists
		local glow
		pcall(function() glow = rock["VFXLayer"]["At0"]["Glow"] end)

		print('ROCK' .. tostring(index) .. ': Found Rock')
		-- Check if Glow is enabled
		if glow then
			print('ROCK' .. tostring(index) .. ': Found Glow')
			if glow.Enabled then					
				print('ROCK' .. tostring(index) .. ': Glow enabled')
				-- Insert into table
				table.insert(rocks, { index = index, rock = rock })
			end
		end
	end

	return rocks
end

-- Tween to part 
function tween_to(part, beat) 
	local character
	pcall(function() character = get_character() end)
	if character == nil then
		if beat then
			print('TWEEN: Failed to find character')	
		end		
		return	
	end		
	
	local dist = (part.Position - character.HumanoidRootPart.Position).Magnitude
	local speed = 0

	if dist < 150 then
		speed = 20000
	elseif dist < 200 then
		speed = 5000
	elseif dist < 300 then
		speed = 1030
	elseif dist < 500 then
		speed = 725
	elseif dist < 1000 then
		speed = 365
	elseif dist >= 1000 then
		speed = 365
	end

	game:GetService("TweenService"):Create(
		character.HumanoidRootPart,
		TweenInfo.new(dist/speed, Enum.EasingStyle.Linear),
		{CFrame = part.CFrame}
	):Play()

	wait(dist/speed)
end

function is_glowing(active_index, rocks)
	local glowing = false

	for _, data in rocks do
		if data.index == active_index then
			glowing = true
		end 
	end

	return glowing
end

function get_singular_rock(rock_index, rocks)
	local rock

	for _, data in rocks do
		if data.index == rock_index then
			rock = data.rock
		end
	end

	return rock
end

function is_beat(time) 
	return math.fmod(time, 1) <= 0.015
end

-- Main loops
local active_rock = -1

local run_iterations = 0
game:GetService("RunService").Stepped:Connect(function(time)
	-- Get active rock if exists and tween to each frame
	if game:GetService('Workspace').Map:FindFirstChild('PrehistoricIsland') then
		local rocks = get_rocks()
		if is_beat(time) then print('RUN-ITERATION' .. tostring(run_iterations) .. ': Found Prehistoric Island with ' .. tostring(#rocks) .. ' rock(s)') end		

		if active_rock ~= -1 then
			local singular_rock = get_singular_rock(active_rock, rocks)
			local mesh = get_mesh(singular_rock)

			
			if has_golem() then				
				if is_beat(time) then print('RUN-ITERATION' .. tostring(run_iterations) .. ': Lava golem cancelled tweening to active rock ' .. tostring(active_rock) .. '...') end 	
			else
				if mesh then
					if is_beat(time) then print('RUN-ITERATION' .. tostring(run_iterations) .. ': Tweening to active rock ' .. tostring(active_rock) .. '...') end 	
				else
					if is_beat(time) then print('RUN-ITERATION' .. tostring(run_iterations) .. ': Failed to find active rock ' .. tostring(active_rock) .. ' mesh') end
				end

				tween_to(mesh, is_beat(time))				
			end
	
		end
	else
		if is_beat(time) then print('RUN-ITERATION' .. tostring(run_iterations) .. ': Failed to find Prehistoric Island') end
	end

	if is_beat(time) then run_iterations += 1 end
end)


-- Main loop
local while_iterations = 0
while true do
	-- Check if Prehistoric Island exists
	if game:GetService('Workspace').Map:FindFirstChild('PrehistoricIsland') then
		-- Get table of glowing rocks
		local rocks = get_rocks()	

		print('WHILE-ITERATION' .. tostring(while_iterations) .. ': Found ' .. tostring(#rocks) .. ' glowing rock(s)...')

		-- Check if a glowing rock is actively being attacked
		if active_rock ~= -1 then
			-- Check if rock is still glowing
			if is_glowing(active_rock, rocks) then				
				local singular_rock = get_singular_rock(active_rock, rocks)
				local mesh = get_mesh(singular_rock)

				if has_golem() then
					print('WHILE-ITERATION' .. tostring(while_iterations) .. ': Lava golem cancelled attacking active rock ' .. tostring(active_rock) .. '...')
				else
					print('WHILE-ITERATION' .. tostring(while_iterations) .. ': Attacking active rock ' .. tostring(active_rock) .. '...')
					attack(mesh.Position)				
				end
				
			else
				-- Otherwise, check if another rock exists
				if #rocks ~= 0 then
					-- Then, move on to next rock
					active_rock = rocks[1].index					
					print('WHILE-ITERATION' .. tostring(while_iterations) .. ': Moving on to rock ' .. tostring(active_rock) .. '...')
				else 
					-- Otherwise, set active rock to none
					active_rock = -1
					print('WHILE-ITERATION' .. tostring(while_iterations) .. ': Reset rocks...')
				end
			end
		else
			if #rocks ~= 0 then
				active_rock = rocks[1].index
				print('WHILE-ITERATION' .. tostring(while_iterations) .. ': Starting with rock ' .. tostring(active_rock) .. '...')
			end
		end
	else
		print('WHILE-ITERATION' .. tostring(while_iterations) .. ': Failed to find Prehistoric Island...')
		active_rock = -1
	end

	while_iterations += 1
	wait(1)
end


