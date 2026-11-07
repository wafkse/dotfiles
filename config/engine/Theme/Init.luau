--!strict

local Types = require("./Types")
local ThemeContext = require("./Context")
local ThemeApplications = require("./Applications")
local ThemeGtk = require("./Outputs/Gtk")
local ThemeQt = require("./Outputs/Qt")
local ThemeZed = require("./Outputs/Editors/Zed")
local ThemeVSCode = require("./Outputs/Editors/VSCode")
local ThemeIDEA = require("./Outputs/Editors/IDEA")

local FunctionTable: Types.ThemeFunctionTable = {
	ThemeLabel = ThemeContext.ThemeLabel,
	ThemeAppearance = ThemeContext.ThemeAppearance,
	ThemeColor = ThemeContext.ThemeColor,
	ThemeRole = ThemeContext.ThemeRole,
	ThemeGtkColor = ThemeGtk.ThemeGtkColor,
	ThemeGtkPalette = ThemeGtk.ThemeGtkPalette,
	ThemeQtConfig = ThemeQt.ThemeQtConfig,
	ThemeApplicationRole = ThemeContext.ThemeApplicationRole,
	ThemeZedTheme = ThemeZed.ThemeZedTheme,
	ThemeVSCodeTheme = ThemeVSCode.ThemeVSCodeTheme,
	ThemeVSCodePackage = ThemeVSCode.ThemeVSCodePackage,
	ThemeIDEATheme = ThemeIDEA.ThemeIDEATheme,
	ThemeIDEAColorScheme = ThemeIDEA.ThemeIDEAColorScheme,
	ThemeApp = ThemeApplications.ThemeApp,
	ThemeAppPalette = ThemeApplications.ThemeAppPalette,
	ThemeAppGradient = ThemeApplications.ThemeAppGradient,
}

local Engine: Types.ThemeEngineModule = {
	function_table = FunctionTable,
}

return Engine
