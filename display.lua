local fiend = _G.Fiend

local texture = [[Interface\Addons\Fiend\media\HalV.tga]]

local floor = math.floor

local GetDPS = function(self)
	if fiend.combatTime[self.guid] > 0 then
		return floor(self.total / fiend.combatTime[self.guid])
	else
		return 0
	end
end

local tip = GameTooltip
local OnEnter = function(self)
	if self:IsShown() and self.pos > 0 then
		tip:SetOwner(self, "ANCHOR_LEFT")
		tip:AddDoubleLine(self.pos .. ". " .. self.name, GetDPS(self) .. " " .. self.parent.suffix, self.col.r, self.col.g, self.col.b, self.col.r, self.col.g, self.col.b)
		tip:AddDoubleLine(self.total, "(" .. math.floor(self.total / self.parent.total * 100) .. "%)", 1, 1, 1, 1, 1, 1)

		tip:Show()
		self.parent.tip = true
	end
end

fiend.OnEnter = OnEnter

local pool = setmetatable({}, {
	__mode = "k",
	__newindex = function(self, index, bar)
		bar.name = nil
		bar.guid = nil
		bar.class = nil
		bar.col = nil
		bar.total = 0
		bar.parent = nil

		rawset(self, index, bar)
	end
})

local Display = {}

function Display:Update(guid, ammount)
	local bar = self.guids[guid]

	bar.total = bar.total + ammount
	self.total = self.total + ammount

	-- bar.per = math.floor(bar.total / self.total * 100)

	bar.right:SetText(bar.total)

	self.dirty = true
end

function Display:UpdateDisplay()
	if not self.isActive or #self.bars == 0 or not fiend.frame:IsShown() then return end

	table.sort(self.bars, function(a, b) return b.total < a.total end)

	local total = math.floor((fiend.frame:GetHeight() - 32) / self.size)
	local width = fiend.frame:GetWidth()

	local size = self.size

	local max = self.bars[1].total

	local bar
	for i = 1, #self.bars do
		bar = self.bars[i]
		if i > total then
			bar.pos = 0
			bar:Hide()
		else
			bar:SetValue(100 * (bar.total / max))

			if bar.pos ~= i then
				bar:SetPoint("TOP", fiend.frame, "TOP", 0, ((i - 1) * -size) - 32)

				bar.left:SetText(i .. ". " .. bar.name)

				bar.pos = i
			end

			bar:Show()
		end
	end

	self.dirty = false
end

function Display:RemoveAllBars()
	local bar
	for i = 1, #self.bars do
		bar = table.remove(self.bars, 1)

		bar:Hide()

		self.guids[bar.guid] = nil

		fiend.combatTime[bar.guid] = 0

		table.insert(pool, bar)
	end

	self.total = 0
end

function Display:Resizing(width, height)
	local total = math.floor((height or fiend.frame:GetHeight() - 32) / self.size)

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

	if fiend.currentDisplay then
		fiend.currentDisplay:Deactivate()
	end

	fiend.frame.title:SetText(self.title)
	fiend.frame:SetBackdropBorderColor(unpack(self.bg))

	fiend.currentDisplay = self

	if fiend.dropDown:IsShown() then
		UIDropDownMenu_Refresh(fiend.dropDown)
	end

	self.isActive = true
	-- Update faster
	self:UpdateDisplay()
end

function Display:Deactivate(clean)
	if not self.isActive then return end

	self.isActive = false

	if clean then
		self:ResetAllBars()
	else
		local bar
		for i = 1, #self.bars do
			bar = self.bars[i]
			bar:Hide()
			bar.pos = 0     -- Force update next dirty cycle
		end
	end

	fiend.currentDisplay = nil
end

function Display:Output(count, where, player)
	if #self.bars == 0 then return end

	local output

	if not where then
		output = print
	else
		output = function(str)
			SendChatMessage(str, where, nil, where == "WHISPER" and player)
		end
	end

	-- I want a total width of 32 chars
	local width = 32
	width = (width - (string.len("Fiend " .. self.title))) / 2

	output(string.rep("=", width) .."Fiend " .. self.title .. string.rep("=", width))

	-- Need to do a double pass
	local bar
	for i = 1, count or #self.bars do
		if not self.bars[i] then break end
		bar = self.bars[i]
		output(string.format("%d. %s - %d (%d%s) - %d%%", i, bar.name, bar.total, GetDPS(bar), self.suffix, (math.floor(bar.total * 10000 / self.total) / 100)))
	end
end

fiend.Display = setmetatable({}, { __call = function(self, title, size, bg, suffix)
	if not fiend.displays[title] then
		local t = setmetatable({}, { __index = Display } )

		fiend.displayCount = fiend.displayCount + 1

		t.bars = {}
		t.max = 0
		t.isActive = false
		t.size = size
		t.title = title
		t.total = 0
		t.bg = bg or { 0.3, 0.3, 0.3 }
		t.suffix = suffix

		t.guids = setmetatable({}, { __index = function(self, guid)
			local bar
			if next(pool) then
				bar = table.remove(pool, 1)
			else
				bar = CreateFrame("Statusbar", nil, fiend.frame)
				bar:SetStatusBarTexture(texture)
				bar:SetMinMaxValues(0, 100)
				bar:SetPoint("LEFT", 1, 0)
				bar:SetPoint("RIGHT", - 1, 0)
				bar:EnableMouse(true)
				bar:Hide()

				bar:SetScript("OnEnter", OnEnter)
				bar:SetScript("OnLeave", function(self) tip:Hide(); self.parent.tip = false end)

				local bg = bar:CreateTexture(nil, "BACKGROUND")
				bg:SetTexture(texture)
				bg:SetAllPoints(bar)

				bar.bg = bg

				local left = bar:CreateFontString(nil, "OVERLAY")
				left:SetFont(STANDARD_TEXT_FONT, size - 2)
				left:SetPoint("LEFT", bar, "LEFT", 5, 0)
				left:SetPoint("BOTTOM")
				left:SetPoint("TOP")
				left:SetShadowColor(0, 0, 0, 0.8)
				left:SetShadowOffset(0.8, - 0.8)

				bar.left = left

				local right = bar:CreateFontString(nil, "OVERLAY")
				right:SetFont(STANDARD_TEXT_FONT, size - 2)
				right:SetPoint("RIGHT", fiend.frame, "RIGHT", - 5, 0)
				right:SetPoint("TOP")
				right:SetPoint("BOTTOM")
				right:SetJustifyH("RIGHT")
				right:SetShadowColor(0, 0, 0, 0.8)
				right:SetShadowOffset(0.8, - 0.8)

				bar.right = right
			end

			local unit = fiend:GetUnit(guid)
			if not unit then
				if UnitInRaid("player") then
					fiend:RAID_ROSTER_UPDATE()
				else
					fiend:PARTY_MEMBERS_UPDATE()
				end

				unit = fiend:GetUnit(guid)
				-- PRAY WITH ME
			end

			local class = select(2, UnitClass(unit)) or "WARRIOR"
			local col = RAID_CLASS_COLORS[class]
			local name = UnitName(unit)

			bar:SetHeight(size)
			bar:SetStatusBarColor(col.r, col.g, col.b)
			bar.bg:SetVertexColor(col.r, col.g, col.b, 0.1)

			bar.left:SetText(name)
			bar.right:SetText(0)

			bar.guid = guid
			bar.parent = t
			bar.total = 0
			bar.pos = 0
			bar.class = class
			bar.col = col
			bar.name = name

			fiend.combatTime[guid] = 0

			table.insert(t.bars, bar)
			rawset(self, guid, bar)

			bar:Hide()

			return bar
		end})

		fiend.displays[title] = t
	end

	local drop = fiend.dropDown

	local menu = {
		text = title,
		owner = drop,
		func = function(self)
			fiend.displays[title]:Activate()
		end,
	}

	fiend.menu[1][3].menuList[#fiend.menu[1][3].menuList + 1] = menu

	if fiend.dropDown:IsShown() then
		UIDropDownMenu_Refresh(fiend.dropDown)
	end

	return fiend.displays[title]
end})
