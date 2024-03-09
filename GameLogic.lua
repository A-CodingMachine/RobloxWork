--Services
local RStorage = game:GetService("ReplicatedStorage")
local SPlayer = game:GetService("Players")
local SLighting = game:GetService("Lighting")

--RStorage Vars
local Game_Loop = RStorage.Game_Remotes.Game_Loop_Events
local Role_Related = Game_Loop.Role_Related
--Modules
local Role_Des = require(RStorage.Mods.Role_Des)
--Time_Vars
local DayTimeLength = 5
local NightTimeLength = 5
local DiscussionTimeLength = 10
local Vote_Time_Length = 15
local Just_Started_Wait = 10
local Ability_Use_Length = 10
local Hotel_Room_Time = 10
local Mafia_Killing_Time = 10

--Game_Vars
local Disscussing = false
local Looping = true
local Just_Started = false

function ChangeHumanoid(JumpHeight, Speed, Char)

	local Hum = Char:FindFirstChild("Humanoid")

	Hum.WalkSpeed = Speed
	Hum.JumpHeight = JumpHeight
end
function ChoosingTable()

	print("Choosing_Table")
	if not Looping then return end

	--local ChairsTaken = {}
	--local Chairs = workspace["Forest_Map"].Log_Chairs:GetChildren()

	--for i,v in pairs(SPlayer:GetPlayers()) do

	--	local Char = v.Character or v.CharacterAdded:Wait()

	--	for i,v in pairs(Chairs) do
	--		if not ChairsTaken[v.Name]  then
	--			ChairsTaken[v.Name] = v
	--			Char:PivotTo(v.PrimaryPart.CFrame)	
	--		else
	--			warn("Chair is taken")
	--		end					
	--	end
	--	ChangeHumanoid(0,0,Char)

	--end	
end

function UnSit()
	for i,Plr in pairs(SPlayer:GetPlayers()) do
		local Char = Plr.Character or Plr.CharacterAdded:Wait()
		local Hum = Char:FindFirstChildOfClass("Humanoid")
		Hum.Sit = false
	end
end

function Mafia_Kill()
	--Allow mafia to kill
	Game_Loop.Chat_Disable:FireAllClients(false)
	
	for i,v in pairs(SPlayer:GetPlayers()) do
		
		local Char = v.Character or v.CharacterAdded:Wait()
		
		if table.find(Role_Des.Mafia, Char:GetAttribute("Role")) then
			print(v.Name)
			Game_Loop.Voting_Started:FireClient(v, "Killing")
		end
	end
	
	for i = Mafia_Killing_Time, 0 , -1 do
		Game_Loop.Update_Timer:FireAllClients(i)
		task.wait(1)
		if i == 0 then
			task.wait(0.5)
			Game_Loop.Voting_Ended:Fire()
		end
	end
	
	task.wait(Mafia_Killing_Time)
end

function Voting()

	if not Looping then return end
	--Discussion
	_G.Current_Vote = "All"
	Game_Loop.Chat_Disable:FireAllClients(true)
	task.wait(DiscussionTimeLength)
	Game_Loop.Voting_Started:FireAllClients()

	for Time = Vote_Time_Length, 0 , -1 do
		task.wait(1)
		Game_Loop.Update_Timer:FireAllClients(Time)
		if Time == 0 then
			task.wait(0.5)
			Game_Loop.Voting_Ended:Fire()
		end
	end
	
end

function Cooridor()

	print("DayTime")

	if not Looping then return end

	if Just_Started then
		task.wait(Just_Started_Wait)
		Role_Related.Server_Role:Fire()
		task.wait(23)
		Just_Started = false
		return
	end

	UnSit()

	SLighting.ClockTime = 10
	task.wait(DayTimeLength)

end

function Black_Room()

	print("Black_Room")

	if not Looping then return end

	UnSit()
	
	SLighting.ClockTime = 24
	task.wait(NightTimeLength)
end

function Hotel_Room()
	task.wait(Hotel_Room_Time)
end

function Use_Abilities()
	print("Use_abilities")
	
	Game_Loop.Round_Restart:Fire()
	
	RStorage.Game_Remotes.Game_Loop_Events.Use_Ability:FireAllClients()

	for i = Ability_Use_Length, 0, -1 do
		task.wait(1)
		RStorage.Game_Remotes.Game_Loop_Events.Update_Timer:FireAllClients(i)
	end	
end

Start_Loop = coroutine.wrap(function()
	while game.Workspace:GetAttribute("Started") and Looping do
		Cooridor()
		Black_Room()
		
		Mafia_Kill()
		Use_Abilities()
		Voting()

		Black_Room()
		Cooridor()
		Hotel_Room()
		
		Mafia_Kill()
		Use_Abilities()	
		Voting()
		
		Black_Room()
	end
end)


game.Workspace:GetAttributeChangedSignal("Started"):Connect(function()

	local Started = game.Workspace:GetAttribute("Started")

	if Started and not Looping  then
		Looping = true
		Start_Loop()
		--Start loop
	else
		Looping = false
		return
	end

end)

game.Workspace:SetAttribute("Started", true)