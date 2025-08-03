local addon, ns = ...
local iconStr = "|T%s:18:18:0:0:128:128:0:91:0:91|t "
local iconStrCustom = "|T%s:18|t "
--local noIcon = "|TInterface/Icons/INV_Misc_QuestionMark:18|t "
local noIcon = "|T235490:18|t "
local calendar = CreateFrame("FRAME", "CalendarTooltipAddon")


local CALENDAR_EVENTTYPE_TEXTURES = {
	[Enum.CalendarEventType.Raid] = "|TInterface\\LFGFrame\\LFGIcon-Raid:18|t ",
	[Enum.CalendarEventType.Dungeon] = "|TInterface\\LFGFrame\\LFGIcon-Dungeon:18|t ",
	[Enum.CalendarEventType.PvP] = "|TInterface\\Calendar\\UI-Calendar-Event-PVP:18|t ",
	[Enum.CalendarEventType.Meeting] = "|TInterface\\Calendar\\MeetingIcon:18|t ",
	[Enum.CalendarEventType.Other] = "|TInterface\\Calendar\\UI-Calendar-Event-Other:18|t ",
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
	if self.db.calendarShowHolidays == nil then
		self.db.calendarShowHolidays = true
	end
	if self.db.calendarShowDarkmoon == nil then
		self.db.calendarShowDarkmoon = true
	end
	if self.db.calendarShowWeeklyHolidays == nil then
		self.db.calendarShowWeeklyHolidays = true
	end
	if self.db.calendarShowBattlegrounds == nil then
		self.db.calendarShowBattlegrounds = true
	end
	if self.db.showFuture == nil then
		self.db.showFuture = true
	end
	if self.db.showPast == nil then
		self.db.showPast = true
	end

	self.eventType = {[0] = "showPast",	[2] = "showFuture"}
	self.list = {}
	self.filterBackup = {}
end


function calendar:setBackup()
	self.isUpdating = true

	local backup = self.filterBackup
	backup.calendarShowHolidays = GetCVar("calendarShowHolidays")
	backup.calendarShowDarkmoon = GetCVar("calendarShowDarkmoon")
	backup.calendarShowLockouts = GetCVar("calendarShowLockouts")
	backup.calendarShowWeeklyHolidays = GetCVar("calendarShowWeeklyHolidays")
	backup.calendarShowBattlegrounds = GetCVar("calendarShowBattlegrounds")

	self.dateBackup = C_Calendar.GetMonthInfo()
	if CalendarFrame then
		CalendarFrame:UnregisterEvent("CALENDAR_UPDATE_EVENT_LIST")
		CalendarEventPickerFrame:UnregisterEvent("CALENDAR_UPDATE_EVENT_LIST")
	end

	SetCVar("calendarShowHolidays", self.db.calendarShowHolidays)
	SetCVar("calendarShowDarkmoon", self.db.calendarShowDarkmoon)
	SetCVar("calendarShowLockouts", "0")
	SetCVar("calendarShowWeeklyHolidays", self.db.calendarShowWeeklyHolidays)
	SetCVar("calendarShowBattlegrounds", self.db.calendarShowBattlegrounds)
end


function calendar:restoreBackup()
	local backup = self.filterBackup
	SetCVar("calendarShowHolidays", backup.calendarShowHolidays)
	SetCVar("calendarShowDarkmoon", backup.calendarShowDarkmoon)
	SetCVar("calendarShowLockouts", backup.calendarShowLockouts)
	SetCVar("calendarShowWeeklyHolidays", backup.calendarShowWeeklyHolidays)
	SetCVar("calendarShowBattlegrounds", backup.calendarShowBattlegrounds)

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
	return ("%d:%d%.2d%.2d"):format(e.eventID, st.year, st.month, st.monthDay)
end


local getFormatTime do
	local minute = MINUTE_ONELETTER_ABBR:gsub(" ", "")
	local hour = HOUR_ONELETTER_ABBR:gsub(" ", "")
	local hstr = (" (%s %s)"):format(hour, minute)
	local dstr = (" (%s %s %s)"):format(DAY_ONELETTER_ABBR:gsub(" ", ""), hour, minute)
	function getFormatTime(tstmp)
		local d,h,m = ChatFrame_TimeBreakDown(tstmp)
		if d > 0 then
			return dstr:format(d,h,m)
		else
			return hstr:format(h,m)
		end
		--TIME_DAYHOURMINUTESECOND
	end
end


local function getColoredTitle(e)
	local colorStr
	if e.order == 2 then
		colorStr = "|cff80b5fd%s|r"
	elseif e.order == 1 then
		colorStr = "|cffeeeeee%s|r"
	else
		colorStr = "|cff808080%s|r"
	end
	return colorStr:format(e.title)
end


function calendar:setEventList(day, order)
	for i = 1, C_Calendar.GetNumDayEvents(0, day) do
		local e = C_Calendar.GetDayEvent(0, day, i)
		local k = getEventKey(e)

		if self.list[k] then
			if e.sequenceType ~= "ONGOING" and self.list[k].sequenceType == "ONGOING" then
				self.list[k].icon = C_Calendar.GetHolidayInfo(0, day, i).texture
			end
		else
			local eInfo = C_Calendar.GetHolidayInfo(0, day, i)
			e.icon = eInfo and eInfo.texture or e.iconTexture

			e.st = getCalendarTime(e.startTime)
			if e.calendarType == "HOLIDAY" then
				e.et = getCalendarTime(e.endTime)
			else
				e.et = e.st
			end

			if order ~= 1 then
				e.order = order
				if order == 2 then
					e.t = e.st
				end
			elseif e.sequenceType == "ONGOING" then
					e.t = e.et
					e.order = order
			elseif e.sequenceType == "START" then
				if e.st > self.curTime then
					e.t = e.st
					e.order = 2
				else
					e.t = e.et
					e.order = order
				end
			elseif e.sequenceType == "END" then
				if e.et > self.curTime then
					e.t = e.et
					e.order = order
				else
					e.order = 0
				end
			elseif e.calendarType == "HOLIDAY" then
				e.t = e.et
				e.order = order
			else
				if e.st > self.curTime then
					e.t = e.st
					e.order = 2
				else
					e.order = 0
				end
			end

			if e.t and e.t < self.timeToEvent then
				self.timeToEvent = e.t
			end

			e.title = getColoredTitle(e)

			local startDate = FormatShortDate(e.startTime.monthDay, e.startTime.month)
			if e.calendarType == "HOLIDAY" then
				local endDate = FormatShortDate(e.endTime.monthDay, e.endTime.month)
				e.dateStr = ("|cff80b5fd%s - %s|r"):format(startDate, endDate)
			else
				local inviteStatusInfo = CalendarUtil.GetCalendarInviteStatusInfo(e.inviteStatus)
				e.inviteStatusStr = " "..inviteStatusInfo.color:WrapTextInColorCode("("..inviteStatusInfo.name..")")
				e.dateStr = ("|cff80b5fd%s %s|r"):format(startDate, GameTime_GetFormattedTime(e.startTime.hour, e.startTime.minute, true))
			end

			self.list[#self.list + 1] = e
			self.list[k] = e
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
	if self.isUpdating then return end
	self.timeToEvent = math.huge
	self.date = C_DateAndTime.GetCurrentCalendarTime()
	self.curTime = getCalendarTime(self.date)
	local day = self.date.monthDay
	wipe(self.list)

	self:setBackup()

	-- current
	C_Calendar.SetAbsMonth(self.date.month, self.date.year)
	local numDays = C_Calendar.GetMonthInfo().numDays
	self:setEventList(day, 1)

	-- before
	local beforeDay = day - self.db.previousDays
	if beforeDay < 1 then
		local monthInfo = C_Calendar.GetMonthInfo(-1)
		self:setEventListRange(-1, monthInfo.numDays + beforeDay, monthInfo.numDays, 0)
		beforeDay = 1
	end
	self:setEventListRange(0, beforeDay, day - 1, 0)

	-- after
	local afterDay = day + self.db.followingDays
	if afterDay > numDays then
		local monthInfo = C_Calendar.GetMonthInfo(1)
		self:setEventListRange(1, 1, afterDay - numDays, 2)
		afterDay = numDays
	end
	self:setEventListRange(0, day + 1, afterDay, 2)

	self:restoreBackup()

	-- sort
	sort(self.list, function(a, b)
		if a.order ~= b.order then return a.order < b.order end
		if a.order == 2 then
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
	local date, order = C_DateAndTime.GetCurrentCalendarTime()
	local curTime = getCalendarTime(date)

	if self.timeToEvent - curTime < 0 then
		self:updateList()
	end

	GameTooltip:ClearLines()
	GameTooltip:AddDoubleLine(EVENTS_LABEL, FormatShortDate(date.monthDay, date.month, date.year).." "..GameTime_GetFormattedTime(date.hour, date.minute, true))
	GameTooltip:AddLine(" ")

	local num = 0
	for i = 1, #self.list do
		local e, title = self.list[i]
		if e.order == 1 or self.db[self.eventType[e.order]] then
			num = num + 1

			if e.icon then
				title = (e.calendarType == "HOLIDAY" and iconStr or iconStrCustom):format(e.icon)..e.title
			else
				title = CALENDAR_EVENTTYPE_TEXTURES[e.eventType]..e.title
			end

			if e.t then
				title = title..getFormatTime(e.t - curTime)
			end

			if e.inviteStatusStr then
				title = title..e.inviteStatusStr
			end

			if order ~= e.order then
				if order ~= nil then GameTooltip:AddLine(" ") end
				order = e.order
			end
			GameTooltip:AddDoubleLine(title, e.dateStr)
		end
	end

	if num == 0 then
		GameTooltip:AddLine(EMPTY, .5,.5,.5)
	end

	GameTooltip:Show()
end


function calendar:CALENDAR_UPDATE_EVENT_LIST()
	self:updateList()
	self:setTooltip()
end


GameTimeFrame:HookScript("OnEnter", function()
	calendar:RegisterEvent("CALENDAR_UPDATE_EVENT_LIST")
	calendar:updateList()
	C_Calendar.OpenCalendar()
end)
GameTimeFrame:HookScript("OnLeave", function()
	calendar:UnregisterEvent("CALENDAR_UPDATE_EVENT_LIST")
end)
GameTimeFrame:HookScript("OnUpdate", function(self)
	if GameTooltip:IsOwned(self) then
		calendar:setTooltip()
	end
end)