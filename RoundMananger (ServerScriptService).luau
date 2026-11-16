-- Round System
-- TODO : 라운드 중 플레이어가 나갈 경우 예외처리
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
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root then
		root.CFrame = part.CFrame + Vector3.new(0, 5, 0)
	end
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

local function GetAliveCount()
	local count = 0
	for player in ipairs(active) do
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
	
	active = {}
	
	TeleportAllRandom(lobbyFolder)
end


-- 메인 루프 // 건들면 뒤짐
while true do
	WaitPlayers()
	RunIntermission()
	RunRound()
end
