--!strict

local Types = require("./Types")
local ThemeContext = require("./Context")

local Applications = {}

--- ThemeApp resolves one named palette entry from an application override.
function Applications.ThemeApp(Theme: Types.ThemeRoot, Application: string, Key: string): Types.ColorHex
	local Active = ThemeContext.ActiveTheme(Theme)
	local ColorName = ThemeContext.OverrideLookup(Theme, Active, tostring(Application), tostring(Key))
	if ColorName == nil then
		return ThemeContext.Placeholder(Theme)
	end

	return ThemeContext.PaletteLookup(Active, tostring(ColorName)) or ThemeContext.Placeholder(Theme)
end

--- ThemeAppPalette resolves an ordered application palette override.
function Applications.ThemeAppPalette(
	Theme: Types.ThemeRoot,
	Application: string,
	Key: string
): Types.ColorList
	local Active = ThemeContext.ActiveTheme(Theme)
	local Names = ThemeContext.OverrideLookup(Theme, Active, tostring(Application), tostring(Key))
	local Resolved: Types.ColorList = {}

	if Names == nil then
		return Resolved
	end

	for _, Name in (Names :: Types.TomlArray) do
		table.insert(Resolved, ThemeContext.PaletteLookup(Active, tostring(Name)) or ThemeContext.Placeholder(Theme))
	end

	return Resolved
end

--- ThemeAppGradient renders a gradient override as the target application's attributes.
function Applications.ThemeAppGradient(
	Theme: Types.ThemeRoot,
	Application: string,
	Key: string
): string
	local Active = ThemeContext.ActiveTheme(Theme)
	local Gradient = ThemeContext.OverrideLookup(Theme, Active, tostring(Application), tostring(Key))
	if Gradient == nil then
		return ""
	end
	local FromName = Gradient.from
	local ToName = Gradient.to
	if FromName == nil or ToName == nil then
		return ""
	end

	local GradientOverride: Types.GradientOverride = {
		from = FromName,
		to = ToName,
		angle = Gradient.angle,
		["relative-to"] = Gradient["relative-to"],
		["in"] = Gradient["in"],
	}

	local From = ThemeContext.PaletteLookup(Active, tostring(FromName)) or ThemeContext.Placeholder(Theme)
	local To = ThemeContext.PaletteLookup(Active, tostring(ToName)) or ThemeContext.Placeholder(Theme)
	local Parts: { string } = { string.format('from="%s" to="%s"', From, To) }

	local Angle = GradientOverride.angle
	if Angle ~= nil then
		table.insert(Parts, "angle=" .. tostring(Angle))
	end

	local RelativeTo = GradientOverride["relative-to"]
	if RelativeTo ~= nil then
		table.insert(Parts, string.format('relative-to="%s"', tostring(RelativeTo)))
	end

	local Inset = GradientOverride["in"]
	if Inset ~= nil then
		table.insert(Parts, string.format('in="%s"', tostring(Inset)))
	end

	return table.concat(Parts, " ")
end

return Applications
