--!strict

local Types = require("../../Types")
local ThemeContext = require("../../Context")
local ColorRoles = require("./ColorRoles")
local Json = require("./Json")

local Zed = {}

--- playerArray groups numbered dotted keys into Zed's ordered player entries.
local function playerArray(Fields: { Types.ColorField }): string
	local Players: { [number]: { Types.ColorField } } = {}
	local Indices: { number } = {}

	for _, Field in Fields do
		local IndexText, PlayerKey = string.match(Field.Key, "^(%d+)%.([%w_.%-]+)$")
		local Index = if IndexText ~= nil then tonumber(IndexText) else nil
		if Index ~= nil and PlayerKey ~= nil then
			local Player = Players[Index]
			if Player == nil then
				Player = {}
				Players[Index] = Player
				table.insert(Indices, Index)
			end
			table.insert(Player, { Key = PlayerKey, Color = Field.Color })
		end
	end

	table.sort(Indices)
	local Entries: { string } = {}
	for _, Index in Indices do
		table.insert(Entries, Json.colorObject(Players[Index]))
	end
	return "[" .. table.concat(Entries, ",") .. "]"
end

--- ThemeZedTheme serializes TOML role assignments to Zed's custom theme format.
function Zed.ThemeZedTheme(Theme: Types.ThemeRoot): string
	local StyleFields: { Types.JsonField } = {}
	for _, Field in ColorRoles.resolve(Theme, "Zed", "Colors") do
		table.insert(StyleFields, { Key = Field.Key, Value = Json.quote(Field.Color) })
	end

	for _, Field in ColorRoles.resolve(Theme, "Zed", "Terminal") do
		table.insert(StyleFields, {
			Key = "terminal.ansi." .. Field.Key,
			Value = Json.quote(Field.Color),
		})
	end

	local PlayerFields = ColorRoles.resolve(Theme, "Zed", "Players")
	if #PlayerFields > 0 then
		table.insert(StyleFields, {
			Key = "players",
			Value = playerArray(PlayerFields),
		})
	end

	table.insert(StyleFields, {
		Key = "syntax",
		Value = Json.syntaxObject(ColorRoles.resolve(Theme, "Zed", "Syntax")),
	})

	local ThemeStyle = Json.object(StyleFields)
	local ThemeEntry = Json.object({
		{ Key = "name", Value = Json.quote("Mirage") },
		{ Key = "appearance", Value = Json.quote(ThemeContext.ThemeAppearance(Theme)) },
		{ Key = "style", Value = ThemeStyle },
	})

	return Json.object({
		{ Key = "$schema", Value = Json.quote("https://zed.dev/schema/themes/v0.2.0.json") },
		{ Key = "name", Value = Json.quote("Mirage") },
		{ Key = "author", Value = Json.quote("Mirage") },
		{ Key = "themes", Value = "[" .. ThemeEntry .. "]" },
	})
end

return Zed
