--!strict

local Types = require("../../Types")
local ThemeContext = require("../../Context")
local ColorRoles = require("./ColorRoles")
local Json = require("./Json")

type AttributeProperties = { [string]: string }
type AttributeGroups = { [string]: AttributeProperties }
type JsonTree = { Value: string?, Children: { [string]: JsonTree } }

local IDEA = {}

local function escapeXml(Value: string): string
	local Escaped = string.gsub(Value, "&", "&amp;")
	Escaped = string.gsub(Escaped, "<", "&lt;")
	Escaped = string.gsub(Escaped, ">", "&gt;")
	Escaped = string.gsub(Escaped, '"', "&quot;")
	return string.gsub(Escaped, "'", "&apos;")
end

local function insertPath(Root: JsonTree, Path: string, Value: string)
	local Node = Root
	for _, Segment in string.split(Path, ".") do
		local Child = Node.Children[Segment]
		if Child == nil then
			Child = { Children = {} }
			Node.Children[Segment] = Child
		end
		Node = Child
	end
	Node.Value = Value
end

local function jsonTreeObject(Node: JsonTree): string
	local Fields: { Types.JsonField } = {}
	for Key, Child in Node.Children do
		local Value = Child.Value or jsonTreeObject(Child)
		table.insert(Fields, { Key = Key, Value = Value })
	end
	return Json.object(Fields)
end

local function uiObject(Fields: { Types.JsonField }): string
	local Root: JsonTree = { Children = {} }
	local DirectFields: { Types.JsonField } = {}
	for _, Field in Fields do
		if string.match(Field.Key, "^UiDesigner%.") ~= nil then
			table.insert(DirectFields, Field)
		else
			insertPath(Root, Field.Key, Field.Value)
		end
	end
	local OutputFields: { Types.JsonField } = DirectFields
	for Key, Child in Root.Children do
		table.insert(OutputFields, { Key = Key, Value = Child.Value or jsonTreeObject(Child) })
	end
	return Json.object(OutputFields)
end

local function rawFields(
	Theme: Types.ThemeRoot,
	Group: Types.ApplicationRoleGroup
): { Types.StringField }
	local RoleMap = ThemeContext.ApplicationRoleMap(Theme, "IDEA", Group)
	local Fields: { Types.StringField } = {}
	if RoleMap ~= nil then
		for Key, Value in RoleMap do
			if type(Key) == "string" then
				table.insert(Fields, { Key = Key, Value = tostring(Value) })
			end
		end
	end
	table.sort(Fields, function(Left, Right)
		return Left.Key < Right.Key
	end)
	return Fields
end

local function jsonScalar(Value: string): string
	if Value == "true" or Value == "false" or tonumber(Value) ~= nil then
		return Value
	end
	return Json.quote(Value)
end

local function resolvedColorFields(Fields: { Types.ColorField }): { Types.JsonField }
	local JsonFields: { Types.JsonField } = {}
	for _, Field in Fields do
		table.insert(JsonFields, { Key = Field.Key, Value = Json.quote(Field.Color) })
	end
	return JsonFields
end

--- ThemeIDEATheme serializes IntelliJ UI colors and its editor scheme reference.
function IDEA.ThemeIDEATheme(Theme: Types.ThemeRoot): string
	local IsDark = ThemeContext.ThemeAppearance(Theme) == "dark"
	local UiFields = resolvedColorFields(ColorRoles.resolve(Theme, "IDEA", "UI"))
	for _, Field in rawFields(Theme, "Settings") do
		table.insert(UiFields, { Key = Field.Key, Value = jsonScalar(Field.Value) })
	end
	local IconFields = resolvedColorFields(ColorRoles.resolve(Theme, "IDEA", "Icons"))
	return Json.object({
		{ Key = "name", Value = Json.quote("Mirage") },
		{ Key = "author", Value = Json.quote("Mirage") },
		{ Key = "dark", Value = if IsDark then "true" else "false" },
		{ Key = "editorScheme", Value = Json.quote("/themes/Mirage.xml") },
		{ Key = "ui", Value = uiObject(UiFields) },
		{
			Key = "icons",
			Value = Json.object({
				{ Key = "ColorPalette", Value = Json.object(IconFields) },
			}),
		},
	})
end

--- ThemeIDEAColorScheme renders IntelliJ's XML editor scheme from semantic roles.
function IDEA.ThemeIDEAColorScheme(Theme: Types.ThemeRoot): string
	local ParentScheme = if ThemeContext.ThemeAppearance(Theme) == "dark" then "Darcula" else "Default"
	local AttributeMap: AttributeGroups = {}
	local Lines: { string } = {
		'<?xml version="1.0"?>',
		'<!-- Mirage editor colors for ' .. escapeXml(ThemeContext.ThemeLabel(Theme)) .. '. -->',
		'<scheme name="Mirage" version="142" parent_scheme="' .. ParentScheme .. '">',
		"  <colors>",
	}

	for _, Field in ColorRoles.resolve(Theme, "IDEA", "Colors") do
		local Hex = string.gsub(Field.Color, "#", "")
		table.insert(Lines, '    <option name="' .. escapeXml(Field.Key) .. '" value="' .. Hex .. '" />')
	end

	table.insert(Lines, "  </colors>")
	table.insert(Lines, "  <attributes>")
	for _, Field in ColorRoles.resolve(Theme, "IDEA", "Attributes") do
		local MatchedAttribute, MatchedProperty = string.match(Field.Key, "^(.*)%.([A-Z_]+)$")
		local AttributeName = MatchedAttribute or Field.Key
		local Property = MatchedProperty or "FOREGROUND"

		local Properties = AttributeMap[AttributeName]
		if Properties == nil then
			Properties = {}
			AttributeMap[AttributeName] = Properties
		end
		Properties[Property] = string.gsub(Field.Color, "#", "")
	end
	for _, Field in rawFields(Theme, "Styles") do
		local MatchedAttribute, MatchedProperty = string.match(Field.Key, "^(.*)%.([A-Z_]+)$")
		if MatchedAttribute ~= nil and MatchedProperty ~= nil then
			local Properties = AttributeMap[MatchedAttribute]
			if Properties == nil then
				Properties = {}
				AttributeMap[MatchedAttribute] = Properties
			end
			Properties[MatchedProperty] = Field.Value
		end
	end

	local AttributeNames: { string } = {}
	for AttributeName in AttributeMap do
		table.insert(AttributeNames, AttributeName)
	end
	table.sort(AttributeNames)
	for _, AttributeName in AttributeNames do
		table.insert(Lines, '    <option name="' .. escapeXml(AttributeName) .. '">')
		table.insert(Lines, "      <value>")
		local Properties = AttributeMap[AttributeName] :: AttributeProperties
		local PropertyNames: { string } = {}
		for Property in Properties do
			table.insert(PropertyNames, Property)
		end
		table.sort(PropertyNames)
		for _, Property in PropertyNames do
			table.insert(
				Lines,
				'        <option name="'
					.. escapeXml(Property)
					.. '" value="'
					.. escapeXml(Properties[Property])
					.. '" />'
			)
		end
		table.insert(Lines, "      </value>")
		table.insert(Lines, "    </option>")
	end
	table.insert(Lines, "  </attributes>")
	table.insert(Lines, "</scheme>")
	return table.concat(Lines, "\n")
end

return IDEA
