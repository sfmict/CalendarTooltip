local addon, ns = ...
local L = ns.L
local calendar = CalendarTooltipAddon
calendar:Hide()


calendar:SetScript("OnShow", function(self)
	self:SetScript("OnShow", function(self)
		self:SetPoint("TOPLEFT", -12, 8)
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

	-- HOLIDAYS
	local holidays = CreateFrame("CheckButton", nil, self, "CalendarTooltipCheckButtonTemplate")
	holidays:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -30)
	holidays:SetChecked(self.db.calendarShowHolidays)
	holidays.Text:SetText(CALENDAR_FILTER_HOLIDAYS)
	holidays:HookScript("OnClick", function(btn)
		self.db.calendarShowHolidays = btn:GetChecked()
	end)

	-- DARKMOON
	local darkmoon = CreateFrame("CheckButton", nil, self, "CalendarTooltipCheckButtonTemplate")
	darkmoon:SetPoint("TOPLEFT", holidays, "BOTTOMLEFT", 0, 0)
	darkmoon:SetChecked(self.db.calendarShowDarkmoon)
	darkmoon.Text:SetText(CALENDAR_FILTER_DARKMOON)
	darkmoon:HookScript("OnClick", function(btn)
		self.db.calendarShowDarkmoon = btn:GetChecked()
	end)

	-- RAID LOCKOUT
	local raidLockout = CreateFrame("CheckButton", nil, self, "CalendarTooltipCheckButtonTemplate")
	raidLockout:SetPoint("TOPLEFT", darkmoon, "BOTTOMLEFT", 0, 0)
	raidLockout:SetChecked(self.db.calendarShowLockouts)
	raidLockout.Text:SetText(CALENDAR_FILTER_RAID_LOCKOUTS)
	raidLockout:HookScript("OnClick", function(btn)
		self.db.calendarShowLockouts = btn:GetChecked()
	end)

	-- WEEKLY HOLIDAYS
	local weeklyHolidays = CreateFrame("CheckButton", nil, self, "CalendarTooltipCheckButtonTemplate")
	weeklyHolidays:SetPoint("TOPLEFT", raidLockout, "BOTTOMLEFT", 0, 0)
	weeklyHolidays:SetChecked(self.db.calendarShowWeeklyHolidays)
	weeklyHolidays.Text:SetText(CALENDAR_FILTER_WEEKLY_HOLIDAYS)
	weeklyHolidays:HookScript("OnClick", function(btn)
		self.db.calendarShowWeeklyHolidays = btn:GetChecked()
	end)

	-- BATTLEGROUND
	local battleground = CreateFrame("CheckButton", nil, self, "CalendarTooltipCheckButtonTemplate")
	battleground:SetPoint("TOPLEFT", weeklyHolidays, "BOTTOMLEFT", 0, 0)
	battleground:SetChecked(self.db.calendarShowBattlegrounds)
	battleground.Text:SetText(CALENDAR_FILTER_BATTLEGROUND)
	battleground:HookScript("OnClick", function(btn)
		self.db.calendarShowBattlegrounds = btn:GetChecked()
	end)

	local maxWidth = math.max(holidays.Text:GetWidth(), darkmoon.Text:GetWidth(), raidLockout.Text:GetWidth(), weeklyHolidays.Text:GetWidth(), battleground.Text:GetWidth())

	-- PAST
	local past = CreateFrame("CheckButton", nil, self, "CalendarTooltipCheckButtonTemplate")
	past:SetPoint("LEFT", holidays, "RIGHT", maxWidth + 40, 0)
	past:SetChecked(self.db.showPast)
	past.Text:SetText(L["Show Past"])
	past:HookScript("OnClick", function(btn)
		self.db.showPast = btn:GetChecked()
	end)

	-- FUTURE
	local future = CreateFrame("CheckButton", nil, self, "CalendarTooltipCheckButtonTemplate")
	future:SetPoint("TOPLEFT", past, "BOTTOMLEFT", 0, 0)
	future:SetChecked(self.db.showFuture)
	future.Text:SetText(L["Show Future"])
	future:HookScript("OnClick", function(btn)
		self.db.showFuture = btn:GetChecked()
	end)

	-- PAST DAYS
	local pastSlider = CreateFrame("SLIDER", nil, self, "CalendarTooltipSliderTemplate")
	pastSlider:SetPoint("TOPLEFT", battleground, "BOTTOMLEFT", 0, -30)
	pastSlider.text:SetText(L["Past Days"])
	pastSlider.RightText:Show()
	pastSlider.OnSliderValueChanged = function(btn, value)
		self.db.previousDays = value
		btn.RightText:SetText(value)
	end
	pastSlider:RegisterCallback(MinimalSliderWithSteppersMixin.Event.OnValueChanged, pastSlider.OnSliderValueChanged, pastSlider)
	local pastOptions = Settings.CreateSliderOptions(0, 28, 1)
	pastSlider:Init(self.db.previousDays, pastOptions.minValue, pastOptions.maxValue, pastOptions.steps, pastOptions.formatters)
	pastSlider.RightText:SetText(self.db.previousDays)

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
	local futureOptions = Settings.CreateSliderOptions(0, 28, 1)
	futureSlider:Init(self.db.followingDays, futureOptions.minValue, futureOptions.maxValue, futureOptions.steps, futureOptions.formatters)
	futureSlider.RightText:SetText(self.db.followingDays)
end)


-- ADD CATEGORY
local category, layout = Settings.RegisterCanvasLayoutCategory(calendar, addon)
category.ID = addon
Settings.RegisterAddOnCategory(category)


-- OPEN CONFIG
function calendar:openConfig()
	if SettingsPanel:IsVisible() and self:IsVisible() then
		if InCombatLockdown() then return end
		HideUIPanel(SettingsPanel)
	else
		Settings.OpenToCategory(addon, true)
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
	local ldb = LibStub("LibDataBroker-1.1", true)
	if ldb then
		local updateFrame = CreateFrame("FRAME")
		updateFrame:Hide()
		updateFrame:SetScript("OnUpdate", function() calendar:setTooltip() end)

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

		self.ldbButton = ldb:NewDataObject(addon, {
			type = "data source",
			text = addon,
			icon = 4618663,
			iconCoords = getTexCoord(),
			OnClick = function(_, button)
				if button == "RightButton" then
					calendar:openConfig()
				elseif not InCombatLockdown() then
					ToggleCalendar()
				end
			end,
			OnEnter = function(self)
				calendar.ldbButton.iconCoords = getTexCoord()
				calendar:RegisterEvent("CALENDAR_UPDATE_EVENT_LIST")
				calendar:updateList()
				C_Calendar.OpenCalendar()
				GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
				calendar:setTooltip()
				GameTooltip:Show()
				updateFrame:Show()
			end,
			OnLeave = function()
				calendar:UnregisterEvent("CALENDAR_UPDATE_EVENT_LIST")
				updateFrame:Hide()
				GameTooltip:Hide()
			end,
		})
	end
end