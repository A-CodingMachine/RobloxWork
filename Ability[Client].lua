--Services
local SPlayer = game:GetService("Players")
local RStorage = game:GetService("ReplicatedStorage")
local STween = game:GetService("TweenService")

--Player_Vars
local LPlayer = SPlayer.LocalPlayer
local Char = LPlayer.Character or LPlayer.CharacterAdded:Wait()

--Gui_Vars
local PlayerChoose = script.Parent:WaitForChild("PlayerChoose")
local Template_Button = script.TemplateButton
local Background = PlayerChoose:WaitForChild("Background")
local ScrollingFrame = Background.Extra_Background.ScrollingFrame

--Remote_Events Vars
local Player_Events = RStorage.Game_Remotes.Player_Events
local Role_Events = RStorage.Game_Remotes.Role_Events

--Modules
local Role_Des = require(RStorage.Mods.Role_Des)
--Other_Vars
local Once = false
local Vote_Type = ""
local Picked_Player1 = ""
local Picked_Player2 = ""
local Time_Ended = false
local Button_Table ={}

function Update_Viewport(CharDup, Button) --Update the viewport current camera

	local Viewport: ViewportFrame = Button.TemplateBackground.ViewportFrame

	local CameraNew = Instance.new("Camera")
	CameraNew.CFrame = CFrame.new(CharDup:FindFirstChild("Head").Position + Vector3.new(0,0,3), CharDup:FindFirstChild("Head").Position)

	CameraNew.Parent = Viewport
	Viewport.CurrentCamera = CameraNew

end


function Update_ScrollingFrame(Role, Max, Type)
	Vote_Type = Type
	if Role then
		Background:WaitForChild("Title").Text = "Use Your Ability"
	elseif Vote_Type == "Killing" then
		Background:WaitForChild("Title").Text = "Kill"
	else
		Background:WaitForChild("Title").Text = "Voting"
	end

	local Max_Selected = Max
	local N_Selected = 0
	Picked_Player1= ""

	for i,v in pairs(SPlayer:GetPlayers()) do --Loop to make viewports of everyplayers character

		if v.Character:GetAttribute("Dead") then continue end
		if not v.Character:GetAttribute("Can_Vote") then continue end  --Make sure it works for voting and using abilities/still need updating                                                                              
		
		if _G.Current_Vote == "Mafia" and table.find(Role_Des.Mafia, v.Character:GetAttribute("Role")) then
			continue
		end

		local Template_Clone = Template_Button:Clone()
		Template_Clone.Parent = ScrollingFrame

		local Char_N = v.Character or v.CharacterAdded:Wait()

		local CharDupi = RStorage.Players_Chars[Char_N.Name]:Clone()

		CharDupi.Parent = Template_Clone.TemplateBackground.ViewportFrame

		Template_Clone.TemplateBackground["Player'sName"].Text = v.Name
		Update_Viewport(CharDupi, Template_Clone)

		--Button to work
		local Connection = Template_Clone.MouseButton1Click:Connect(function() --Making connections to disable later
			
			if N_Selected == Max_Selected then --there are some roles which can choose more than 1 player
				for i,v in pairs(ScrollingFrame:GetChildren()) do	
					if v.Name == "TemplateButton" then
						v.TemplateBackground.BackgroundColor3 = Color3.fromRGB(0,0,0)
						v.TemplateBackground["Player'sName"].BackgroundColor3 = Color3.fromRGB(0,0,0)
					end
				end
				N_Selected = 0
			end
			
			if Role ~= "Bartender" then --Bartender role may not be able to pick a certain person
				Template_Clone.TemplateBackground.BackgroundColor3 = Color3.fromRGB(66,66,66)
				Template_Clone.TemplateBackground["Player'sName"].BackgroundColor3 = Color3.fromRGB(66,66,66)
			else
				
				if SPlayer[Template_Clone.TemplateBackground["Player'sName"].Text].Character:GetAttribute("Can_Drunk") then 
					--Check If can be drunk
					Template_Clone.TemplateBackground.BackgroundColor3 = Color3.fromRGB(66,66,66)
					Template_Clone.TemplateBackground["Player'sName"].BackgroundColor3 = Color3.fromRGB(66,66,66)
					
				else
					--Show pop up
				end
				
			end
			
			if Role == "Journalist" then
				if Picked_Player1 then
					Picked_Player2 = Template_Clone.TemplateBackground["Player'sName"].Text
				else
					Picked_Player1 = Template_Clone.TemplateBackground["Player'sName"].Text
				end
			else
				Picked_Player1 = Template_Clone.TemplateBackground["Player'sName"].Text
			end

			N_Selected += 1

		end)

		table.insert(Button_Table, Connection)

	end
	
	
	
	PlayerChoose.Enabled = true

	while not Time_Ended do
		task.wait(0.4)
	end

	if N_Selected == 0 then
		Picked_Player1 = nil
		Picked_Player2 = nil
	end


end


RStorage.Game_Remotes.Game_Loop_Events.Voting_Started.OnClientEvent:Connect(function(Vote_Type)
	Update_ScrollingFrame(nil, 1, Vote_Type)
	Vote_Type = ""
	Once = true
	PlayerChoose.Enabled = true
end)

RStorage.Game_Remotes.Game_Loop_Events.Use_Ability.OnClientEvent:Connect(function() --Function for when AbilityTime use starts

	local Role = Char:GetAttribute("Role")
	local P_Role = nil

	if Role == "Civilian" then return end

	if Role == "Journalist" then
		Update_ScrollingFrame(Role,2)
		--return if players are on the role team or not	
	else
		Update_ScrollingFrame(Role,1)
	end


	if not Picked_Player1 then return end

	local Character:Model = SPlayer[Picked_Player1].Character

	if Role == "Detective" then
		P_Role = SPlayer[Picked_Player1]
		-- return chosen player's role
	elseif Role == "Doctor" then

		if Character:GetAttribute("Times_Healed") + 1 == 3 then --Check if character can be healed again
			Player_Events.Died:FireServer(Character.Name)
		else
			Role_Events.Healed:FireServer(Character.Name)
		end  

	elseif Role == "Sheriff" then
		Role_Events.Shot:FireServer(Character.Name)
	end
	
	if Role == "Godfather" then
		if SPlayer[Picked_Player1].Character:GetAttribute("Role") == "Detective" then
			P_Role = SPlayer[Picked_Player1]
		end
	elseif Role == "Bartender" then
		--Update player attributes using a remote
	end
end)

RStorage.Game_Remotes.Game_Loop_Events.Update_Timer.OnClientEvent:Connect(function(Time)
	Time_Ended = false
	Background.Timer.Text = "Time left: "..Time

	if Time == 0 then
		Time_Ended = true
		PlayerChoose.Enabled = false

		for i,v in pairs(ScrollingFrame:GetChildren()) do --Destroy images so we can update later
			if v:IsA("ImageButton") then
				v:Destroy()
			end
		end

		for i,v in Button_Table do --Disconnect to avoid memory leaks
			v:Disconnect()
		end	

		RStorage.Game_Remotes.Game_Loop_Events.Voted:FireServer(Picked_Player1)

		Once = false
		return
	end
end)

