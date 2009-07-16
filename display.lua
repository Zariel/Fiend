local fiend = _G.Fiend

local texture = [[Interface\Addons\Fiend\media\HalV.tga]]

local Display = setmetatable({}, {
	__call = function(self, title, size)
		if not fiend.displays[name] then
			local t = setmetatable({}, { __index = self } )

			fiend.displayCount = fiend.displayCount + 1

			t.bars = {}
			t.max = 0
			t.isActive = false
			t.size = size

			t.names = setmetatable({}, { __index = function(self, name)
				local bar = CreateFrame("Statusbar", nil, fiend.frame)
				bar:SetStatusBarTexture(texture)
				bar:SetHeight(size)
				local col = RAID_CLASS_COLORS[select(2, UnitClass(name)) or "WARRIOR"]
				bar:SetStatusBarColor(col.r, col.g, col.b)
				bar:SetMinMaxValues(0, 100)
				bar:SetPoint("LEFT")
				bar:SetPoint("RIGHT")

				local left = bar:CreateFontString(nil, "OVERLAY")
				left:SetFont(STANDARD_TEXT_FONT, 14)
				left:SetPoint("LEFT", bar, "LEFT")
				left:SetPoint("BOTTOM")
				left:SetPoint("TOP")
				left:SetText(name)

				bar.left = left

				local right = bar:CreateFontString(nil, "OVERLAY")
				right:SetFont(STANDARD_TEXT_FONT, 14)
				right:SetPoint("RIGHT", fiend.frame, "RIGHT")
				right:SetPoint("TOP")
				right:SetPoint("BOTTOM")
				right:SetJustifyH("RIGHT")
				right:SetText("0")

				bar.right = right

				bar.name = name
				bar.parent = title
				bar.toUpdate = 0
				bar.dirty = false
				bar.total = 0
				bar.pos = 0

				table.insert(t.bars, bar)
				self[name] = bar

				bar:Hide()

				return bar
			end})

			fiend.displays[title] = t
		end

		return fiend.displays[title]
	end
})

function Display:Update(name, ammount)
	local bar = self.names[name]

	bar.total = bar.total + ammount
	bar.right:SetText(bar.total)

	self.dirty = true
end

function Display:UpdateDisplay()
	if not self.isActive then return end

	table.sort(self.bars, function(a, b) return b.total < a.total end)

	self.max = self.bars[1].total

	local total = math.floor(fiend.frame:GetHeight() / self.size)
	local width = fiend.frame:GetWidth()

	local bar
	for i = 1, #self.bars do
		bar = self.bars[i]
		if i > total then
			bar.pos = 0
			bar:Hide()
		else
			bar:SetValue(100 * (bar.total / self.max))

			if bar.pos ~= i then
				bar:SetPoint("TOP", fiend.frame, "TOP", 0, -16 * (i - 1))
			end

			bar.pos = i

			bar:Show()
		end
	end

	self.dirty = false
end

function Display:ResetBar(name)
	local bar = self.names[name]

	bar.total = 0
	bar.pos = 0

	bar.right:SetText(0)

	bar:SetValue(0)
	bar:Hide()

	self.dirty = true
end

function Display:RemoveBar(name)
	local bar = self.names[name]

	if bar.pos > 0 then
		table.remove(self.bars, bar.pos)
	else
		for i, bars in pairs(self.bars) do
			table.remove(self.bars, i)
			break
		end
	end

	self:ResetBar(name)

	self.names[name] = nil
end

function Display:Resizing()
	local total = math.floor(fiend.frame:GetHeight() / self.size)

	local bar
	for i = 1, #self.bars do
		bar = self.bars[i]
		if i > total then
			bar:Hide()
		else
			bar:Show()
		end
	end
end

function Display:Activate()
	if self.isActive then return end

	for k, v in pairs(fiend.displays) do
		if v.isActive then
			v.isActive = false
			break
		end
	end

	self.isActive = true
	self.dirty = true
end

function Display:Deactivate()
	if not self.isActive then return end

	for name, bar in pairs(self.names) do
		self:ResetBar(name)
	end

	self.isActive = false
end

fiend.Display = Display
