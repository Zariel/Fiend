if GetLocale() ~= "ruRU" then return end
local L = {}

L["Damage"] = "Урон"
L["Healing"] = "Исцеление"
L["OverHealing"] = "Избыточное исцеление"
L["Reset"] = "Сброс"
L["Reset All"] = "Сбросить все"
L["Displays"] = "Отображения"
L["Output"] = "Вывод"
L["Guild"] = "Гильдия"
L["Party"] = "Группа"
L["Say"] = "Сказать"
L["Whisper"] = "Шепнуть"
L["Print"] = "Печать"
L["Count"] = "Количество"
L["Hide"] = "Показать"
L["Show"] = "Скрыть"
L["All"] = "Все"
L["Set the output limit to %d"] = "Установить предел вывода на %d строк"
L["Set the output limit to All"] = "Установить предел вывода на все строки"

local _, Fiend = ...
Fiend.L = L