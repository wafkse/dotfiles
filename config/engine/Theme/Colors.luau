--!strict

local Colors = {}

type RGB = { Red: number, Green: number, Blue: number }
type HSL = { Hue: number, Saturation: number, Lightness: number }

local function channels(Hex: string): RGB?
	local Red, Green, Blue = string.match(Hex, "^#?(%x%x)(%x%x)(%x%x)$")
	if Red == nil or Green == nil or Blue == nil then
		return nil
	end

	return {
		Red = tonumber(Red, 16) :: number,
		Green = tonumber(Green, 16) :: number,
		Blue = tonumber(Blue, 16) :: number,
	}
end

local function hex(Red: number, Green: number, Blue: number): string
	return string.format(
		"#%02x%02x%02x",
		math.floor(Red + 0.5),
		math.floor(Green + 0.5),
		math.floor(Blue + 0.5)
	)
end

--- mix blends Source over Target by the specified source fraction.
function Colors.mix(Source: string, Target: string, Amount: number): string
	local SourceRGB = channels(Source)
	local TargetRGB = channels(Target)
	if SourceRGB == nil or TargetRGB == nil then
		return Source
	end

	local Fraction = math.clamp(Amount, 0, 1)
	return hex(
		TargetRGB.Red + (SourceRGB.Red - TargetRGB.Red) * Fraction,
		TargetRGB.Green + (SourceRGB.Green - TargetRGB.Green) * Fraction,
		TargetRGB.Blue + (SourceRGB.Blue - TargetRGB.Blue) * Fraction
	)
end

local function toHsl(Color: RGB): HSL
	local Red = Color.Red / 255
	local Green = Color.Green / 255
	local Blue = Color.Blue / 255
	local Maximum = math.max(Red, Green, Blue)
	local Minimum = math.min(Red, Green, Blue)
	local Difference = Maximum - Minimum
	local Lightness = (Maximum + Minimum) / 2
	local Hue = 0
	local Saturation = 0

	if Difference ~= 0 then
		Saturation = if Lightness > 0.5
			then Difference / (2 - Maximum - Minimum)
			else Difference / (Maximum + Minimum)

		if Maximum == Red then
			Hue = (Green - Blue) / Difference + (if Green < Blue then 6 else 0)
		elseif Maximum == Green then
			Hue = (Blue - Red) / Difference + 2
		else
			Hue = (Red - Green) / Difference + 4
		end
		Hue /= 6
	end

	return { Hue = Hue, Saturation = Saturation, Lightness = Lightness }
end

local function hueChannel(P: number, Q: number, Hue: number): number
	local AdjustedHue = Hue
	if AdjustedHue < 0 then
		AdjustedHue += 1
	elseif AdjustedHue > 1 then
		AdjustedHue -= 1
	end

	if AdjustedHue < 1 / 6 then
		return P + (Q - P) * 6 * AdjustedHue
	elseif AdjustedHue < 1 / 2 then
		return Q
	elseif AdjustedHue < 2 / 3 then
		return P + (Q - P) * (2 / 3 - AdjustedHue) * 6
	end
	return P
end

local function fromHsl(Color: HSL): string
	if Color.Saturation == 0 then
		local Gray = Color.Lightness * 255
		return hex(Gray, Gray, Gray)
	end

	local Q = if Color.Lightness < 0.5
		then Color.Lightness * (1 + Color.Saturation)
		else Color.Lightness + Color.Saturation - Color.Lightness * Color.Saturation
	local P = 2 * Color.Lightness - Q
	return hex(
		hueChannel(P, Q, Color.Hue + 1 / 3) * 255,
		hueChannel(P, Q, Color.Hue) * 255,
		hueChannel(P, Q, Color.Hue - 1 / 3) * 255
	)
end

--- shade adjusts HSL lightness while preserving hue and saturation.
function Colors.shade(Hex: string, Amount: number): string
	local RGB = channels(Hex)
	if RGB == nil then
		return Hex
	end

	local HSL = toHsl(RGB)
	HSL.Lightness = math.clamp(HSL.Lightness + Amount, 0, 1)
	return fromHsl(HSL)
end

--- opacity appends an 8-bit alpha channel in the editor color format.
function Colors.opacity(Hex: string, Amount: number): string
	local RGB = channels(Hex)
	if RGB == nil then
		return Hex
	end

	local Opacity = math.clamp(Amount, 0, 1)
	if Opacity == 0 then
		return "#00000000"
	end

	local Alpha = math.floor(Opacity * 255 + 0.5)
	return string.format("#%02x%02x%02x%02x", RGB.Red, RGB.Green, RGB.Blue, Alpha)
end

return Colors
