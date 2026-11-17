-- Round System

--[[
	TODO : 라운드 중 플레이어가 나갈 경우 예외처리 - 완
	라운드 시작하고 점프 못하게 막음 ㅇㅇ
	이제 알았는데 , 플레이어가 로비로 텔포할때, 아무 파트에 텔포함 ㅇㅇ...
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local teams = game:GetService("Teams")

local survivorspawn = workspace:WaitForChild("SurvivorSpawns")
local lobbyFolder = workspace:WaitForChild("Lobby")

local INTERMISSION = 20 -- 인터미션 시간 
local Round = 30 -- 라운드 지속시간
local min_players = 1 -- 나중에 2로 바꾸셈 ( 최소 플레이어수 )

-- shared values (UI)
local statusValue = Instance.new("StringValue")
statusValue.Name = "Status"
statusValue.Value = "Waiting"
statusValue.Parent = ReplicatedStorage

local timerValue = Instance.new("IntValue")
timerValue.Name = "Timer"
timerValue.Value = 0
timerValue.Parent = ReplicatedStorage

local function WaitPlayers()
	
	local targetTeam = teams:WaitForChild("Spectate") -- 관전 팀
	-- 모든 플레이어를 관전팀으로 옮김
	
	for _, player in ipairs(Players:GetPlayers()) do
		player.Team = targetTeam
	end
	
	statusValue.Value = "Waiting"
	timerValue.Value = 0
	while #Players:GetPlayers() < min_players do
		warn("플레이어 없음 ㅅㄱ")
		task.wait(1)
	end
end

local function RunIntermission()
	statusValue.Value = "Intermission"
	local t = INTERMISSION
	while t > 0 do
		if #Players:GetPlayers() < min_players then
			WaitPlayers()
			statusValue.Value = "Intermission"
			t = INTERMISSION
		end
		timerValue.Value = t
		task.wait(1)
		t -= 1
	end
end

local function TeleportPlayer(player, part)
	local character = player.Character
	if not character or not player.Parent then return end

	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end

	character:PivotTo(part.CFrame * CFrame.new(0, 5, 0))
end


local function TeleportAllRandom(folder)
	local spawns = folder:GetChildren()
	if #spawns == 0 then
		warn(folder.Name .. " 폴더 안에 파트 없음")
		return
	end
	for _, player in ipairs(Players:GetPlayers()) do
		TeleportPlayer(player, spawns[math.random(1, #spawns)])
	end
end

local active = {} -- 라운드에 있는 플레이어 목록


--[[
	라운드중에 플레이어 점프 못 하게 막는 코드
]]
local Default_JumpPower = 50
local Default_JumpHeight = 7.2

local function SetJump(player, enabled)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	
	hum.JumpPower = enabled and Default_JumpPower or 0
	hum.JumpHeight = enabled and Default_JumpHeight or 0
end

local function OnCharacterAdded(player, char)
	local hum = char:WaitForChild("Humanoid", 5)
	
	if not hum then return end
	
	SetJump(player, not active[player])
end


local function OnPlayerAdded(player)
	player.CharacterAdded:Connect(function(char)
		OnPlayerAdded(player, char)
	end)
end

for _, player in ipairs(Players:GetPlayers()) do
	OnPlayerAdded(player)
end

Players.PlayerAdded:Connect(OnPlayerAdded)


local function GetAliveCount()
	local count = 0
	for player in pairs(active) do
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health > 0 then
			count += 1
		end
	end
	return count
end

Players.PlayerRemoving:Connect(function(player)
	active[player] = nil
end)



local function RunRound()
	local survivorteam = teams:WaitForChild("Survivor")
	local spectateteam = teams:WaitForChild("Spectate")
	
	active = {} -- 플레이어 등록
	for _, player in ipairs(Players:GetPlayers()) do
		active[player] = true
		player.Team = survivorteam
		SetJump(player, false)
	end
	
	TeleportAllRandom(survivorspawn)

	statusValue.Value = "Round"
	
	local t = Round
	while t > 0 do
		if next(active) == nil then
			-- warn("no active players. ending round")
			break
		end
		
		if GetAliveCount() == 0 then
			break
		end
		timerValue.Value = t
		task.wait(1)
		t -= 1
	end
	timerValue.Value = 0
	
	for _, player in ipairs(Players:GetPlayers()) do
		player.Team = spectateteam
	end
	
	--// LobbySpawn 파트에 텔포하게 지정하기
	--// 내가 왜 이걸 수정 못했지? 그냥 3줄 코드인데;;
	local lobbyspawn = lobbyFolder:WaitForChild("LobbySpawn")
	
	for _, player in ipairs(Players:GetPlayers()) do
		TeleportPlayer(player, lobbyspawn)
	end
	
	active = {}
	
	for _, player in ipairs(Players:GetPlayers()) do
		player.Team = spectateteam
	end
	
	TeleportAllRandom(lobbyFolder)
end


-- 메인 루프 // 건들면 뒤짐
while true do
	WaitPlayers()
	RunIntermission()
	RunRound()
end
