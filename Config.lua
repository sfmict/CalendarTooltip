local addon, ns = ...
local L = ns.L
local calendar = CalendarTooltipAddon
calendar:Hide()


calendar:SetScript("OnShow", function(self)
	self:SetScript("OnShow", function(self)
		self:SetPoint("TOPLEFT", -12, 8)
		self:refreshConfig()
	end)
	self:SetPoint("TOPLEFT", -12, 8)

	-- ADDON INFO
	local info = self:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	info:SetPoint("TOPLEFT", 40, 20)
	info:SetTextColor(.5, .5, .5, 1)
	info:SetJustifyH("RIGHT")
	info:SetText(("%s %s: %s"):format(C_AddOns.GetAddOnMetadata(addon, "Version"), L["author"], C_AddOns.GetAddOnMetadata(addon, "Author")))

	-- TITLE
	local title = self:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 16, -16)
	title:SetJustifyH("LEFT")
	title:SetText(L["%s Configuration"]:format(addon))

	local checkbox_OnClick = function(btn) self.db[btn.value] = btn:GetChecked() end
	local function createCheckbox(text, value)
		local btn = CreateFrame("CheckButton", nil, self, "CalendarTooltipCheckButtonTemplate")
		btn.Text:SetText(text)
		btn.value = value
		btn:HookScript("OnClick", checkbox_OnClick)
		return btn
	end

	-- CVARS
	local cvars = {
		self.isMainline and CALENDAR_FILTER_HOLIDAYS or CALENDAR_FILTER_RAID_RESETS,
		CALENDAR_FILTER_DARKMOON,
		CALENDAR_FILTER_RAID_LOCKOUTS,
		CALENDAR_FILTER_WEEKLY_HOLIDAYS,
		CALENDAR_FILTER_BATTLEGROUND,
	}
	local maxWidth = 0

	for i, cvar in ipairs(self.FILTER_CVARS) do
		local btn = createCheckbox(cvars[i], cvar)
		if i == 1 then
			btn:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -30)
		else
			btn:SetPoint("TOPLEFT", cvars[i-1], "BOTTOMLEFT")
		end
		maxWidth = math.max(maxWidth, btn.Text:GetWidth())
		cvars[i] = btn
	end

	-- PAST
	local past = createCheckbox(L["Show Past"], "showPast")
	past:SetPoint("LEFT", cvars[1], "RIGHT", maxWidth + 40, 0)

	-- FUTURE
	local future = createCheckbox(L["Show Future"], "showFuture")
	future:SetPoint("TOPLEFT", past, "BOTTOMLEFT")

	-- SHOW ID
	local showID = createCheckbox(L["Show ID"], "showID")
	showID:SetPoint("TOPLEFT", future, "BOTTOMLEFT")

	-- PAST DAYS
	local pastSlider = CreateFrame("SLIDER", nil, self, "CalendarTooltipSliderTemplate")
	pastSlider:SetPoint("TOPLEFT", cvars[#cvars], "BOTTOMLEFT", 0, -30)
	pastSlider.text:SetText(L["Past Days"])
	pastSlider.RightText:Show()
	pastSlider.OnSliderValueChanged = function(btn, value)
		self.db.previousDays = value
		btn.RightText:SetText(value)
	end
	pastSlider:RegisterCallback(MinimalSliderWithSteppersMixin.Event.OnValueChanged, pastSlider.OnSliderValueChanged, pastSlider)

	-- FUTURE DAYS
	local futureSlider = CreateFrame("SLIDER", nil, self, "CalendarTooltipSliderTemplate")
	futureSlider:SetPoint("TOPLEFT", pastSlider, "BOTTOMLEFT", 0, -15)
	futureSlider.text:SetText(L["Future Days"])
	futureSlider.RightText:Show()
	futureSlider.OnSliderValueChanged = function(btn, value)
		self.db.followingDays = value
		btn.RightText:SetText(value)
	end
	futureSlider:RegisterCallback(MinimalSliderWithSteppersMixin.Event.OnValueChanged, futureSlider.OnSliderValueChanged, futureSlider)

	-- COLORS
	local function getHexColor(r,g,b)
		return ("%.2x%.2x%.2x"):format(Round(r * 255), Round(g * 255), Round(b * 255))
	end

	local function color_OnClick(btn)
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		btn.r, btn.g, btn.b = self:getRGBColor(self.db[btn.value])
		ColorPickerFrame:SetupColorPickerAndShow(btn)
	end

	local function createSwatchBtn(value)
		local btn =  CreateFrame("BUTTON", nil, self)
		btn:SetSize(30, 30)
		btn.text = btn:CreateFontString(nil, "ARTWORK", "GameFontHighlightLeft")
		btn.text:SetPoint("LEFT", btn, "RIGHT")
		btn.text:SetText(L[value])
		btn:SetNormalTexture("Interface/ChatFrame/ChatFrameColorSwatch")
		btn.normalTex = btn:GetNormalTexture()
		btn.value = value
		btn:SetScript("OnClick", color_OnClick)
		btn.swatchFunc = function()
			local r,g,b = ColorPickerFrame:GetColorRGB()
			btn.normalTex:SetVertexColor(r,g,b)
			self.db[value] = getHexColor(r,g,b)
			self:setColors()
		end
		btn.cancelFunc = function(color)
			btn.normalTex:SetVertexColor(color.r, color.g, color.b)
			self.db[value] = getHexColor(color.r, color.g, color.b)
			self:setColors()
		end
		return btn
	end

	local titleColor = createSwatchBtn("titleColor")
	titleColor:SetPoint("TOPLEFT", futureSlider, "BOTTOMLEFT", 0, -30)

	local dateColor = createSwatchBtn("dateColor")
	dateColor:SetPoint("TOPLEFT", titleColor, "BOTTOMLEFT")

	local timeColor = createSwatchBtn("timeColor")
	timeColor:SetPoint("TOPLEFT", dateColor, "BOTTOMLEFT")

	local timeDayColor = createSwatchBtn("timeDayColor")
	timeDayColor:SetPoint("TOPLEFT", timeColor, "BOTTOMLEFT")

	local colorWidth = math.max(titleColor.text:GetWidth(), dateColor.text:GetWidth(), timeColor.text:GetWidth(), timeDayColor.text:GetWidth())

	local pastColor = createSwatchBtn("pastColor")
	pastColor:SetPoint("LEFT", titleColor, "RIGHT", colorWidth + 40, 0)

	local ongoingColor = createSwatchBtn("ongoingColor")
	ongoingColor:SetPoint("TOPLEFT", pastColor, "BOTTOMLEFT")

	local futureColor = createSwatchBtn("futureColor")
	futureColor:SetPoint("TOPLEFT", ongoingColor, "BOTTOMLEFT")

	-- RESET COLORS
	local resetButton = CreateFrame("BUTTON", nil, self, "UIPanelButtonTemplate")
	resetButton:SetPoint("TOPLEFT", timeDayColor, "BOTTOMLEFT", 0, -10)
	resetButton:SetText(L["Reset Colors"])
	resetButton:SetWidth(resetButton:GetFontString():GetStringWidth() + 20)
	resetButton:SetScript("OnClick", function()
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		self.db.titleColor = self:getDefColor("titleColor")
		self.db.dateColor = self:getDefColor("dateColor")
		self.db.timeColor = self:getDefColor("timeColor")
		self.db.timeDayColor = self:getDefColor("timeDayColor")
		self.db.pastColor = self:getDefColor("pastColor")
		self.db.ongoingColor = self:getDefColor("ongoingColor")
		self.db.futureColor = self:getDefColor("futureColor")
		self:setColors()
		self:refreshConfig()
	end)

	-- REFRESH
	function self:refreshConfig()
		for i, btn in ipairs(cvars) do
			btn:SetChecked(self.db[btn.value])
		end

		past:SetChecked(self.db[past.value])
		future:SetChecked(self.db[future.value])
		showID:SetChecked(self.db[showID.value])

		local pastOptions = Settings.CreateSliderOptions(0, 28, 1)
		pastSlider:Init(self.db.previousDays, pastOptions.minValue, pastOptions.maxValue, pastOptions.steps, pastOptions.formatters)
		pastSlider.RightText:SetText(self.db.previousDays)

		local futureOptions = Settings.CreateSliderOptions(0, 28, 1)
		futureSlider:Init(self.db.followingDays, futureOptions.minValue, futureOptions.maxValue, futureOptions.steps, futureOptions.formatters)
		futureSlider.RightText:SetText(self.db.followingDays)

		titleColor.normalTex:SetVertexColor(self:getRGBColor(self.db.titleColor))
		dateColor.normalTex:SetVertexColor(self:getRGBColor(self.db.dateColor))
		timeColor.normalTex:SetVertexColor(self:getRGBColor(self.db.timeColor))
		timeDayColor.normalTex:SetVertexColor(self:getRGBColor(self.db.timeDayColor))
		pastColor.normalTex:SetVertexColor(self:getRGBColor(self.db.pastColor))
		ongoingColor.normalTex:SetVertexColor(self:getRGBColor(self.db.ongoingColor))
		futureColor.normalTex:SetVertexColor(self:getRGBColor(self.db.futureColor))
	end
	self:refreshConfig()
end)


-- ADD CATEGORY
local category, layout = Settings.RegisterCanvasLayoutCategory(calendar, addon)
Settings.RegisterAddOnCategory(category)


-- OPEN CONFIG
function calendar:openConfig()
	if SettingsPanel:IsVisible() and self:IsVisible() then
		if InCombatLockdown() then return end
		HideUIPanel(SettingsPanel)
	else
		Settings.OpenToCategory(category:GetID(), addon)
	end
end


SLASH_CALENDARTOOLTIPCONFIG1 = "/calendartooltip"
SLASH_CALENDARTOOLTIPCONFIG2 = "/ct"
SlashCmdList["CALENDARTOOLTIPCONFIG"] = function() calendar:openConfig() end


-- DATA BROKER
calendar:RegisterEvent("PLAYER_LOGIN")
function calendar:PLAYER_LOGIN()
	self:UnregisterEvent("PLAYER_LOGIN")
	self.PLAYER_LOGIN = nil
	local ldb = LibStub and LibStub("LibDataBroker-1.1", true)
	if ldb then
		local updateFrame = CreateFrame("FRAME")
		updateFrame:Hide()
		updateFrame:SetScript("OnUpdate", function() calendar:setTooltip() end)

		local data = {
			type = "data source",
			text = addon,
			OnClick = function(_, button)
				if button == "RightButton" then
					calendar:openConfig()
				elseif not InCombatLockdown() then
					ToggleCalendar()
				end
			end,
			OnLeave = function()
				updateFrame:Hide()
				calendar:onLeave()
				GameTooltip:Hide()
			end,
		}

		if calendar.isMainline then
			local iconCoords = {}
			local function getTexCoord()
				local day = C_DateAndTime.GetCurrentCalendarTime().monthDay
				if day ~= updateFrame.day then
					updateFrame.day = day
					local atlasInfo = C_Texture.GetAtlasInfo("ui-hud-calendar-"..day.."-up")
					iconCoords[1] = atlasInfo.leftTexCoord
					iconCoords[2] = atlasInfo.rightTexCoord - 4/256
					iconCoords[3] = atlasInfo.topTexCoord
					iconCoords[4] = atlasInfo.bottomTexCoord - 4/256
				end
				return iconCoords
			end

			data.icon = 4618663
			data.iconCoords = getTexCoord()
			data.OnEnter = function(self)
				calendar.ldbButton.iconCoords = getTexCoord()
				GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
				GameTooltip:AddLine(" ")
				GameTooltip:Show()
				calendar:onEnter()
				updateFrame:Show()
			end
		else
			data.icon = 235489
			data.iconCoords = {0, .390625, 0, .78125}
			data.OnEnter = function(self)
				GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
				GameTooltip:AddLine(" ")
				GameTooltip:Show()
				calendar:onEnter()
				updateFrame:Show()
			end
		end

		self.ldbButton = ldb:NewDataObject(addon, data)
	end
end