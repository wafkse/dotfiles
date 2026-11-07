--!strict

local Types = require("../../Types")
local ThemeContext = require("../../Context")
local ColorRoles = require("./ColorRoles")
local Json = require("./Json")

local VSCode = {}

--- ThemeVSCodeTheme serializes TOML role assignments to a VS Code color theme.
function VSCode.ThemeVSCodeTheme(Theme: Types.ThemeRoot): string
	local Appearance = ThemeContext.ThemeAppearance(Theme)
	local TokenFields = ColorRoles.resolve(Theme, "VSCode", "Tokens")
	local SemanticTokenFields = ColorRoles.resolve(Theme, "VSCode", "SemanticTokens")
	return Json.object({
		{ Key = "$schema", Value = Json.quote("vscode://schemas/color-theme") },
		{ Key = "name", Value = Json.quote("Mirage") },
		{ Key = "type", Value = Json.quote(Appearance) },
		{ Key = "colors", Value = Json.colorObject(ColorRoles.resolve(Theme, "VSCode", "Colors")) },
		{ Key = "tokenColors", Value = Json.vscodeTokens(TokenFields) },
		{
			Key = "semanticTokenColors",
			Value = Json.vscodeSemanticTokens(SemanticTokenFields),
		},
	})
end

--- ThemeVSCodePackage generates a local theme extension manifest.
function VSCode.ThemeVSCodePackage(Theme: Types.ThemeRoot): string
	local UiTheme = if ThemeContext.ThemeAppearance(Theme) == "dark" then "vs-dark" else "vs"
	local ThemeContribution = Json.object({
		{ Key = "label", Value = Json.quote("Mirage") },
		{ Key = "uiTheme", Value = Json.quote(UiTheme) },
		{ Key = "path", Value = Json.quote("./themes/Mirage.json") },
	})
	local Contributions = Json.object({
		{ Key = "themes", Value = "[" .. ThemeContribution .. "]" },
	})
	return Json.object({
		{ Key = "name", Value = Json.quote("mirage-theme") },
		{ Key = "displayName", Value = Json.quote("Mirage Theme") },
		{ Key = "publisher", Value = Json.quote("waffle") },
		{ Key = "version", Value = Json.quote("1.0.0") },
		{ Key = "engines", Value = Json.object({ { Key = "vscode", Value = Json.quote("^1.80.0") } }) },
		{ Key = "categories", Value = "[\"Themes\"]" },
		{ Key = "contributes", Value = Contributions },
	})
end

return VSCode
