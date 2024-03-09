--Services
local SPlayer = game:GetService("Players")
local SUGS = UserSettings():GetService("UserGameSettings")
local STween = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local SRun = game:GetService("RunService")
local RStorage = game:GetService("ReplicatedStorage")
--PlayerVars
local LPlayer = SPlayer.LocalPlayer
local Char = LPlayer.CharacterAdded:Wait() or LPlayer.Character
local Hum = Char:WaitForChild("Humanoid")
local HumPart = Char:WaitForChild("HumanoidRootPart")
local Head = Char:WaitForChild("Head")

--Modules
local CameraMS = require(script:WaitForChild("CameraMS"))

--OtherVars
local Camera = game.Workspace.CurrentCamera
Camera.FieldOfView = 80

local Ate_Poison = false
local Shake_CF = CFrame.new()

----------------------------------- Settings
CanToggleMouse = {allowed = true; activationkey = Enum.KeyCode.F;}
CanViewBody = true
Sensitivity = SUGS.MouseSensitivity
Smoothness = SUGS.MouseSensitivity/4
FieldOfView = 80	
HeadOffset = CFrame.new(0,0.7,0)

--More Vars
local CamPos,TargetCamPos = Camera.CoordinateFrame.p,Camera.CoordinateFrame.p 
local AngleX,TargetAngleX = 0,0
local AngleY,TargetAngleY = 0,0

local running = true
local freemouse = false
local defFOV = FieldOfView
--TweenVars
local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
local In = {CameraMaxZoomDistance = 0.3, CameraMinZoomDistance = 0.3}
local Out = {CameraMaxZoomDistance = 13, CameraMinZoomDistance = 13}

local Debounce = false
local OutVar = false
local Connection = nil 
local Input_Connection = nil

--//Functions
function Died()
	if Connection then
		Connection:Disconnect()
		Input_Connection:Disconnect()
	end

	Camera.CameraType = Enum.CameraType.Custom
	UIS.MouseBehavior = Enum.MouseBehavior.Default

	local Tween = STween:Create(LPlayer, tweenInfo, Out)
	Tween:Play()
	Tween.Completed:Wait()	
end

Char:FindFirstChildOfClass("Humanoid").Died:Connect(function()
	Died()
end)

LPlayer.CharacterAdded:Connect(function(Character)
	print("Character_Added")
	Head = Character:WaitForChild("Head")
	Char = Character
	
	Character:FindFirstChildOfClass("Humanoid").Died:Connect(function()
		Died()
	end)
	
end)

UIS.InputBegan:Connect(function(Input, gpe)
	
	if gpe then return end
	if Char:FindFirstChildOfClass("Humanoid").Health <= 0 then return end
	
	if LPlayer.CameraMaxZoomDistance > 0.5 then
		OutVar = true	
	elseif LPlayer.CameraMaxZoomDistance == 0.5 then
		OutVar = false
	end

	if Input.KeyCode == Enum.KeyCode.Q then
		
		if Debounce then return end
		
		if Connection then
			Connection:Disconnect()
			Input_Connection:Disconnect()
		end
		Debounce = true
		
		if OutVar then
						
			local Tween = STween:Create(LPlayer, tweenInfo, In)
			Tween:Play()
			
			Tween.Completed:Wait()
			
			UIS.MouseBehavior = Enum.MouseBehavior.LockCenter	
			
			local X,Y,Z = Camera.CFrame:ToOrientation()
			TargetAngleX = math.deg(X) 
			TargetAngleY = math.deg(Y) 
			
		
			Connection = SRun.RenderStepped:connect(function()
				if running then
					
					CameraMS.UpdateChar(Char)
					
					CamPos = CamPos + (TargetCamPos - CamPos) *0.28 
					AngleX = AngleX + (TargetAngleX - AngleX) *0.35 
					
					local dist = TargetAngleY - AngleY 
					
					dist = math.abs(dist) > 180 and dist - (dist / math.abs(dist)) * 360 or dist 
					AngleY = (AngleY + dist *0.35) %360
					
					Camera.CameraType = Enum.CameraType.Scriptable
					
					Camera.CoordinateFrame = CFrame.new(Head.Position) 
						* CFrame.Angles(0,math.rad(AngleY),0) 
						* CFrame.Angles(math.rad(AngleX),0,0)
						* HeadOffset
						* Shake_CF
					
					HumPart.CFrame=CFrame.new(HumPart.Position)*CFrame.Angles(0,math.rad(AngleY),0)
					
					
				else 
					game:GetService("UserInputService").MouseBehavior = Enum.MouseBehavior.Default
				end
				
				if (Camera.Focus.p-Camera.CoordinateFrame.p).magnitude < 1 then
					running = false
				else
					running = true
					if freemouse == true then
						game:GetService("UserInputService").MouseBehavior = Enum.MouseBehavior.Default
					else
						game:GetService("UserInputService").MouseBehavior = Enum.MouseBehavior.LockCenter
					end
				end
				if not CanToggleMouse.allowed then
					freemouse = false
				end
				Camera.FieldOfView = FieldOfView
			end)
			
			Input_Connection = UIS.InputChanged:connect(function(inputObject)
				if inputObject.UserInputType == Enum.UserInputType.MouseMovement then
					
					Sensitivity = SUGS.MouseSensitivity
					Smoothness = SUGS.MouseSensitivity/4
				
					local delta = Vector2.new(inputObject.Delta.x,inputObject.Delta.y) * Smoothness

					local X = TargetAngleX - delta.y 
					TargetAngleX = (X >= 80 and 80) or (X <= -80 and -80) or X 
					TargetAngleY = (TargetAngleY - delta.x) %360 
				end	
			end)
			
			Debounce = false
			OutVar = false
			
		elseif not OutVar then
			Camera.CameraType = Enum.CameraType.Custom
			UIS.MouseBehavior = Enum.MouseBehavior.Default
			
			Camera.CFrame = Head.CFrame
			
			local Tween = STween:Create(LPlayer, tweenInfo, Out)
			Tween:Play()
			Tween.Completed:Wait()
			
			Debounce = false
			OutVar = true
		end	
	end
end)






