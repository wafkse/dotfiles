--!strict

local Types = require("../Types")
local ThemeContext = require("../Context")

type GtkPartEntry = { Part: Types.GtkPart }

local function gtkPart(Part: Types.GtkPart): GtkPartEntry
	return { Part = Part }
end

local GTK_PARTS: { GtkPartEntry } = {
	gtkPart("window-background"), gtkPart("window-foreground"),
	gtkPart("view-background"), gtkPart("view-foreground"),
	gtkPart("surface-background"), gtkPart("surface-foreground"),
	gtkPart("raised-background"), gtkPart("raised-foreground"),
	gtkPart("muted-foreground"), gtkPart("disabled-foreground"),
	gtkPart("border"), gtkPart("border-strong"), gtkPart("shadow"),
	gtkPart("control-accent"), gtkPart("control-accent-foreground"),
	gtkPart("selection-background"), gtkPart("selection-foreground"),
	gtkPart("error"), gtkPart("error-foreground"),
	gtkPart("warning"), gtkPart("warning-foreground"),
	gtkPart("success"), gtkPart("success-foreground"),
	gtkPart("link"), gtkPart("link-visited"), gtkPart("placeholder-text"),
	gtkPart("tooltip-background"), gtkPart("tooltip-foreground"),
	gtkPart("title-close"), gtkPart("title-minimize"), gtkPart("title-maximize"),
	gtkPart("category-create"), gtkPart("category-develop"),
	gtkPart("category-learn"), gtkPart("category-play"),
	gtkPart("category-socialize"), gtkPart("category-work"),
	gtkPart("palette-error"), gtkPart("palette-warning"),
	gtkPart("palette-success"), gtkPart("palette-link"),
	gtkPart("palette-accent"), gtkPart("palette-neutral"),
}

local Gtk = {}

--- ThemeGtkColor resolves a GTK UI part to its assigned semantic palette role.
function Gtk.ThemeGtkColor(Theme: Types.ThemeRoot, Part: Types.GtkPart): Types.ColorHex
	local Active = ThemeContext.ActiveTheme(Theme)
	local RoleName = ThemeContext.OverrideLookup(Theme, Active, "GTK", Part)

	if RoleName == nil then
		return ThemeContext.Placeholder(Theme)
	end

	return ThemeContext.ThemeRoleByName(Theme, tostring(RoleName))
end

--- ThemeGtkPalette emits GTK aliases consumed by the GTK3 and GTK4 Sass output.
function Gtk.ThemeGtkPalette(Theme: Types.ThemeRoot): string
	local Lines: { string } = {
		"/* Mirage GTK styling for " .. ThemeContext.ThemeLabel(Theme) .. ".",
		" * UI parts resolve through the active theme's GTK color-family assignments.",
		" */",
	}

	for _, Entry in GTK_PARTS do
		local Part = Entry.Part
		local Name = string.gsub(Part, "-", "_")
		table.insert(Lines, string.format("@define-color ui_%s %s;", Name, Gtk.ThemeGtkColor(Theme, Part :: Types.GtkPart)))
	end

	return table.concat(Lines, "\n")
end

return Gtk
