--[[
    Mirage theme-resolution module.

    This is the Luau replacement for the old `partial/theme.tera` macro file. Every
    template function below receives the live render context as opaque, lazily-resolving
    Mirage value handles: indexing walks the underlying TOML tree without materializing
    it, missing keys collapse to `nil`, and `tostring` yields a value's display form.

    Templates call these as ordinary minijinja functions, e.g.

        {{ ThemeApp(Theme, 'Ghostty', 'background') }}

    where `Theme` is the `[default.Theme]` tree merged in from the configure candidates.

    Override resolution is two-tier (see `OverrideLookup`): a theme's own `Override` table
    is a surgical exception that wins per key, and anything it leaves unset falls back to
    the shared `FamilyOverride.<family>` mapping selected by the theme's `family` tag. The
    family mapping holds role names, so one Catppuccin block resolves correct hexes for
    every flavor against that flavor's own palette.
]]

--- The active theme subtree for a `Theme` root.
---
--- The selection mirrors the old macros: an explicit `Theme.name` wins when present and
--- non-empty, otherwise `Theme.default` is used.
local function ActiveTheme(Theme)
    local Name = Theme.name

    if Name ~= nil and tostring(Name) ~= "" then
        return Theme[tostring(Name)]
    end

    return Theme[tostring(Theme.default)]
end

--- The visible fallback colour, surfaced whenever a lookup fails so a mistake is loud.
local function Placeholder(Theme)
    return tostring(Theme.placeholder)
end

--- Resolve a palette entry's colour by its name within a theme subtree, or `nil`.
local function PaletteLookup(Active, ColorName)
    if Active == nil then
        return nil
    end

    local Palette = Active.Palette

    if Palette == nil then
        return nil
    end

    for _, Entry in Palette do
        if tostring(Entry.name) == ColorName then
            return tostring(Entry.color)
        end
    end

    return nil
end

--- Resolve an application override entry (which holds a colour *name* or structure), or `nil`.
---
--- The lookup is two-tier. A per-theme `Override[App][Key]` is consulted first and wins when
--- present, so an individual theme can carve out exceptions. Otherwise the active theme's
--- `family` tag selects a shared `Theme.FamilyOverride[family][App]` mapping, letting every
--- flavour of a family share one role-name table while still resolving against its own palette.
local function OverrideLookup(Theme, Active, Application, Key)
    -- 1. Per-theme exception.
    if Active ~= nil and Active.Override ~= nil and Active.Override[Application] ~= nil then
        local Value = Active.Override[Application][Key]

        if Value ~= nil then
            return Value
        end
    end

    -- 2. Family mapping, keyed by the active theme's own `family` tag.
    local Family = Active ~= nil and Active.family or nil

    if Family ~= nil then
        local Groups = Theme.FamilyOverride
        local Group = Groups ~= nil and Groups[tostring(Family)] or nil

        if Group ~= nil and Group[Application] ~= nil then
            local Value = Group[Application][Key]

            if Value ~= nil then
                return Value
            end
        end
    end

    return nil
end

--- The display name of the active theme, for headers and comments.
local function ThemeLabel(Theme)
    local Name = Theme.name

    if Name ~= nil and tostring(Name) ~= "" then
        return tostring(Name)
    end

    return tostring(Theme.default)
end

--- A bare palette colour, looked up by its name in the active theme.
local function ThemeColor(Theme, Name)
    return PaletteLookup(ActiveTheme(Theme), tostring(Name)) or Placeholder(Theme)
end

--- An application override colour: an `Override[App][Key]` name resolved to its hex value.
local function ThemeApp(Theme, Application, Key)
    local Active = ActiveTheme(Theme)
    local ColorName = OverrideLookup(Theme, Active, tostring(Application), tostring(Key))

    if ColorName == nil then
        return Placeholder(Theme)
    end

    return PaletteLookup(Active, tostring(ColorName)) or Placeholder(Theme)
end

--- An application override colour *array* (e.g. the Ghostty terminal palette), resolved
--- element-by-element to hex values. Returns an empty sequence when the override is absent.
local function ThemeAppPalette(Theme, Application, Key)
    local Active = ActiveTheme(Theme)
    local Names = OverrideLookup(Theme, Active, tostring(Application), tostring(Key))

    local Resolved = {}

    if Names == nil then
        return Resolved
    end

    for _, Name in Names do
        table.insert(Resolved, PaletteLookup(Active, tostring(Name)) or Placeholder(Theme))
    end

    return Resolved
end

--- An application override gradient, rendered as a run of attributes
--- (`from="#.." to="#.." angle=.. relative-to=".." in=".."`). Returns an empty string when
--- the override is absent so callers can omit the directive entirely.
local function ThemeAppGradient(Theme, Application, Key)
    local Active = ActiveTheme(Theme)
    local Gradient = OverrideLookup(Theme, Active, tostring(Application), tostring(Key))

    if Gradient == nil then
        return ""
    end

    local From = PaletteLookup(Active, tostring(Gradient.from)) or Placeholder(Theme)
    local To = PaletteLookup(Active, tostring(Gradient.to)) or Placeholder(Theme)

    local Parts = { string.format('from="%s" to="%s"', From, To) }

    if Gradient.angle ~= nil then
        table.insert(Parts, "angle=" .. tostring(Gradient.angle))
    end

    local RelativeTo = Gradient["relative-to"]

    if RelativeTo ~= nil then
        table.insert(Parts, string.format('relative-to="%s"', tostring(RelativeTo)))
    end

    if Gradient["in"] ~= nil then
        table.insert(Parts, string.format('in="%s"', tostring(Gradient["in"])))
    end

    return table.concat(Parts, " ")
end

return {
    function_table = {
        ThemeLabel = ThemeLabel,
        ThemeColor = ThemeColor,
        ThemeApp = ThemeApp,
        ThemeAppPalette = ThemeAppPalette,
        ThemeAppGradient = ThemeAppGradient,
    },
}
