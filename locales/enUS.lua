local _, ns = ...
local L = {}
ns.L = L

L["author"] = "Author"
L["%s Configuration"] = "%s Configuration"
L["Show Past"] = "Show Past"
L["Show Future"] = "Show Future"
L["Show ID"] = "Show ID"
L["Past Days"] = "Past Days"
L["Future Days"] = "Future Days"
L["titleColor"] = "Title"
L["dateColor"] = "Date"
L["timeColor"] = "Time"
L["timeDayColor"] = "Time (<1d)"
L["pastColor"] = "Past"
L["ongoingColor"] = "Ongoing"
L["futureColor"] = "Future"
L["Reset Colors"] = "Reset Colors"

setmetatable(L, {__index = function(self, key)
	self[key] = key or ""
	return key
end})