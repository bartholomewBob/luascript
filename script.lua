-- Make tween infinite in runservice and set to active rock index
-- Add noclip to prevent damage

print('ITERATION0: Started script')
local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local backpack = player:WaitForChild('Backpack')
local humanoid = character:FindFirstChildOfClass('Humanoid')

function get_mesh(rock)
	return rock:FindFirstChildOfClass('MeshPart')
end

-- Cycle through all weapons, and use all skills
function attack(position) 	
	local weapons = {}

	-- Get all weapons from player's backpack
	print('ROCK: Fetching weapons...')
	for _, weapon in backpack:GetChildren() do
		if weapon:FindFirstChild('EquipEvent') then
			table.insert(weapons, weapon)
		end
	end
	print('ROCK: Fetched ' .. #weapons .. ' weapon(s)')


	-- Equip each weapon and use abilities
	for index, weapon in weapons do
		print('ROCK: Equipping weapon ' .. weapon.Name)

		humanoid:EquipTool(weapon)
		wait(0.5)

		print('ROCK: Using abilities of weapon...')

		for i, ability in { "Z", "X", "C", "V"} do
			print('ROCK: Using ability "' .. ability .. '"...')

			-- Fire client side
			game:GetService("ReplicatedStorage"):WaitForChild("Events", 9e9):WaitForChild("ActivatedSkill", 9e9):Fire(unpack({ [1] = ability }))


			-- Get all remote functions for weapon skills
			print('ROCK: Fetching remote functions...')
			local remotes = {}
			for _, child in humanoid:GetChildren() do			
				if child:IsA('RemoteFunction') and #remotes < #weapons then
					table.insert(remotes, child)
				end
			end
			print('ROCK: Fetched ' .. #remotes .. ' remote function(s)')

			-- Iterate through each remote and invoke
			for i, remote in remotes do
				print('ROCK: Running remote ' .. i .. '...')
				local status, err = pcall(function() remote:InvokeServer(unpack({ [1] = ability, [2] = position})) end)
				print('ROCK: Ran remote ' .. i .. ' with result ' .. tostring(status) .. ' (' .. tostring(err) .. ')')
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
function tween_to(part) 
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

-- Main loop
local iterations = 0
local active_rock = -1

while true do
	-- Check if Prehistoric Island exists
	if game:GetService('Workspace').Map:FindFirstChild('PrehistoricIsland') then
		-- Get table of glowing rocks
		local rocks = get_rocks()	
	
		print('ITERATION' .. tostring(iterations) .. ': Found ' .. tostring(#rocks) .. ' glowing rock(s)...')

		-- Check if a glowing rock is actively being attacked
		if active_rock ~= -1 then
			-- Check if rock is still glowing
			if is_glowing(active_rock, rocks) then
				print('ITERATION' .. tostring(iterations) .. ': Attacking active rock ' .. tostring(active_rock) .. '...')

				local singular_rock = get_singular_rock(active_rock, rocks)
				local mesh = get_mesh(singular_rock)

				attack(mesh.Position)				
			else
				-- Otherwise, check if another rock exists
				if #rocks ~= 0 then
					-- Then, move on to next rock
					active_rock = rocks[1].index					
					print('ITERATION' .. tostring(iterations) .. ': Moving on to rock ' .. tostring(active_rock) .. '...')
				else 
					-- Otherwise, set active rock to none
					active_rock = -1
					print('ITERATION' .. tostring(iterations) .. ': Reset rocks...')
				end
			end
		else
			if #rocks ~= 0 then
				active_rock = rocks[1].index
				print('ITERATION' .. tostring(iterations) .. ': Starting with rock ' .. tostring(active_rock) .. '...')
			end
		end
	else
		print('ITERATION' .. tostring(iterations) .. ': Failed to find Prehistoric Island...')
		active_rock = -1
	end

	iterations += 1
	wait(1)
end

game:GetService("RunService").Heartbeat:Connect(function()
	-- Get active rock if exists and tween to each frame
	if game:GetService('Workspace').Map:FindFirstChild('PrehistoricIsland') then		
		local rocks = get_rocks()

		if active_rock ~= -1 then
			local singular_rock = get_singular_rock(active_rock, rocks)
			local mesh = get_mesh(singular_rock)

			tween_to(mesh)
		end
	end
end)
