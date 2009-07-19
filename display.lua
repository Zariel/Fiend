local fiend = _G.Fiend

local texture = [[Interface\Addons\Fiend\media\HalV.tga]]

local tip = GameTooltip
local OnEnter = function(self)
	if self:IsShown() and self.pos > 0 then
		tip:SetOwner(self, "ANCHOR_LEFT")
		tip:AddLine(self.pos .. ". " .. self.guid, self.col.r, self.col.g, self.col.b)
		tip:AddDoubleLine(self.total, "(" .. math.floor(self.total / self.parent.total * 100) .. "%)", 1, 1, 1, 1, 1, 1)
		tip:Show()
	end
end

local pool = setmetatable({}, { __mode = "k" })
local Display = setmetatable({}, {
	__call = function(self, title, size, bg)
		if not fiend.displays[guid] then
			local t = setmetatable({}, { __index = self } )

			fiend.displayCount = fiend.displayCount + 1

			t.bars = {}
			t.max = 0
			t.isActive = false
			t.size = size
			t.title = title
			t.total = 0
			t.bg = bg

			t.guids = setmetatable({}, { __index = function(self, guid)
				local bar
				if next(pool) then
					bar = table.remove(pool, 1)
				else
					bar = CreateFrame("Statusbar", nil, fiend.frame)
					bar:SetStatusBarTexture(texture)
					bar:SetMinMaxValues(0, 100)
					bar:SetPoint("LEFT")
					bar:SetPoint("RIGHT")
					bar:EnableMouse(true)

					bar:SetScript("OnEnter", OnEnter)
					bar:SetScript("OnLeave", function(self) tip:Hide() end)

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
					right:SetFont(STANDARD_TEXT_FONT, 14)
					right:SetPoint("RIGHT", fiend.frame, "RIGHT", - 5, 0)
					right:SetPoint("TOP")
					right:SetPoint("BOTTOM")
					right:SetJustifyH("RIGHT")
					right:SetShadowColor(0, 0, 0, 0.8)
					right:SetShadowOffset(0.8, - 0.8)

					bar.right = right
				end

				local class = select(2, UnitClass(guid)) or "WARRIOR"
				local col = RAID_CLASS_COLORS[class]
				local name = UnitName(self:GetUnit(guid))

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

				table.insert(t.bars, bar)
				self[guid] = bar

				bar:Hide()

				return bar
			end})

			fiend.displays[title] = t
		end

		return fiend.displays[title]
end})

function Display:Update(guid, ammount)
	local bar = self.guids[guid]

	bar.total = bar.total + ammount
	self.total = self.total + ammount

	--bar.per = math.floor(bar.total / self.parent.bars[1].total * 100)

	bar.right:SetText(bar.total)

	self.dirty = true
end

function Display:UpdateDisplay()
	if not self.isActive or #self.bars == 0 then return end

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

				bar.left:SetText(i .. ". " .. bar.guid)

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

		table.insert(pool, bar)
	end

	self.total = 0
end

function Display:Resizing()
	local total = math.floor((fiend.frame:GetHeight() - 32) / self.size)

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

	fiend.frame.title:SetText(self.title)
	fiend.frame:SetBackdropBorderColor(unpack(self.bg))

	fiend.currentDisplay = self

	self.isActive = true
	self.dirty = true
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

	output("Fiend " .. self.title)
	for i = 1, count or #self.bars do
		if not self.bars[i] then break end
		output(i .. ". " .. self.bars[i].guid .. "" .. self.bars[i].total)
	end
end

fiend.Display = Display
