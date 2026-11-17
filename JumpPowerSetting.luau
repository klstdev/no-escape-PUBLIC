local part = script.Parent 

local function onTouched(hit)
	local character = hit.Parent
	local humanoid = character:FindFirstChildOfClass("Humanoid")

	
	if humanoid then
		humanoid.UseJumpPower = true 
		humanoid.JumpPower = 50
	end
end

part.Touched:Connect(onTouched)
