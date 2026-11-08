--!strict

local Colors = {}

type RGB = { Red: number, Green: number, Blue: number }
type HSL = { Hue: number, Saturation: number, Lightness: number }
type ColorMath = "byte-ratio"

local function ratioByte(Value: number): number
	return math.floor(math.clamp(Value, 0, 1) * 255 + 0.5)
end

local function ratioValue(Byte: number): number
	return Byte / 255
end

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
function Colors.mix(Source: string, Target: string, Amount: number, MathMode: ColorMath?): string
	local SourceRGB = channels(Source)
	local TargetRGB = channels(Target)
	if SourceRGB == nil or TargetRGB == nil then
		return Source
	end

	if MathMode == "byte-ratio" then
		local Percent = math.floor(math.clamp(Amount, 0, 1) * 100 + 0.5)
		local Weight = ratioByte(Percent / 100)
		local OtherWeight = 255 - Weight
		local function blend(SourceChannel: number, TargetChannel: number): number
			local SourcePart = ratioByte(ratioValue(SourceChannel) * ratioValue(Weight))
			local TargetPart = ratioByte(ratioValue(TargetChannel) * ratioValue(OtherWeight))
			return ratioByte(ratioValue(SourcePart) + ratioValue(TargetPart))
		end

		return hex(
			blend(SourceRGB.Red, TargetRGB.Red),
			blend(SourceRGB.Green, TargetRGB.Green),
			blend(SourceRGB.Blue, TargetRGB.Blue)
		)
	end

	local Fraction = math.clamp(Amount, 0, 1)
	return hex(
		TargetRGB.Red + (SourceRGB.Red - TargetRGB.Red) * Fraction,
		TargetRGB.Green + (SourceRGB.Green - TargetRGB.Green) * Fraction,
		TargetRGB.Blue + (SourceRGB.Blue - TargetRGB.Blue) * Fraction
	)
end

local function toHslContinuous(Color: RGB): HSL
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

local function hueChannelContinuous(P: number, Q: number, Hue: number): number
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

local function fromHslContinuous(Color: HSL): string
	if Color.Saturation == 0 then
		local Gray = Color.Lightness * 255
		return hex(Gray, Gray, Gray)
	end

	local Q = if Color.Lightness < 0.5
		then Color.Lightness * (1 + Color.Saturation)
		else Color.Lightness + Color.Saturation - Color.Lightness * Color.Saturation
	local P = 2 * Color.Lightness - Q
	return hex(
		hueChannelContinuous(P, Q, Color.Hue + 1 / 3) * 255,
		hueChannelContinuous(P, Q, Color.Hue) * 255,
		hueChannelContinuous(P, Q, Color.Hue - 1 / 3) * 255
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

	if Red == Green and Green == Blue then
		return { Hue = 0, Saturation = 0, Lightness = Color.Red }
	end

	if Maximum == Red then
		Hue = 60 * (Green - Blue) / Difference
	elseif Maximum == Green then
		Hue = 120 + 60 * (Blue - Red) / Difference
	else
		Hue = 240 + 60 * (Red - Green) / Difference
	end

	Saturation = if Lightness < 0.5
		then Difference / (Maximum + Minimum)
		else Difference / (2 - (Maximum + Minimum))

	return {
		Hue = math.floor(Hue + 0.5) % 360,
		Saturation = ratioByte(Saturation),
		Lightness = ratioByte(Lightness),
	}
end

local function rgbValue(Hue: number, First: number, Second: number): number
	local Value = Hue / 360
	if Value > 2 / 3 then
		return Second
	elseif Value > 1 / 2 then
		return Second + (First - Second) * (2 / 3 - Value) * 6
	elseif Value > 1 / 6 then
		return First
	end
	return Second + (First - Second) * Value * 6
end

local function fromHsl(Color: HSL): string
	local Saturation = ratioValue(Color.Saturation)
	local Lightness = ratioValue(Color.Lightness)
	if Color.Saturation == 0 then
		local Gray = ratioByte(Lightness)
		return hex(Gray, Gray, Gray)
	end

	local First = if Lightness < 0.5
		then Lightness * (1 + Saturation)
		else (Lightness + Saturation) - Lightness * Saturation
	local Second = 2 * Lightness - First
	return hex(
		ratioByte(rgbValue((Color.Hue + 120) % 360, First, Second)),
		ratioByte(rgbValue(Color.Hue, First, Second)),
		ratioByte(rgbValue((Color.Hue - 120) % 360, First, Second))
	)
end

--- shade adjusts HSL lightness while preserving hue and saturation.
function Colors.shade(Hex: string, Amount: number, MathMode: ColorMath?): string
	local RGB = channels(Hex)
	if RGB == nil then
		return Hex
	end

	if MathMode ~= "byte-ratio" then
		local HSL = toHslContinuous(RGB)
		HSL.Lightness = math.clamp(HSL.Lightness + Amount, 0, 1)
		return fromHslContinuous(HSL)
	end

	local HSL = toHsl(RGB)
	local Percent = math.floor(math.clamp(math.abs(Amount), 0, 1) * 100 + 0.5)
	local LightnessChange = ratioByte(Percent / 100)
	local SignedChange = if Amount < 0 then -LightnessChange else LightnessChange
	HSL.Lightness = ratioByte(ratioValue(HSL.Lightness) + ratioValue(SignedChange))
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
