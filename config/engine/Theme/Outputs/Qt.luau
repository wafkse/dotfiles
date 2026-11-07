--!strict

local Types = require("../Types")
local ThemeContext = require("../Context")

local function qtColorGroup(State: Types.QtState, Roles: { Types.SemanticRole }): Types.QtColorGroup
	local Slots: { Types.QtColorSlot } = {}
	for _, Role in Roles do
		table.insert(Slots, { Role = Role :: Types.SemanticRole })
	end
	return { State = State, Slots = Slots }
end

local QT_COLOR_GROUPS: { Types.QtColorGroup } = {
	qtColorGroup("active", {
		"foreground", "surface-mid", "border-strong", "surface-raised", "shadow", "surface",
		"foreground", "foreground", "foreground", "background", "surface", "shadow",
		"accent", "shadow", "link", "link-visited", "surface", "foreground", "background",
		"foreground", "placeholder", "accent",
	}),
	qtColorGroup("inactive", {
		"foreground-muted", "background", "surface-mid", "surface-raised", "shadow", "surface",
		"foreground-muted", "foreground", "foreground-muted", "background", "surface", "shadow",
		"surface-raised", "foreground-muted", "foreground-muted", "foreground-muted", "surface",
		"foreground", "background", "foreground", "placeholder", "surface-raised",
	}),
	qtColorGroup("disabled", {
		"disabled", "surface-raised", "surface-mid", "surface-raised", "shadow", "surface",
		"disabled", "foreground", "disabled", "background", "surface", "shadow", "surface",
		"disabled", "link", "link-visited", "surface", "foreground", "background", "foreground",
		"placeholder", "surface",
	}),
}

local Qt = {}

--- desaturateColor reduces HSL saturation while preserving hue and lightness.
local function desaturateColor(Color: Types.ColorHex, Amount: number): Types.ColorHex
	local Hex = string.gsub(Color, "#", "")
	if #Hex ~= 6 then
		return Color
	end

	local Red = (tonumber(string.sub(Hex, 1, 2), 16) or 0) / 255
	local Green = (tonumber(string.sub(Hex, 3, 4), 16) or 0) / 255
	local Blue = (tonumber(string.sub(Hex, 5, 6), 16) or 0) / 255
	local Maximum = math.max(Red, Green, Blue)
	local Minimum = math.min(Red, Green, Blue)
	local Chroma = Maximum - Minimum
	if Chroma == 0 then
		return Color
	end

	local Lightness = (Maximum + Minimum) / 2
	local Hue = 0
	if Maximum == Red then
		Hue = 60 * (((Green - Blue) / Chroma) % 6)
	elseif Maximum == Green then
		Hue = 60 * (((Blue - Red) / Chroma) + 2)
	else
		Hue = 60 * (((Red - Green) / Chroma) + 4)
	end

	local Saturation = Chroma / (1 - math.abs(2 * Lightness - 1))
	local NewChroma = (1 - math.abs(2 * Lightness - 1)) * Saturation * (1 - Amount)
	local Sector = Hue / 60
	local X = NewChroma * (1 - math.abs((Sector % 2) - 1))
	local Red1, Green1, Blue1
	if Sector < 1 then
		Red1, Green1, Blue1 = NewChroma, X, 0
	elseif Sector < 2 then
		Red1, Green1, Blue1 = X, NewChroma, 0
	elseif Sector < 3 then
		Red1, Green1, Blue1 = 0, NewChroma, X
	elseif Sector < 4 then
		Red1, Green1, Blue1 = 0, X, NewChroma
	elseif Sector < 5 then
		Red1, Green1, Blue1 = X, 0, NewChroma
	else
		Red1, Green1, Blue1 = NewChroma, 0, X
	end

	local Offset = Lightness - NewChroma / 2
	local function Byte(Value: number): number
		return math.floor((Value + Offset) * 255 + 0.5)
	end

	return string.format("#%02x%02x%02x", Byte(Red1), Byte(Green1), Byte(Blue1))
end

--- ThemeQtConfig renders the three ordered color groups for Qt5ct and Qt6ct.
function Qt.ThemeQtConfig(Theme: Types.ThemeRoot): string
	local Lines: { string } = {
		"# Mirage Auto-generated from " .. ThemeContext.ThemeLabel(Theme),
		"# Color slot order follows the Qt5ct and Qt6ct color scheme format.",
		"[ColorScheme]",
	}

	for _, Group in QT_COLOR_GROUPS do
		local State = Group.State
		local Colors: { string } = {}
		for _, Slot in Group.Slots do
			local Role = Slot.Role :: Types.SemanticRole
			local Alpha = if Role == "placeholder" then "80" else "ff"
			local Color = ThemeContext.ThemeRoleByName(Theme, tostring(Role))
			if State == "disabled" and (Role == "link" or Role == "link-visited") then
				Color = desaturateColor(Color, 0.5)
			end
	
			table.insert(Colors, "#" .. Alpha .. string.gsub(Color, "#", ""))
		end
		table.insert(Lines, State .. "_colors=" .. table.concat(Colors, ", "))
	end

	return table.concat(Lines, "\n")
end

return Qt
