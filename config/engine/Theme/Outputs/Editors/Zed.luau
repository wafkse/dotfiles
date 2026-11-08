--!strict

local Types = require("../../Types")
local ThemeContext = require("../../Context")
local ColorRoles = require("./ColorRoles")
local Json = require("./Json")

local Zed = {}

--- syntaxFields joins capture colors and optional typography into Zed syntax entries.
local function syntaxFields(Theme: Types.ThemeRoot): { Types.SyntaxField }
	local FieldsByKey: { [string]: Types.SyntaxField } = {}
	for _, Field in ColorRoles.resolve(Theme, "Zed", "Syntax") do
		FieldsByKey[Field.Key] = { Key = Field.Key, Color = Field.Color }
	end

	local Styles = ThemeContext.ApplicationRoleMap(Theme, "Zed", "SyntaxStyles")
	if Styles ~= nil then
		for Key, Value in Styles do
			if type(Key) == "string" and Value ~= nil then
				local Capture = string.match(Key, "^(.*)%.font_style$")
				local Property = if Capture ~= nil then "font_style" else nil
				if Capture == nil then
					Capture = string.match(Key, "^(.*)%.font_weight$")
					Property = if Capture ~= nil then "font_weight" else nil
				end

				local Field = if Capture ~= nil then FieldsByKey[Capture] else nil
				if Field ~= nil and Property == "font_style" then
					Field.FontStyle = tostring(Value)
				elseif Field ~= nil and Property == "font_weight" then
					Field.FontWeight = tonumber(tostring(Value))
				end
			end
		end
	end

	local Fields: { Types.SyntaxField } = {}
	for _, Field in FieldsByKey do
		table.insert(Fields, Field)
	end
	table.sort(Fields, function(Left: Types.SyntaxField, Right: Types.SyntaxField): boolean
		return Left.Key < Right.Key
	end)
	return Fields
end

--- numberedFields serializes an ordered numeric role map as a JSON array.
local function numberedFields(Fields: { Types.ColorField }): string
	table.sort(Fields, function(Left: Types.ColorField, Right: Types.ColorField): boolean
		return (tonumber(Left.Key) or math.huge) < (tonumber(Right.Key) or math.huge)
	end)
	local Values: { string } = {}
	for _, Field in Fields do
		table.insert(Values, Json.quote(Field.Color))
	end
	return "[" .. table.concat(Values, ",") .. "]"
end

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

	local AccentFields = ColorRoles.resolve(Theme, "Zed", "Accents")
	if #AccentFields > 0 then
		table.insert(StyleFields, { Key = "accents", Value = numberedFields(AccentFields) })
	end

	table.insert(StyleFields, {
		Key = "syntax",
		Value = Json.syntaxObject(syntaxFields(Theme)),
	})

	local NullFields = ThemeContext.ApplicationRoleMap(Theme, "Zed", "Null")
	if NullFields ~= nil then
		for Key, Value in NullFields do
			if type(Key) == "string" and Value ~= nil then
				table.insert(StyleFields, { Key = Key, Value = "null" })
			end
		end
	end

	local Settings = ThemeContext.ApplicationRoleMap(Theme, "Zed", "Settings")
	if Settings ~= nil then
		for Key, Value in Settings do
			if type(Key) == "string" and Value ~= nil then
				table.insert(StyleFields, { Key = Key, Value = Json.tomlScalar(Value) })
			end
		end
	end

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
