--// 히트박스 투명 처리
--// 지금 맵이 하나여서 이렇게 해도 알빠는 아닌데 맵 나중에 많이 추가할때 이렇게 하면 좆될수도 ㅇㅇ
--// 하지만 성능은 책임지죠?
local folder = script.Parent
local children = folder:GetChildren()

for _, child in ipairs(children) do
	if child:IsA("BasePart") then
		child.Transparency = 1
	end
end
