if GetLocale() ~= "koKR" then return end
local L = {}

L["Damage"] = "데미지"
L["Healing"] = "힐링"
L["OverHealing"] = "오버힐링"
L["Reset"] = "초기화"
L["Reset All"] = "모두 초기화"
L["Displays"] = "표시"
L["Output"] = "출력"
L["Guild"] = "길드"
L["Party"] = "파티"
L["Say"] = "일반"
L["Whisper"] = "귓속말"
L["Print"] = "프린트"
L["Count"] = "갯수"
L["Hide"] = "숨기기"
L["Show"] = "보이기"
L["All"] = "모두"
L["Set the output limit to %d"] = "출력 한계를 %d개로 지정합니다."
L["Set the output limit to All"] = "출력 한계를 모두로 지정합니다."

local _, Fiend = ...
Fiend.L = L
