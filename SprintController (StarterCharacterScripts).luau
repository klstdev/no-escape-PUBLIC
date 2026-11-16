--[[
	TODO : 모바일 버튼 토글로 바꾸기 시발
	// 지금 알았는데 내가 디버깅 땜에 출력한다고 전용 함수까지 만들어놨었더라;;
	// ㅅㅂ 나 죽여라 그냥
	
	NOTE : 제발 애니메이션 아이디만 넣지말고 에셋 권한을 좀 넣어 시발
		안넣어서 아웃풋창 지랄났잖아;;
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local character = script.Parent
local humanoid = character:WaitForChild("Humanoid") :: Humanoid
local rootPart = character:WaitForChild("HumanoidRootPart") :: BasePart
local animator = humanoid:WaitForChild("Animator") :: Animator

-- 설정
local CONFIG = {
	WalkSpeed = 12,
	RunSpeed = 22.5,
	MoveThreshold = 0.1, --// 이 값보다 이동 입력이 작으면 안 움직이는 중
	MinRealSpeed = 0.5, 
	FadeTime = 0.2, 
	RunKeys = { Enum.KeyCode.LeftShift, Enum.KeyCode.RightShift },

	MaxStamina = 110, 
	DrainPerSecond = 9, 
	RegenPerSecond = 19.5, --// 회복 시 초당 회복량
	RegenDelay = 0.8,
	ExhaustedThreshold = 30, 

	BaseFOV = 70, --// 평소 시야각
	RunFOV = 85, --// 스프린트 시 시야각
	FOVTweenIn = 0.35, --// 달리기 시작할 때 넓어지는 시간
	FOVTweenOut = 0.3, --// 달리기 끝날 때 돌아오는 시간

	MobileGuiName = "Sprint_Mobile", 
	MobileButtonName = "Runbutton",
}

--// 나중에 애니메이션 만들면 "rbxassetid://123456" 형식으로 넣기 ㅇㅇ
local ANIMATION_IDS = {
	Idle = "",
	Walk = "",
	Run = "rbxassetid://76619896647076", --// 115045971738112 71988936866100
}

--// Run은 기본 Animate의 걷기/뛰기(Core/Movement)보다 위에서 덮어써야 하므로 Action // 코피바라는 봐라
local ANIMATION_PRIORITY = {
	Idle = Enum.AnimationPriority.Idle,
	Run = Enum.AnimationPriority.Action,
}


type MoveState = "Idle" | "Walk" | "Run"

local currentState: MoveState = "Idle"
local runHeld = false
local tracks: { [string]: AnimationTrack } = {}


for stateName, id in pairs(ANIMATION_IDS) do
	if id ~= "" then
		local animation = Instance.new("Animation")
		animation.AnimationId = id
		local track = animator:LoadAnimation(animation)
		track.Priority = ANIMATION_PRIORITY[stateName]
		track.Looped = true
		tracks[stateName] = track
	end
end

local function playStateAnimation(state: MoveState)
	for stateName, track in pairs(tracks) do
		if stateName == state then
			if not track.IsPlaying then
				track:Play(CONFIG.FadeTime)
			end
		else
			if track.IsPlaying then
				track:Stop(CONFIG.FadeTime)
			end
		end
	end
end

--// 스프린트 카메라 효과
local fovTween: Tween? = nil

local function tweenFOV(targetFOV: number, duration: number)
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	if fovTween then
		fovTween:Cancel()
	end
	fovTween = TweenService:Create(
		camera,
		TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ FieldOfView = targetFOV }
	)
	fovTween:Play()
end

local function updateCameraEffect(state: MoveState)
	if state == "Run" then
		tweenFOV(CONFIG.RunFOV, CONFIG.FOVTweenIn)
	else
		tweenFOV(CONFIG.BaseFOV, CONFIG.FOVTweenOut)
	end
end

local function setState(newState: MoveState)
	if newState == currentState then
		return
	end
	currentState = newState

	updateCameraEffect(newState)


	if newState == "Run" then
		humanoid.WalkSpeed = CONFIG.RunSpeed
	else
		humanoid.WalkSpeed = CONFIG.WalkSpeed
	end

	playStateAnimation(newState) --// 제발건들지마라제발건들지마라제발건들지마라제발건들지마라

	character:SetAttribute("MoveState", newState)
end


local function isRunKey(keyCode: Enum.KeyCode): boolean
	return table.find(CONFIG.RunKeys, keyCode) ~= nil
end


--// 이거 무슨 역할이더라
local runSources: { [string]: boolean } = {}

local function SetRunHeld(source: string, held: boolean)
	runSources[source] = if held then true else nil
	runHeld = next(runSources) ~= nil
end

local function ReleaseAllRunInputs()
	table.clear(runSources)
	runHeld = false
end

UserInputService.InputBegan:Connect(function(input)
	if not isRunKey(input.KeyCode) then
		return
	end

	if UserInputService:GetFocusedTextBox() then
		return
	end
	SetRunHeld("Keyboard", true)
	-- print("run key pressed")
end)

UserInputService.InputEnded:Connect(function(input)
	--// 뗄 때는 gameProcessed 검사 안 함
	if isRunKey(input.KeyCode) then
		SetRunHeld("Keyboard", false)
	end
end)

UserInputService.WindowFocusReleased:Connect(function()
	ReleaseAllRunInputs()
end)

local function setupMobileButton()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	local gui = playerGui:WaitForChild(CONFIG.MobileGuiName, 5)
	local button = gui and gui:WaitForChild(CONFIG.MobileButtonName, 5)

	if not button or not button:IsA("GuiButton") then 
		warn(("MovementController: Failed finding mobile sprint button: %s > %s"):format(
			CONFIG.MobileGuiName,
			CONFIG.MobileButtonName
			))
		return
	end

	
	button.Visible = UserInputService.TouchEnabled
	print("button found :", button:GetFullName(), "| Visible =", button.Visible,
		"| TouchEnabled =", UserInputService.TouchEnabled,
		"| MouseEnabled =", UserInputService.MouseEnabled)

	UserInputService.LastInputTypeChanged:Connect(function(lastInputType)
		if lastInputType == Enum.UserInputType.Touch then
			button.Visible = true
		elseif lastInputType == Enum.UserInputType.Keyboard or string.find(lastInputType.Name, "Gamepad") then
			button.Visible = false
		end
	end)

	local activeInput: InputObject? = nil

	button.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.Touch
			or input.UserInputType == Enum.UserInputType.MouseButton1 --// Studio 에뮬레이터/마우스 테스트용
		then
			activeInput = input
			SetRunHeld("Mobile", true)
			-- print("button pressed :", input.UserInputType.Name)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if activeInput and input == activeInput then
			activeInput = nil
			SetRunHeld("Mobile", false)
		end
	end)


	button.Destroying:Connect(function()
		activeInput = nil
		SetRunHeld("Mobile", false)
	end)
	button:GetPropertyChangedSignal("Visible"):Connect(function()
		if not button.Visible then
			activeInput = nil
			SetRunHeld("Mobile", false)
		end
	end)
end

task.spawn(setupMobileButton)

local stamina = CONFIG.MaxStamina
local exhausted = false --// 탈진: 스태미나가 0이 되어 회복될 때까지 달리기 불가
local regenWait = 0
local uiFullSince: number? = nil --// 스태미나가 가득 찬 시각

local COLOR_FULL = Color3.fromRGB(9, 2, 104)
local COLOR_EMPTY = Color3.fromRGB(135, 135, 135)


local ui = {}
local function getStaminaUI()
	if ui.Bar and ui.Bar.Parent then
		return ui
	end
	local playerGui = Players.LocalPlayer:FindFirstChild("PlayerGui")
	local gui = playerGui and playerGui:FindFirstChild("Stamina")
	local bar = gui and gui:FindFirstChild("StaminaBar")
	if not bar then
		return nil
	end
	ui.Bar = bar
	ui.Fill = bar:FindFirstChild("Fill")
	ui.Label = bar:FindFirstChild("SpeedLabel")
	if not ui.Fill or not ui.Label then
		return nil
	end
	return ui
end


local function isMoving(): boolean
	local hasInput = humanoid.MoveDirection.Magnitude > CONFIG.MoveThreshold
	if not hasInput then
		return false
	end

	local v = rootPart.AssemblyLinearVelocity
	local realSpeed = Vector3.new(v.X, 0, v.Z).Magnitude
	return realSpeed > CONFIG.MinRealSpeed
end

humanoid.WalkSpeed = CONFIG.WalkSpeed
character:SetAttribute("MoveState", "Idle")
updateCameraEffect("Idle")


humanoid.Died:Connect(function()
	tweenFOV(CONFIG.BaseFOV, CONFIG.FOVTweenOut)
end)

RunService.Heartbeat:Connect(function(dt)
	if humanoid.Health <= 0 then
		return
	end

	--// 스태미나 소모/회복
	if currentState == "Run" then
		stamina = math.max(0, stamina - CONFIG.DrainPerSecond * dt)
		regenWait = CONFIG.RegenDelay
		if stamina <= 0 then
			exhausted = true 
		end
	elseif regenWait > 0 then
		regenWait -= dt
	else
		stamina = math.min(CONFIG.MaxStamina, stamina + CONFIG.RegenPerSecond * dt)
	end
	if exhausted and stamina >= CONFIG.ExhaustedThreshold then
		exhausted = false
	end
	character:SetAttribute("Stamina", stamina) 

	if not isMoving() then
		
		setState("Idle")
	elseif runHeld and not exhausted then
		setState("Run")
	else
		setState("Walk")
	end

	local s = getStaminaUI()
	if s then
		local pct = stamina / CONFIG.MaxStamina
		s.Fill.Size = UDim2.fromScale(pct, 1)
		s.Fill.BackgroundColor3 = COLOR_EMPTY:Lerp(COLOR_FULL, pct)

		
		if pct >= 1 then
			uiFullSince = uiFullSince or os.clock()
			s.Bar.Visible = os.clock() - uiFullSince < 1.5
		else
			uiFullSince = nil
			s.Bar.Visible = true
		end

		
		local v = rootPart.AssemblyLinearVelocity
		local speed = Vector3.new(v.X, 0, v.Z).Magnitude
		s.Label.Text = string.format("%d studs/s", math.round(speed))
	end
end)
