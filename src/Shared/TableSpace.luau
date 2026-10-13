--!strict
-- Converts between the world and a table's table space (see ARCHITECTURE.md): table x is the Felt's
-- local X axis, table y its local Z axis, and balls rest on its top face.

local TableSpace = {}

-- Where a ball of `radius` centered at (x, y) sits
function TableSpace.toWorld(felt: BasePart, x: number, y: number, radius: number): CFrame
	return felt.CFrame * CFrame.new(x, felt.Size.Y / 2 + radius, y)
end

function TableSpace.toTable(felt: BasePart, position: Vector3): (number, number)
	local point = felt.CFrame:PointToObjectSpace(position)
	return point.X, point.Z
end

-- Shows or hides a ball part along with any markings welded to it
function TableSpace.setShown(ball: BasePart, shown: boolean)
	local transparency = if shown then 0 else 1
	ball.Transparency = transparency
	for _, child in ball:GetChildren() do
		if child:IsA("BasePart") then
			child.Transparency = transparency
		end
	end
end

return TableSpace
