if GetLocale() ~= "ruRU" then
	return
end

local _, ns = ...
local L = ns.L

L["author"] = "Автор"
L["%s Configuration"] = "Конфигурация %s"
L["Show Past"] = "Показывать прошедшие"
L["Show Future"] = "Показывать будущие"
L["Past Days"] = "Прошедших дней"
L["Future Days"] = "Будущих дней"