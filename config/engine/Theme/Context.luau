--!strict

local Types = require("./Types")
local Colors = require("./Colors")

local ThemeContext = {}

local function applicationRoleMapAt(
	ApplicationRoles: Types.TomlNode?,
	Application: string,
	Group: string
): Types.TomlNode?
	local ApplicationMap = if ApplicationRoles ~= nil then ApplicationRoles[Application] else nil
	return if ApplicationMap ~= nil then ApplicationMap[Group] else nil
end

local SEMANTIC_ROLES: { [string]: boolean } = {
	background = true,
	foreground = true,
	surface = true,
	["surface-foreground"] = true,
	["surface-raised"] = true,
	["surface-raised-foreground"] = true,
	["surface-light"] = true,
	["surface-midlight"] = true,
	["surface-mid"] = true,
	["surface-dark"] = true,
	["surface-hover"] = true,
	["surface-selection"] = true,
	["surface-inactive"] = true,
	["surface-input"] = true,
	["surface-control"] = true,
	["surface-window"] = true,
	muted = true,
	["foreground-muted"] = true,
	["foreground-subtle"] = true,
	["foreground-faint"] = true,
	["foreground-overlay"] = true,
	["foreground-quiet"] = true,
	disabled = true,
	border = true,
	["border-strong"] = true,
	shadow = true,
	accent = true,
	["accent-primary"] = true,
	["accent-secondary"] = true,
	["accent-tertiary"] = true,
	["accent-warm"] = true,
	["accent-soft"] = true,
	["accent-cool"] = true,
	["accent-cyan"] = true,
	["accent-teal"] = true,
	["accent-foreground"] = true,
	["accent-contrast"] = true,
	selection = true,
	["selection-foreground"] = true,
	error = true,
	["error-foreground"] = true,
	warning = true,
	["warning-foreground"] = true,
	success = true,
	["success-foreground"] = true,
	link = true,
	["link-visited"] = true,
	tooltip = true,
	["tooltip-foreground"] = true,
	placeholder = true,
	caret = true,
	["syntax-annotation"] = true,
	["syntax-class"] = true,
	["syntax-comment"] = true,
	["syntax-entity"] = true,
	["syntax-constant"] = true,
	["syntax-function"] = true,
	["syntax-identifier"] = true,
	["syntax-keyword"] = true,
	["syntax-number"] = true,
	["syntax-operator"] = true,
	["syntax-parameter"] = true,
	["syntax-property"] = true,
	["syntax-punctuation"] = true,
	["syntax-regexp"] = true,
	["syntax-string"] = true,
	["syntax-tag"] = true,
	["syntax-type"] = true,
	["syntax-variable"] = true,
	["terminal-bright-red"] = true,
	["terminal-bright-green"] = true,
	["terminal-bright-yellow"] = true,
	["terminal-bright-blue"] = true,
	["terminal-bright-magenta"] = true,
	["terminal-bright-cyan"] = true,
}

--- ActiveTheme selects the explicitly named theme or the configured default.
function ThemeContext.ActiveTheme(Theme: Types.ThemeRoot): Types.ThemeDefinition?
	local Name = Theme.name

	if Name ~= nil and tostring(Name) ~= "" then
		return Theme[tostring(Name)] :: Types.ThemeDefinition?
	end

	local DefaultName = Theme.default
	if DefaultName == nil then
		return nil
	end

	return Theme[tostring(DefaultName)] :: Types.ThemeDefinition?
end

--- Placeholder returns the configured visible fallback color.
function ThemeContext.Placeholder(Theme: Types.ThemeRoot): Types.ColorHex
	local Value = Theme.placeholder
	return if Value == nil then "#ff00ff" else tostring(Value)
end

--- PaletteLookup resolves one palette entry by its display name.
function ThemeContext.PaletteLookup(Active: Types.ThemeDefinition?, ColorName: string): Types.ColorHex?
	if Active == nil then
		return nil
	end

	local Palette = Active.Palette
	if Palette == nil then
		return nil
	end

	for _, Entry in (Palette :: Types.TomlArray) do
		if Entry ~= nil then
			local EntryName = Entry.name
			local Color = Entry.color
			if EntryName ~= nil and Color ~= nil and tostring(EntryName) == ColorName then
				return tostring(Color)
			end
		end
	end

	return nil
end

--- OverrideLookup prefers a theme-specific assignment, then its family's shared assignment.
function ThemeContext.OverrideLookup(
	Theme: Types.ThemeRoot,
	Active: Types.ThemeDefinition?,
	Application: string,
	Key: string
): Types.TomlNode?
	local ApplicationName = tostring(Application)
	local OverrideKey = tostring(Key)

	if Active ~= nil then
		local Overrides = Active.Override
		local ApplicationOverrides = if Overrides ~= nil then Overrides[ApplicationName] else nil
		local Value = if ApplicationOverrides ~= nil then ApplicationOverrides[OverrideKey] else nil
		if Value ~= nil then
			return Value
		end
	end

	if Active == nil then
		return nil
	end

	local FamilyName = Active.family
	local Families = Theme.FamilyOverride
	if FamilyName == nil or Families == nil then
		return nil
	end

	local Family = Families[tostring(FamilyName)]
	local ApplicationOverrides = if Family ~= nil then Family[ApplicationName] else nil
	return if ApplicationOverrides ~= nil then ApplicationOverrides[OverrideKey] else nil
end

--- ThemeLabel returns the active theme's display name for generated files.
function ThemeContext.ThemeLabel(Theme: Types.ThemeRoot): string
	local Name = Theme.name
	if Name ~= nil and tostring(Name) ~= "" then
		return tostring(Name)
	end

	local DefaultName = Theme.default
	return if DefaultName == nil then "Unknown" else tostring(DefaultName)
end

--- ThemeColor resolves a named palette entry or returns the visible fallback.
function ThemeContext.ThemeColor(Theme: Types.ThemeRoot, Name: string): Types.ColorHex
	return ThemeContext.PaletteLookup(ThemeContext.ActiveTheme(Theme), tostring(Name)) or ThemeContext.Placeholder(Theme)
end

--- ThemeAppearance reports the active palette's explicit light or dark mode.
function ThemeContext.ThemeAppearance(Theme: Types.ThemeRoot): Types.Appearance
	local Active = ThemeContext.ActiveTheme(Theme)

	local Appearance = if Active ~= nil then Active.appearance else nil

	return if Appearance ~= nil and tostring(Appearance) == "light" then "light" else "dark"
end

--- ApplicationRoleMap selects theme, family, then shared app-token assignments.
function ThemeContext.ApplicationRoleMap(
	Theme: Types.ThemeRoot,
	Application: Types.EditorApplication,
	Group: Types.ApplicationRoleGroup
): Types.TomlNode?
	local Active = ThemeContext.ActiveTheme(Theme)

	local ThemeOverrides = if Active ~= nil then Active.Override else nil

	local ThemeApplicationRoles = if ThemeOverrides ~= nil then ThemeOverrides.ApplicationRoles else nil

	local RoleMap = applicationRoleMapAt(ThemeApplicationRoles, Application, Group)
	if RoleMap ~= nil then
		return RoleMap
	end

	local FamilyName = if Active ~= nil then Active.family else nil
	local Families = Theme.FamilyOverride
	local Family = if FamilyName ~= nil and Families ~= nil then Families[tostring(FamilyName)] else nil
	local FamilyApplicationRoles = if Family ~= nil then Family.ApplicationRoles else nil

	RoleMap = applicationRoleMapAt(FamilyApplicationRoles, Application, Group)
	if RoleMap ~= nil then
		return RoleMap
	end

	return applicationRoleMapAt(Theme.ApplicationRoles, Application, Group)
end

--- ThemeApplicationRole resolves an app token's semantic role through the palette.
function ThemeContext.ThemeApplicationRole(
	Theme: Types.ThemeRoot,
	Application: Types.EditorApplication,
	Group: Types.ApplicationRoleGroup,
	Key: string
): Types.ColorHex
	local RoleMap = ThemeContext.ApplicationRoleMap(Theme, Application, Group)
	local Assignment = if RoleMap ~= nil then RoleMap[tostring(Key)] else nil
	if Assignment == nil then
		return ThemeContext.Placeholder(Theme)
	end

	local function descriptorField(Field: string): Types.TomlNode?
		local Success, Value = pcall(function(): Types.TomlNode?
			return Assignment[Field]
		end)
		return if Success then Value else nil
	end

	local Descriptor: Types.ApplicationRoleDescriptor = {
		role = descriptorField("role"),
		["light-role"] = descriptorField("light-role"),
		["dark-role"] = descriptorField("dark-role"),
		opacity = descriptorField("opacity"),
		["light-opacity"] = descriptorField("light-opacity"),
		["dark-opacity"] = descriptorField("dark-opacity"),
		mix = descriptorField("mix"),
		amount = descriptorField("amount"),
		["light-amount"] = descriptorField("light-amount"),
		["dark-amount"] = descriptorField("dark-amount"),
		["shade"] = descriptorField("shade"),
		["light-shade"] = descriptorField("light-shade"),
		["dark-shade"] = descriptorField("dark-shade"),
		["color-math"] = descriptorField("color-math"),
	}
	local ColorMath: "byte-ratio"? = if Descriptor["color-math"] ~= nil
		and tostring(Descriptor["color-math"]) == "byte-ratio"
		then "byte-ratio"
		else nil
	local Appearance = ThemeContext.ThemeAppearance(Theme)
	local RoleNode = if Appearance == "light"
		then Descriptor["light-role"] or Descriptor.role
		else Descriptor["dark-role"] or Descriptor.role
	local RoleName = if RoleNode ~= nil then tostring(RoleNode) else tostring(Assignment)
	local Color = ThemeContext.ThemeRoleByName(Theme, RoleName)
	local MixRole = Descriptor.mix
	local AmountNode = if Appearance == "light"
		then Descriptor["light-amount"] or Descriptor.amount
		else Descriptor["dark-amount"] or Descriptor.amount

	if MixRole ~= nil and AmountNode ~= nil then
		local MixColor = ThemeContext.ThemeRoleByName(Theme, tostring(MixRole))
		local Amount = tonumber(tostring(AmountNode))
		if Amount ~= nil then
			Color = Colors.mix(Color, MixColor, Amount, ColorMath)
		end
	end

	local ShadeNode = if Appearance == "light"
		then Descriptor["light-shade"] or Descriptor["shade"]
		else Descriptor["dark-shade"] or Descriptor["shade"]
	if ShadeNode ~= nil then
		local Amount = tonumber(tostring(ShadeNode))
		if Amount ~= nil then
			Color = Colors.shade(Color, Amount, ColorMath)
		end
	end

	local OpacityNode = if Appearance == "light"
		then Descriptor["light-opacity"] or Descriptor.opacity
		else Descriptor["dark-opacity"] or Descriptor.opacity
	if OpacityNode ~= nil then
		local Opacity = tonumber(tostring(OpacityNode))
		if Opacity ~= nil then
			Color = Colors.opacity(Color, Opacity)
		end
	end

	return Color
end

--- ThemeRole resolves a semantic role through a theme exception or family palette map.
function ThemeContext.ThemeRole(Theme: Types.ThemeRoot, Role: Types.SemanticRole): Types.ColorHex
	local Active = ThemeContext.ActiveTheme(Theme)
	local RoleKey = tostring(Role)
	local RoleName: Types.TomlNode? = nil

	if Active ~= nil then
		local Overrides = Active.Override
		local RoleOverrides = if Overrides ~= nil then Overrides.Roles else nil
		RoleName = if RoleOverrides ~= nil then RoleOverrides[RoleKey] else nil
	end

	if RoleName == nil and Active ~= nil then
		local FamilyName = Active.family
		local Families = Theme.FamilyOverride
		local Family = if FamilyName ~= nil and Families ~= nil then Families[tostring(FamilyName)] else nil
		local FamilyRoles = if Family ~= nil then Family.Roles else nil
		RoleName = if FamilyRoles ~= nil then FamilyRoles[RoleKey] else nil
	end

	if RoleName == nil then
		return ThemeContext.Placeholder(Theme)
	end

	return ThemeContext.PaletteLookup(Active, tostring(RoleName)) or ThemeContext.Placeholder(Theme)
end

--- ThemeRoleByName validates a TOML role name before crossing into the typed role API.
function ThemeContext.ThemeRoleByName(Theme: Types.ThemeRoot, RoleName: string): Types.ColorHex
	if SEMANTIC_ROLES[RoleName] ~= true then
		return ThemeContext.Placeholder(Theme)
	end

	return ThemeContext.ThemeRole(Theme, RoleName :: Types.SemanticRole)
end

return ThemeContext
