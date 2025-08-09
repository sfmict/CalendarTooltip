if GetLocale() ~= "ruRU" then
	return
end

local _, ns = ...
local L = ns.L

L["author"] = "Автор"
L["%s Configuration"] = "Конфигурация %s"
L["Show Past"] = "Показывать прошедшие"
L["Show Future"] = "Показывать будущие"
L["Show ID"] = "Показывать ID"
L["Past Days"] = "Прошедших дней"
L["Future Days"] = "Будущих дней"
L["titleColor"] = "Заголовок"
L["dateColor"] = "Дата"
L["timeColor"] = "Время"
L["timeDayColor"] = "Время (<1д.)"
L["pastColor"] = "Прошедшие"
L["ongoingColor"] = "Текущие"
L["futureColor"] = "Будущие"
L["Reset Colors"] = "Сбросить цвета"
