local fiend = _G.Fiend

local texture = [[Interface\Addons\Fiend\media\HalV.tga]]

local Display = setmetatable({}, {
	__call = function(self, title, size)
		if not fiend.displays[name] then
			local t = setmetatable({}, { __index = self } )

			t.bars = {}
			t.max = 0
			t.isActive = false
			t.size = size

			if (#fiend.displays == 0) then
				t.isActive = true
			end

			t.names = setmetatable({}, { __index = function(self, name)
				local bar = fiend.frame:CreateTexture(nil, "OVERLAY")
				bar:SetTexture(texture)
				bar:SetHeight(size)
				local col = RAID_CLASS_COLORS[select(2, UnitClass(name)) or "WARRIOR"]
				bar:SetVertexColor(col.r, col.g, col.b)

				local left = fiend.frame:CreateFontString(nil, "OVERLAY")
				left:SetFont(STANDARD_TEXT_FONT, 14)
				left:SetPoint("LEFT", bar, "LEFT")
				left:SetPoint("CENTER", bar, "CENTER")
				left:SetText(name)

				bar.left = left

				local right = fiend.frame:CreateFontString(nil, "OVERLAY")
				right:SetFont(STANDARD_TEXT_FONT, 14)
				right:SetPoint("RIGHT", fiend.frame, "RIGHT")
				right:SetPoint("CENTER", bar, "CENTER")
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

				return self[name]
			end})

			fiend.displays[title] = t
		end

		return fiend.displays[title]
	end
})

function Display:Update(name, ammount)
	local bar = self.names[name]

	bar.total = bar.total + ammount

	if not self.isActive then return end

	for i, bar in ipairs(self.bars) do
		if bar.total > self.max then
			self.max = bar.total
		end
	end

	bar:SetWidth(fiend.frame:GetWidth() * (bar.total / self.max))
	bar.right:SetText(bar.total)

	self:UpdateDisplay()
end

function Display:UpdateDisplay()
	table.sort(self.bars, function(a, b) return b.total < a.total end)

	local total = math.floor(fiend.frame:GetHeight() / self.size)

	for i, bar in ipairs(self.bars) do
		bar:SetWidth(fiend.frame:GetWidth() * (bar.total / self.max))
		bar:Show()
		if i > total then
			bar.pos = 0
			bar:Hide()
		elseif bar.pos ~= i then
			bar:ClearAllPoints()

			if i > 1 then
				bar:SetPoint("TOP", self.bars[i - 1], "BOTTOM")
			else
				bar:SetPoint("TOP", fiend.frame, "TOP")
			end

			bar:SetPoint("LEFT", fiend.frame, "LEFT")

			bar.pos = i
		end
	end
end

function Display:ResetBar(name)
	local bar = self.names[name]

	local total = bar.total
	bar.total = 0
	bar:Hide()
	bar.pos = 0
	bar:SetWidth(0)

	bar.right:SetText(0)

	if self.max == total then
		self.max = 0
		for i, bar in ipairs(self.bars) do
			if bar.total > self.max then
				self.max = bar.total
			end
		end
	end
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

	for i, bar in ipairs(self.bars) do
		if i > total then
			bar:Hide()
		else
			bar:Show()
		end
	end
end

fiend.Display = Display
