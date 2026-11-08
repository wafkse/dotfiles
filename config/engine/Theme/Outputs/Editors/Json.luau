--!strict

local Types = require("../../Types")

local Json = {}

--- quote escapes a Luau string for a JSON string value.
function Json.quote(Value: string): string
	local Escaped = string.gsub(Value, "\\", "\\\\")
	Escaped = string.gsub(Escaped, '"', '\\"')
	Escaped = string.gsub(Escaped, "\b", "\\b")
	Escaped = string.gsub(Escaped, "\f", "\\f")
	Escaped = string.gsub(Escaped, "\n", "\\n")
	Escaped = string.gsub(Escaped, "\r", "\\r")
	Escaped = string.gsub(Escaped, "\t", "\\t")
	Escaped = string.gsub(Escaped, "[%z\1-\31]", function(Character: string): string
		return string.format("\\u%04x", string.byte(Character))
	end)
	return '"' .. Escaped .. '"'
end

--- object encodes a set of already serialized JSON values in stable key order.
function Json.object(Fields: { Types.JsonField }): string
	local Sorted: { Types.JsonField } = {}
	for _, Field in Fields do
		table.insert(Sorted, Field)
	end
	table.sort(Sorted, function(Left: Types.JsonField, Right: Types.JsonField): boolean
		return Left.Key < Right.Key
	end)

	local Parts: { string } = {}
	for _, Field in Sorted do
		table.insert(Parts, Json.quote(Field.Key) .. ":" .. Field.Value)
	end
	return "{" .. table.concat(Parts, ",") .. "}"
end

--- colorObject encodes app token colors as a JSON string-to-string object.
function Json.colorObject(Fields: { Types.ColorField }): string
	local JsonFields: { Types.JsonField } = {}
	for _, Field in Fields do
		table.insert(JsonFields, { Key = Field.Key, Value = Json.quote(Field.Color) })
	end
	return Json.object(JsonFields)
end

--- syntaxObject encodes Zed captures with color and optional typography.
function Json.syntaxObject(Fields: { Types.SyntaxField }): string
	local JsonFields: { Types.JsonField } = {}
	for _, Field in Fields do
		local CaptureFields: { Types.JsonField } = {
			{ Key = "color", Value = Json.quote(Field.Color) },
			{ Key = "font_style", Value = if Field.FontStyle ~= nil then Json.quote(Field.FontStyle) else "null" },
			{ Key = "font_weight", Value = if Field.FontWeight ~= nil then tostring(Field.FontWeight) else "null" },
		}
		table.insert(JsonFields, { Key = Field.Key, Value = Json.object(CaptureFields) })
	end
	return Json.object(JsonFields)
end

--- tomlScalar serializes a TOML scalar as a JSON primitive.
function Json.tomlScalar(Value: Types.TomlNode): string
	local Text = tostring(Value)
	if Text == "true" or Text == "false" then
		return Text
	end
	if tonumber(Text) ~= nil then
		return Text
	end
	return Json.quote(Text)
end

--- vscodeTokens encodes TextMate scopes as VS Code token color rules.
function Json.vscodeTokens(Fields: { Types.ColorField }): string
	local Rules: { string } = {}
	for _, Field in Fields do
		local Settings = Json.object({ { Key = "foreground", Value = Json.quote(Field.Color) } })
		local Rule = Json.object({
			{ Key = "scope", Value = Json.quote(Field.Key) },
			{ Key = "settings", Value = Settings },
		})
		table.insert(Rules, Rule)
	end
	return "[" .. table.concat(Rules, ",") .. "]"
end

--- vscodeSemanticTokens encodes semantic token scopes as foreground objects.
function Json.vscodeSemanticTokens(Fields: { Types.ColorField }): string
	local JsonFields: { Types.JsonField } = {}
	for _, Field in Fields do
		local TokenStyle = Json.object({
			{ Key = "foreground", Value = Json.quote(Field.Color) },
		})
		table.insert(JsonFields, { Key = Field.Key, Value = TokenStyle })
	end
	return Json.object(JsonFields)
end

return Json
