--!strict

--- A lazy TOML value exposed by Mirage to engine functions.
---
--- Mirage values support string-key indexing for tables, numeric iteration for arrays,
--- and `tostring` for scalar values. The type describes that host boundary without
--- materializing or weakening the decoded tree to `any`.
export type TomlNode = {
	[string | number]: TomlNode?,
}

--- TomlArray is a contiguous array of lazy TOML values.
export type TomlArray = { [number]: TomlNode? }

--- ThemeRoot is the `[default.Theme]` tree passed to every theme helper.
export type ThemeRoot = {
	[string | number]: TomlNode?,
	--- name optionally selects a theme variant for a one-off render.
	name: TomlNode?,
	--- default names the selected theme when name is absent.
	default: TomlNode,
	--- placeholder supplies the visible fallback when a lookup is incomplete.
	placeholder: TomlNode,
	--- FamilyOverride stores shared semantic roles and application mappings.
	FamilyOverride: TomlNode?,
	--- ApplicationRoles assigns app tokens to semantic roles shared by all palettes.
	ApplicationRoles: TomlNode?,
}

--- ThemeDefinition is one named palette and its family-level override settings.
export type ThemeDefinition = {
	[string | number]: TomlNode?,
	--- family selects the shared family role and application mappings.
	family: TomlNode?,
	--- appearance chooses the matching light or dark editor theme base.
	appearance: TomlNode?,
	--- Palette contains ordered named color entries.
	Palette: TomlNode?,
	--- Override contains per-theme exceptions to family assignments.
	Override: TomlNode?,
}

--- PaletteEntry is one schema-validated named color in a theme's Palette array.
export type PaletteEntry = {
	--- name is the key used by semantic and application mappings.
	name: TomlNode,
	--- color is the hexadecimal value emitted to application templates.
	color: TomlNode,
	--- accent marks a palette color as a candidate highlight.
	accent: TomlNode?,
}

--- GradientOverride contains two palette names and optional target formatting.
export type GradientOverride = {
	--- from names the palette color at the start of the gradient.
	from: TomlNode,
	--- to names the palette color at the end of the gradient.
	to: TomlNode,
	--- angle optionally sets the gradient direction.
	angle: TomlNode?,
	--- relative-to optionally selects the target's gradient coordinate space.
	["relative-to"]: TomlNode?,
	--- in optionally names a nested gradient target.
	["in"]: TomlNode?,
}

--- ApplicationRoleDescriptor adds a color operation to a semantic role assignment.
export type ApplicationRoleDescriptor = {
	--- role selects the semantic palette role for every appearance by default.
	role: TomlNode?,
	--- light-role overrides role when the active theme has a light appearance.
	["light-role"]: TomlNode?,
	--- dark-role overrides role when the active theme has a dark appearance.
	["dark-role"]: TomlNode?,
	--- opacity sets the resolved color's alpha from 0 (transparent) to 1 (opaque).
	opacity: TomlNode?,
	--- light-opacity overrides opacity for light appearances.
	["light-opacity"]: TomlNode?,
	--- dark-opacity overrides opacity for dark appearances.
	["dark-opacity"]: TomlNode?,
	--- mix selects a second semantic role to blend with role.
	mix: TomlNode?,
	--- amount sets role's contribution to a mix, from 0 to 1.
	amount: TomlNode?,
	--- light-amount overrides amount for light appearances.
	["light-amount"]: TomlNode?,
	--- dark-amount overrides amount for dark appearances.
	["dark-amount"]: TomlNode?,
	--- shade adjusts HSL lightness; positive values lighten and negative values darken.
	["shade"]: TomlNode?,
	--- light-shade overrides shade for light appearances.
	["light-shade"]: TomlNode?,
	--- dark-shade overrides shade for dark appearances.
	["dark-shade"]: TomlNode?,
	--- color-math selects the intermediate precision used by mix and shade operations.
	["color-math"]: TomlNode?,
}
--- ColorHex is an RGB or RGBA hexadecimal color returned to a template.
export type ColorHex = string
export type Appearance = "dark" | "light"
export type EditorApplication = "Zed" | "VSCode" | "IDEA"
export type ApplicationRoleGroup = "Accents" | "Colors" | "Null" | "SemanticTokens" | "Syntax" | "SyntaxStyles" | "Terminal" | "Tokens" | "UI" | "Attributes" | "Players" | "Icons" | "Settings" | "Styles"

--- ColorField is one resolved editor token and its active palette color.
export type ColorField = {
	Key: string,
	Color: ColorHex,
}

--- SyntaxField contains one resolved Zed capture and its optional typography.
export type SyntaxField = {
	Key: string,
	Color: ColorHex,
	FontStyle: string?,
	FontWeight: number?,
}

--- JsonField is one object property whose Value is already valid JSON.
export type JsonField = {
	Key: string,
	Value: string,
}

--- StringField is one opaque TOML scalar used for non-color application settings.
export type StringField = {
	Key: string,
	Value: string,
}

--- SemanticRole names the palette-independent visual roles assigned by a family.
export type SemanticRole =
	| "background"
	| "foreground"
	| "surface"
	| "surface-foreground"
	| "surface-raised"
	| "surface-raised-foreground"
	| "surface-light"
	| "surface-midlight"
	| "surface-mid"
	| "surface-dark"
	| "surface-hover"
	| "surface-selection"
	| "surface-inactive"
	| "surface-input"
	| "surface-control"
	| "surface-window"
	| "muted"
	| "foreground-muted"
	| "foreground-subtle"
	| "foreground-faint"
	| "foreground-overlay"
	| "foreground-quiet"
	| "disabled"
	| "border"
	| "border-strong"
	| "shadow"
	| "accent"
	| "accent-primary"
	| "accent-secondary"
	| "accent-tertiary"
	| "accent-warm"
	| "accent-soft"
	| "accent-cool"
	| "accent-cyan"
	| "accent-teal"
	| "accent-foreground"
	| "accent-contrast"
	| "selection"
	| "selection-foreground"
	| "error"
	| "error-foreground"
	| "warning"
	| "warning-foreground"
	| "success"
	| "success-foreground"
	| "link"
	| "link-visited"
	| "tooltip"
	| "tooltip-foreground"
	| "placeholder"
	| "caret"
	| "syntax-annotation"
	| "syntax-class"
	| "syntax-comment"
	| "syntax-entity"
	| "syntax-constant"
	| "syntax-function"
	| "syntax-identifier"
	| "syntax-keyword"
	| "syntax-number"
	| "syntax-operator"
	| "syntax-parameter"
	| "syntax-property"
	| "syntax-punctuation"
	| "syntax-regexp"
	| "syntax-string"
	| "syntax-tag"
	| "syntax-type"
	| "syntax-variable"
	| "terminal-bright-red"
	| "terminal-bright-green"
	| "terminal-bright-yellow"
	| "terminal-bright-blue"
	| "terminal-bright-magenta"
	| "terminal-bright-cyan"

--- GtkPart names the semantic UI areas consumed by the GTK Sass templates.
export type GtkPart =
	| "window-background"
	| "window-foreground"
	| "view-background"
	| "view-foreground"
	| "surface-background"
	| "surface-foreground"
	| "raised-background"
	| "raised-foreground"
	| "muted-foreground"
	| "disabled-foreground"
	| "border"
	| "border-strong"
	| "shadow"
	| "control-accent"
	| "control-accent-foreground"
	| "selection-background"
	| "selection-foreground"
	| "error"
	| "error-foreground"
	| "warning"
	| "warning-foreground"
	| "success"
	| "success-foreground"
	| "link"
	| "link-visited"
	| "placeholder-text"
	| "tooltip-background"
	| "tooltip-foreground"
	| "title-close"
	| "title-minimize"
	| "title-maximize"
	| "category-create"
	| "category-develop"
	| "category-learn"
	| "category-play"
	| "category-socialize"
	| "category-work"
	| "palette-error"
	| "palette-warning"
	| "palette-success"
	| "palette-link"
	| "palette-accent"
	| "palette-neutral"

--- QtState selects one of the three color groups in Qt's color scheme format.
export type QtState = "active" | "inactive" | "disabled"
--- QtColorSlot preserves one ordered Qt palette slot's semantic role.
export type QtColorSlot = {
	--- Role selects the palette-independent color assigned to this slot.
	Role: SemanticRole,
}
--- QtColorGroup preserves one ordered role sequence and its Qt state.
export type QtColorGroup = {
	--- State names the active, inactive, or disabled color sequence.
	State: QtState,
	--- Slots contains the color roles in Qt's required positional order.
	Slots: { QtColorSlot },
}
--- ColorList is an ordered palette of hexadecimal colors.
export type ColorList = { ColorHex }

--- ThemeFunctionTable is the public API available to Jinja templates.
export type ThemeFunctionTable = {
	--- ThemeLabel returns the active theme's display name.
	ThemeLabel: (Theme: ThemeRoot) -> string,
	--- ThemeAppearance returns the active theme's light or dark appearance.
	ThemeAppearance: (Theme: ThemeRoot) -> Appearance,
	--- ThemeColor resolves a named entry in the active theme's palette.
	ThemeColor: (Theme: ThemeRoot, Name: string) -> ColorHex,
	--- ThemeRole resolves a semantic role through the active family's palette mapping.
	ThemeRole: (Theme: ThemeRoot, Role: SemanticRole) -> ColorHex,
	--- ThemeGtkColor resolves a GTK UI part through its family assignment.
	ThemeGtkColor: (Theme: ThemeRoot, Part: GtkPart) -> ColorHex,
	--- ThemeGtkPalette emits GTK color aliases for all Sass UI parts.
	ThemeGtkPalette: (Theme: ThemeRoot) -> string,
	--- ThemeQtConfig renders the Qt5ct and Qt6ct color scheme.
	ThemeQtConfig: (Theme: ThemeRoot) -> string,
	--- ThemeApplicationRole resolves one app token through the semantic-role tree.
	ThemeApplicationRole: (Theme: ThemeRoot, Application: EditorApplication, Group: ApplicationRoleGroup, Key: string) -> ColorHex,
	--- ThemeZedTheme writes the active role mappings as a Zed theme document.
	ThemeZedTheme: (Theme: ThemeRoot) -> string,
	--- ThemeVSCodeTheme writes the active role mappings as a VS Code theme document.
	ThemeVSCodeTheme: (Theme: ThemeRoot) -> string,
	--- ThemeVSCodePackage writes the extension manifest for the generated VS Code theme.
	ThemeVSCodePackage: (Theme: ThemeRoot) -> string,
	--- ThemeIDEATheme writes the IntelliJ UI theme description.
	ThemeIDEATheme: (Theme: ThemeRoot) -> string,
	--- ThemeIDEAColorScheme writes the active role mappings as an IntelliJ editor scheme.
	ThemeIDEAColorScheme: (Theme: ThemeRoot) -> string,
	--- ThemeApp resolves one application override value.
	ThemeApp: (Theme: ThemeRoot, Application: string, Key: string) -> ColorHex,
	--- ThemeAppPalette resolves an ordered application palette override.
	ThemeAppPalette: (Theme: ThemeRoot, Application: string, Key: string) -> ColorList,
	--- ThemeAppGradient renders one application gradient override as attributes.
	ThemeAppGradient: (Theme: ThemeRoot, Application: string, Key: string) -> string,
}

--- ThemeEngineModule is the module contract expected by Mirage's engine loader.
export type ThemeEngineModule = {
	--- function_table contains functions callable from templates.
	function_table: ThemeFunctionTable,
}

return {}
