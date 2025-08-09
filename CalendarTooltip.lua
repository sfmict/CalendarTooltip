local addon, ns = ...
local iconStr = "|T%s:18:18:0:0:128:128:0:91:0:91|t "
local iconStrCustom = "|T%s:18|t "
--local iconLockOut = "|T198873:18|t "
local iconLockOut = "|T340023:18:18:2:0:32:32:0:28:0:28|t "
local noIcon = "|TInterface/Icons/INV_Misc_QuestionMark:18|t "
local calendar = CreateFrame("FRAME", "CalendarTooltipAddon")
local titleR, titleG, titleB, dstr, hstr, mstr


local CALENDAR_EVENTTYPE_TEXTURES = {
	[Enum.CalendarEventType.Raid] = "|TInterface\\LFGFrame\\LFGIcon-Raid:18|t ",
	[Enum.CalendarEventType.Dungeon] = "|TInterface\\LFGFrame\\LFGIcon-Dungeon:18|t ",
	[Enum.CalendarEventType.PvP] = "|TInterface\\Calendar\\UI-Calendar-Event-PVP:18|t ",
	[Enum.CalendarEventType.Meeting] = "|TInterface\\Calendar\\MeetingIcon:18|t ",
	[Enum.CalendarEventType.Other] = "|TInterface\\Calendar\\UI-Calendar-Event-Other:18|t ",
}
calendar.isMainline = WOW_PROJECT_MAINLINE == WOW_PROJECT_ID
calendar.FILTER_CVARS = {
	calendar.isMainline and "calendarShowHolidays" or "calendarShowResets",
	"calendarShowDarkmoon",
	"calendarShowLockouts",
	"calendarShowWeeklyHolidays",
	"calendarShowBattlegrounds",
}


calendar:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)
calendar:RegisterEvent("ADDON_LOADED")


function calendar:ADDON_LOADED(addonName)
	if addonName ~= addon then return end
	self:UnregisterEvent("ADDON_LOADED")
	self.ADDON_LOADED = nil

	CalendarTooltipDB = CalendarTooltipDB or {}
	self.db = CalendarTooltipDB
	self.db.previousDays = self.db.previousDays or 3
	self.db.followingDays = self.db.followingDays or 6

	if self.db.showFuture == nil then
		self.db.showFuture = true
	end
	if self.db.showPast == nil then
		self.db.showPast = true
	end

	for i, cvar in ipairs(self.FILTER_CVARS) do
		if self.db[cvar] == nil then
			self.db[cvar] = true
		end
	end

	self.db.titleColor = self.db.titleColor or self:getDefColor("titleColor")
	self.db.dateColor = self.db.dateColor or self:getDefColor("dateColor")
	self.db.timeColor = self.db.timeColor or self:getDefColor("timeColor")
	self.db.timeDayColor = self.db.timeDayColor or self:getDefColor("timeDayColor")
	self.db.pastColor = self.db.pastColor or self:getDefColor("pastColor")
	self.db.ongoingColor = self.db.ongoingColor or self:getDefColor("ongoingColor")
	self.db.futureColor = self.db.futureColor or self:getDefColor("futureColor")

	self.eventType = {"showPast", nil, "showFuture"}
	self.list = {}
	self.filterBackup = {}
	self:setColors()
end


function calendar:getDefColor(value)
	if value == "titleColor" or value == "timeColor" then
		return "ffd200"
	elseif value == "dateColor" then
		return "80b5fd"
	elseif value == "timeDayColor" then
		return "ff732b"
	elseif value == "pastColor" then
		return "808080"
	elseif value == "ongoingColor" then
		return "eeeeee"
	elseif value == "futureColor" then
		return "80b5fd"
	end
end


function calendar:getRGBColor(hex)
	return ExtractColorValueFromHex(hex, 1), ExtractColorValueFromHex(hex, 3), ExtractColorValueFromHex(hex, 5)
end


function calendar:setColors()
	titleR, titleG, titleB = self:getRGBColor(self.db.titleColor)
	self.dateColor1 = "|cff"..self.db.dateColor.."%s - %s|r"
	self.dateColor2 = "|cff"..self.db.dateColor.."%s %s|r"
	local day = DAY_ONELETTER_ABBR:gsub(" ", "")
	local hour = HOUR_ONELETTER_ABBR:gsub(" ", "")
	local minute = MINUTE_ONELETTER_ABBR:gsub(" ", "")
	dstr = ("|cff%s%s %s|r |cff808080|||r "):format(self.db.timeColor, day, hour)
	hstr = ("|cff%s%s %s|r |cff808080|||r "):format(self.db.timeDayColor, hour, minute)
	mstr = ("|cff%s%s|r |cff808080|||r "):format(self.db.timeDayColor, minute)
	self[1] = "|cff"..self.db.pastColor.."%s|r"
	self[2] = "|cff"..self.db.ongoingColor.."%s|r"
	self[3] = "|cff"..self.db.futureColor.."%s|r"
end


function calendar:setBackup()
	self.isUpdating = true

	self.dateBackup = C_Calendar.GetMonthInfo()
	if CalendarFrame then
		CalendarFrame:UnregisterEvent("CALENDAR_UPDATE_EVENT_LIST")
		CalendarEventPickerFrame:UnregisterEvent("CALENDAR_UPDATE_EVENT_LIST")
	end

	local backup = self.filterBackup
	for i, cvar in ipairs(self.FILTER_CVARS) do
		backup[cvar] = GetCVar(cvar)
		SetCVar(cvar, self.db[cvar])
	end
end


function calendar:restoreBackup()
	local backup = self.filterBackup
	for i, cvar in ipairs(self.FILTER_CVARS) do
		SetCVar(cvar, backup[cvar])
	end

	C_Calendar.SetAbsMonth(self.dateBackup.month, self.dateBackup.year)
	if CalendarFrame then
		CalendarFrame:RegisterEvent("CALENDAR_UPDATE_EVENT_LIST")
		CalendarEventPickerFrame:RegisterEvent("CALENDAR_UPDATE_EVENT_LIST")
	end

	self.isUpdating = false
end


local getCalendarTime do
	local t = {}
	function getCalendarTime(eTime)
		t.year = eTime.year
		t.month = eTime.month
		t.day = eTime.monthDay
		t.hour = eTime.hour
		t.min = eTime.minute
		return time(t)
	end
end


local function getEventKey(e)
	local st = e.startTime
	return ("%s:%d%.2d%.2d"):format(e.eventID, st.year, st.month, st.monthDay)
end


function getFormatTime(tstmp)
	local d,h,m = ChatFrame_TimeBreakDown(tstmp)
	if d > 0 then
		return dstr:format(d,h)
	elseif h > 0 then
		return hstr:format(h,m)
	else
		return mstr:format(m)
	end
end


function calendar:updateEventAttr(e)
	local startDate = FormatShortDate(e.startTime.monthDay, e.startTime.month)
	if e.calendarType == "HOLIDAY" then
		e.title = self[e.order]:format(e.title)
		local endDate = FormatShortDate(e.endTime.monthDay, e.endTime.month)
		e.dateStr = self.dateColor1:format(startDate, endDate)
	else
		if e.difficultyName == nil or e.difficultyName == "" then
			e.title = self[e.order]:format(e.title)
		else
			e.title = self[e.order]:format(DUNGEON_NAME_WITH_DIFFICULTY:format(e.title, e.difficultyName))
		end

		if (e.calendarType == "GUILD_EVENT" or e.calendarType == "COMMUNITY_EVENT")
		and e.inviteType == Enum.CalendarInviteType.Signup
		then
			local inviteInfo = CalendarUtil.GetCalendarInviteStatusInfo(e.inviteStatus)
			e.title = e.title.." "..inviteInfo.color:WrapTextInColorCode("("..inviteInfo.name..")")
		end

		local startTime = GameTime_GetFormattedTime(e.startTime.hour, e.startTime.minute, true)
		e.dateStr = self.dateColor2:format(startDate, startTime)
	end
end


function calendar:setEventList(day, order)
	for i = 1, C_Calendar.GetNumDayEvents(0, day) do
		local e = C_Calendar.GetDayEvent(0, day, i)
		local k = getEventKey(e)
		local ce = self.list[k]

		if ce == nil then
			local eInfo = C_Calendar.GetHolidayInfo(0, day, i)
			e.icon = eInfo and eInfo.texture or e.iconTexture

			e.st = getCalendarTime(e.startTime)
			if e.calendarType == "HOLIDAY" then
				e.et = getCalendarTime(e.endTime)
			else
				e.et = e.st
			end

			if order ~= 2 then
				e.order = order
				if order == 3 then
					e.t = e.st
				end
			elseif e.sequenceType == "ONGOING" then
					e.t = e.et
					e.order = order
			elseif e.sequenceType == "START" then
				if e.st > self.curTime then
					e.t = e.st
					e.order = 3
				else
					e.t = e.et
					e.order = order
				end
			elseif e.sequenceType == "END" then
				if e.et > self.curTime then
					e.t = e.et
					e.order = order
				else
					e.order = 1
				end
			elseif e.calendarType == "HOLIDAY" then
				e.t = e.et
				e.order = order
			else
				if e.st > self.curTime then
					e.t = e.st
					e.order = 3
				else
					e.order = 1
				end
			end

			if e.t and e.t < self.timeToEvent then
				self.timeToEvent = e.t
			end

			if self.db.showID then
				e.title = e.title.." |cff808080("..e.eventID..")|r"
			end

			self:updateEventAttr(e)
			self.list[#self.list + 1] = e
			self.list[k] = e

		elseif ce.sequenceType == "ONGOING" and e.sequenceType ~= "ONGOING" then
			ce.icon = C_Calendar.GetHolidayInfo(0, day, i).texture
		elseif ce.icon == nil and e.iconTexture ~= nil then
			ce.icon = e.iconTexture
		end
	end
end


function calendar:setEventListRange(offset, startDay, endDay, order)
	local month = self.date.month + offset
	local year = self.date.year

	if month < 1 then
		month = 12
		year = year - 1
	elseif month > 12 then
		month = 1
		year = year + 1
	end

	C_Calendar.SetAbsMonth(month, year)
	for day = startDay, endDay do self:setEventList(day, order) end
end


function calendar:updateList()
	self.timeToEvent = math.huge
	self.date = C_DateAndTime.GetCurrentCalendarTime()
	self.curTime = getCalendarTime(self.date)
	local day = self.date.monthDay
	wipe(self.list)

	self:setBackup()

	-- current
	C_Calendar.SetAbsMonth(self.date.month, self.date.year)
	self:setEventList(day, 2)

	-- before
	local beforeDay = day - self.db.previousDays
	if beforeDay < 1 then
		local numDays = C_Calendar.GetMonthInfo(-1).numDays
		self:setEventListRange(-1, numDays + beforeDay, numDays, 1)
		beforeDay = 1
	end
	self:setEventListRange(0, beforeDay, day - 1, 1)

	-- after
	local afterDay = day + self.db.followingDays
	local numDays = C_Calendar.GetMonthInfo().numDays
	if afterDay > numDays then
		self:setEventListRange(0, day + 1, numDays, 3)
		self:setEventListRange(1, 1, afterDay - numDays, 3)
	else
		self:setEventListRange(0, day + 1, afterDay, 3)
	end

	self:restoreBackup()

	-- sort
	sort(self.list, function(a, b)
		if a.order ~= b.order then return a.order < b.order end
		if a.order == 3 then
			if a.st ~= b.st then return a.st < b.st end
			if a.et ~= b.et then return a.et < b.et end
		else
			if a.et ~= b.et then return a.et < b.et end
			if a.st ~= b.st then return a.st < b.st end
		end
		if a.title ~= b.title then return a.title < b.title end
		return a.eventID < b.eventID
	end)
end


function calendar:setTooltip()
	local date = C_DateAndTime.GetCurrentCalendarTime()
	local curTime = getCalendarTime(date)

	if self.timeToEvent <= curTime then
		self:updateList()
	end

	GameTooltip:ClearLines()
	GameTooltip:AddDoubleLine(EVENTS_LABEL, FormatShortDate(date.monthDay, date.month, date.year).." "..GameTime_GetFormattedTime(date.hour, date.minute, true), titleR, titleG, titleB, titleR, titleG, titleB)
	GameTooltip:AddLine(" ")

	local num, icon, order = 0
	for i = 1, #self.list do
		local e = self.list[i]
		if e.order == 2 or self.db[self.eventType[e.order]] then
			num = num + 1

			if e.icon then
				icon = (e.calendarType == "HOLIDAY" and iconStr or iconStrCustom):format(e.icon)
			elseif e.calendarType == "RAID_LOCKOUT" then
				icon = iconLockOut
			elseif e.calendarType ~= "HOLIDAY" then
				icon = CALENDAR_EVENTTYPE_TEXTURES[e.eventType]
			else
				icon = noIcon
			end

			if order ~= e.order then
				if order ~= nil then GameTooltip:AddLine(" ") end
				order = e.order
			end
			GameTooltip:AddDoubleLine(icon..e.title, e.t and getFormatTime(e.t - curTime)..e.dateStr or e.dateStr)
		end
	end

	if num == 0 then
		GameTooltip:AddLine(EMPTY, .5,.5,.5)
	end

	GameTooltip:Show()
end


function calendar:CALENDAR_UPDATE_EVENT_LIST()
	if self.isUpdating then return end
	self:updateList()
	self:setTooltip()
end


function calendar:onEnter()
	self:RegisterEvent("CALENDAR_UPDATE_EVENT_LIST")
	self:updateList()
	C_Calendar.OpenCalendar()
end


function calendar:onLeave()
	self:UnregisterEvent("CALENDAR_UPDATE_EVENT_LIST")
end


GameTimeFrame:HookScript("OnEnter", function() calendar:onEnter() end)
GameTimeFrame:HookScript("OnLeave", function() calendar:onLeave() end)
GameTimeFrame:HookScript("OnUpdate", function(self)
	if GameTooltip:IsOwned(self) then
		calendar:setTooltip()
	end
end)