--!strict

local Types = require("../../Types")
local ThemeContext = require("../../Context")

local ColorRoles = {}

--- resolve materializes one app's TOML role map as stable, resolved color entries.
function ColorRoles.resolve(
	Theme: Types.ThemeRoot,
	Application: Types.EditorApplication,
	Group: Types.ApplicationRoleGroup
): { Types.ColorField }
	local RoleMap = ThemeContext.ApplicationRoleMap(Theme, Application, Group)
	local Fields: { Types.ColorField } = {}
	if RoleMap == nil then
		return Fields
	end

	for Key, _ in RoleMap do
		if type(Key) == "string" then
			local KeyName = Key :: string
			table.insert(Fields, {
				Key = KeyName,
				Color = ThemeContext.ThemeApplicationRole(Theme, Application, Group, KeyName),
			})
		end
	end

	table.sort(Fields, function(Left: Types.ColorField, Right: Types.ColorField): boolean
		return Left.Key < Right.Key
	end)
	return Fields
end

return ColorRoles
