# Per-theme overrides

Drop TOML files here to override individual application colours for a **specific
theme**, taking precedence over the shared family mapping in
`theme/Theme.default.toml` (`[default.Theme.FamilyOverride.<family>]`).

The resolver (`theme.luau` → `OverrideLookup`) consults the per-theme `Override`
table first and only falls back to the family mapping when a key is absent. So an
entry here is a surgical exception, not a wholesale replacement — you override just
the keys you name, and everything else keeps inheriting from the family.

These candidates merge **last** (after the theme data), so they win on conflict.

## Example

```toml
#:schema ../../../schema/Universe.toml.schema.json

# Give only Mocha a different launcher border, leaving every other key (and every
# other flavor) on the Catppuccin family mapping.
[default.Theme.'Catppuccin Mocha'.Override.Fuzzel]
border = "Sapphire"
```
