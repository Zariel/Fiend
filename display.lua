local fiend = _G.Fiend

local Display = {
}

local View = {
	texture = [[Interface\fiends\Fiend\media\HalV.tga]],
	max = 0,
	isActive = false,
	total = 0,
	bg = { 0.3, 0.3, 0.3 },
}

local floor = math.floor

local tip = GameTooltip
function display.OnEnter = function(self)
	if self:IsShown() and self.pos > 0 then
		tip:SetOwner(self, "ANCHOR_LEFT")
		tip:AddDoubleLine(self.pos .. ". " .. self.name, self.col.r, self.col.g, self.col.b, self.col.r, self.col.g, self.col.b)
		tip:AddDoubleLine(self.total, "(" .. math.floor(self.total / self.parent.total * 100) .. "%)", 1, 1, 1, 1, 1, 1)

		tip:Show()
		self.parent.tip = true
	end
end

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

function View:Update(guid, ammount, name)
	local bar = self.guids[guid]
	bar.name = name

	bar.total = bar.total + ammount
	self.total = self.total + ammount

	-- bar.per = math.floor(bar.total / self.total * 100)

	bar.right:SetText(bar.total)

	self.dirty = true
end

function View:UpdateDisplay()
	if not self.isActive or #self.bars == 0 or not self.display.frame:IsShown() then return end

	table.sort(self.bars, function(a, b) return b.total < a.total end)

	local total = math.floor((self.display.frame:GetHeight() - 32) / self.size)
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

function View:RemoveAllBars()
	local bar
	for i = 1, #self.bars do
		bar = table.remove(self.bars, 1)

		bar:Hide()

		self.guids[bar.guid] = nil

		table.insert(pool, bar)
	end

	self.total = 0
end

function View:Resizing(width, height)
	local total = math.floor((height or self.display.frame:GetHeight() - 32) / self.size)

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

function View:Activate()
	if self.isActive then return end

	if self.display.currentDisplay then
		fiend.currentDisplay:Deactivate()
	end

	self.display.frame.title:SetText(self.title)
	self.display.frame:SetBackdropBorderColor(unpack(self.bg))

	self.display.currentDisplay = self

	--[[
	if fiend.dropDown:IsShown() then
		UIDropDownMenu_Refresh(fiend.dropDown)
	end
	]]

	self.isActive = true
	-- Update faster
	self:UpdateDisplay()
end

function View:Deactivate(clean)
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

	self.display.currentDisplay = nil
end

function View:Output(count, where, player)
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
		output(string.format("%d. %s - %d %d%%", i, bar.name, bar.total, (math.floor(bar.total * 10000 / self.total) / 100)))
	end
end

function Display:CreateFrame(title)
	local frame = CreateFrame("Frame", "FiendDamage" .. title, UIParent)
	frame:SetHeight(250)
	frame:SetWidth(300)
	frame:SetPoint("CENTER")
	frame:EnableMouse(true)
	frame:SetMinResize(50, 50)
	frame:SetMovable(true)
	frame:SetResizable(true)
	frame:SetUserPlaced(true)
	frame:SetClampedToScreen(true)
	--frame:SetHitRectInsets(

	frame:SetScript("OnMouseUp", function(self, button)
		if button == "LeftButton" then
			self:StopMovingOrSizing()
		end
	end)

	frame:SetScript("OnMouseDown", function(s, button)
		if IsModifiedClick("ALT") and button == "LeftButton" then
			s:StartMoving()
		elseif button == "RightButton" then
			if IsModifiedClick("SHIFT") then
				self.currentDisplay:RemoveAllBars()
			else
				--ToggleDropDownMenu(1, nil, fiend.dropDown, "cursor")
			end
		end
	end)

	frame:SetScript("OnSizeChanged", function(s, width, height)
		if self.display.currentDisplay then
			self.display.currentDisplay.dirty = true
		end
	end)

	frame:SetBackdrop({
		bgFile = [[Interface\Tooltips\UI-Tooltip-Background.tga]], tile = true, tileSize = 16,
		edgeFile = [[Interface\fiends\Fiend\media\otravi-semi-full-border.tga]], edgeSize = 32,
		insets = {left = 0, right = 0, top = 20, bottom = 0},
	})

	frame:SetBackdropColor(0, 0, 0, 0.8)

	local title = frame:CreateFontString(nil, "OVERLAY")
	title:SetFont(STANDARD_TEXT_FONT, 16)
	title:SetText("Fiend")
	title:SetJustifyH("CENTER")
	title:SetPoint("CENTER")
	title:SetPoint("TOP", 0, - 12)

	frame.title = title

	local drag = CreateFrame("Frame", nil, frame)
	drag:SetHeight(16)
	drag:SetWidth(16)
	drag:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", - 1, 1)
	drag:EnableMouse(true)
	drag:SetFrameLevel(20)

	drag:SetScript("OnMouseUp", function(self, button)
		if button == "LeftButton" then
			frame:StopMovingOrSizing()
		end
	end)

	drag:SetScript("OnMouseDown", function(self, button)
		if button == "LeftButton" and IsModifiedClick("ALT") then
			frame:StartSizing()
		end
	end)

	local texture = drag:CreateTexture(nil, "OVERLAY")
	texture:SetTexture([[Interface\fiends\Fiend\media\draghandle.tga]])
	texture:SetBlendMode("ADD")
	texture:SetAlpha(0.7)
	texture:SetAllPoints(drag)

	drag.texture = texture
	frame.drag = drag

	self.frame = frame
end

function fiend:NewDisplay(title)
	title = title or #self.displays + 1
	if self.displays[title] then return end

	local t = setmetatable({}, { __index = Display } )

	t.views = {}
	t:CreateFrame(title)

	self.displays[title] = t

	return t
end

function Display:CombatEvent(event, guid, ammount, name, overHeal)
	if not self.events[event] then return end -- Dont care

	if overHeal and self.overHeal then
		self:Update(guid, overHeal, name)
	else if ammount > 0 then
		self:Update(guid, ammount, name)
	end
end

function Display:NewView(title, events, size, bg, color)
	if self.views[title] then return self.views[title] end

	local t = setmetatable({}, { __index = View })

	t.events = {}
	t.bars = {}

	for i, event in pairs(events) do
		t.events[event] = true
	end

	t.size = size
	t.title = title
	t.bg = bg or self.bg
	t.color = color
	t.display = self

	t.guids = setmetatable({}, { __index = function(, guid)
		local bar
		if next(pool) then
			bar = table.remove(pool, 1)
		else
			bar = CreateFrame("Statusbar", nil, self.frame)
			bar:SetStatusBarTexture(t.texture)
			bar:SetMinMaxValues(0, 100)
			bar:SetPoint("LEFT", 1, 0)
			bar:SetPoint("RIGHT", - 1, 0)
			bar:EnableMouse(true)
			bar:Hide()

			bar:SetScript("OnEnter", self.OnEnter)
			bar:SetScript("OnLeave", function(self) tip:Hide(); self.tip = false end)

			local bg = bar:CreateTexture(nil, "BACKGROUND")
			bg:SetTexture(self.texture)
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
			right:SetPoint("RIGHT", self.frame, "RIGHT", - 5, 0)
			right:SetPoint("TOP")
			right:SetPoint("BOTTOM")
			right:SetJustifyH("RIGHT")
			right:SetShadowColor(0, 0, 0, 0.8)
			right:SetShadowOffset(0.8, - 0.8)

			bar.right = right
		end

		local col = t.color

		if not col then
			local unit = fiend:GetUnit(guid)
			local class = select(2, GetPlayerInfoByGUID(guid)) or "WARRIOR"
			col = RAID_CLASS_COLORS[class]
		end

		bar:SetHeight(size)
		bar:SetStatusBarColor(col.r, col.g, col.b)
		bar.bg:SetVertexColor(col.r, col.g, col.b, 0.1)

		bar.left:SetText(name)
		bar.right:SetText(0)

		bar.guid = guid
		bar.parent = t
		bar.total = 0
		bar.pos = 0

		table.insert(self.bars, bar)
		rawset(s, guid, bar)

		bar:Hide()

		return bar
	end})

	--[[
	local drop = fiend.dropDown

	local menu = {
		text = name,
		owner = drop,
		func = function(self)
			self.displays[title]:Activate()
		end,
	}

	fiend.menu[1][3].menuList[#fiend.menu[1][3].menuList + 1] = menu

	if fiend.dropDown:IsShown() then
		UIDropDownMenu_Refresh(fiend.dropDown)
	end
	]]

	self.views[title] = t

	return t
end
