local _, ns = ...
local L = {}
ns.L = L

L["Show Past"] = "Show Past"
L["Show Future"] = "Show Future"
L["Past Days"] = "Past Days"
L["Future Days"] = "Future Days"

setmetatable(L, {__index = function(self, key)
	self[key] = key or ""
	return key
end})