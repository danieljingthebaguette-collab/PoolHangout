--!strict
-- The table's layout in table space (see ARCHITECTURE.md), worked out from Config.Table or a shot's params.

-- The Config.Table numbers the layout comes from
export type TableParams = {
	Length: number,
	Width: number,
	BallRadius: number,
	CornerPocketMouth: number,
	SidePocketMouth: number,
}
export type Rail = { ax: number, ay: number, bx: number, by: number }
export type Pocket = { x: number, y: number, radius: number }
export type Layout = {
	rails: { Rail },
	pockets: { Pocket },
	rack: { { x: number, y: number } },
	headLineX: number,
}

local Geometry = {}

function Geometry.build(tableParams: TableParams): Layout
	local halfLength, halfWidth = tableParams.Length / 2, tableParams.Width / 2
	-- A corner pocket's mouth is measured across its diagonal opening, like a real table's
	local cornerGap = tableParams.CornerPocketMouth / math.sqrt(2)
	local sideGap = tableParams.SidePocketMouth / 2

	-- Straight cushions with gaps for the pockets. Their ends are the pockets' jaws.
	local rails: { Rail } = {}
	for _, y in { -halfWidth, halfWidth } do
		table.insert(rails, { ax = -halfLength + cornerGap, ay = y, bx = -sideGap, by = y })
		table.insert(rails, { ax = sideGap, ay = y, bx = halfLength - cornerGap, by = y })
	end
	for _, x in { -halfLength, halfLength } do
		table.insert(rails, { ax = x, ay = -halfWidth + cornerGap, bx = x, by = halfWidth - cornerGap })
	end

	-- Pocket ids: 1–3 along the −y side from the head end to the foot end, 4–6 along the +y side.
	-- A ball drops once its center is within a pocket's radius.
	local pockets: { Pocket } = {}
	for _, y in { -halfWidth, halfWidth } do
		table.insert(pockets, { x = -halfLength, y = y, radius = tableParams.CornerPocketMouth / 2 })
		table.insert(pockets, { x = 0, y = y, radius = sideGap })
		table.insert(pockets, { x = halfLength, y = y, radius = tableParams.CornerPocketMouth / 2 })
	end

	-- 15 touching balls in a triangle: the first on the foot spot, the rows behind it toward the foot rail
	local radius = tableParams.BallRadius
	local rack: { { x: number, y: number } } = {}
	for row = 0, 4 do
		for i = 0, row do
			table.insert(
				rack,
				{ x = tableParams.Length / 4 + row * math.sqrt(3) * radius, y = (i - row / 2) * 2 * radius }
			)
		end
	end

	return { rails = rails, pockets = pockets, rack = rack, headLineX = -tableParams.Length / 4 }
end

return Geometry
