local Enums = {}

-------------------------------------------------------------------------------------------------------------------
local Types = require(workspace.Types)
local RegistryService: Types.RegistryService = require(`../Services/RegistryService`)

local Combinatorics: SharedTable = RegistryService:WaitForSharedTable(`Combinatorics`)
type Vector = Vector3 | Vector2 | Vector2int16 | Vector3int16 | vector

-------------------------------------------------------------------------------------------------------------------
local function Lerp(A: Vector, B: Vector, Alpha: number): Vector
	return A + (B - A) * Alpha
end

-------------------------------------------------------------------------------------------------------------------
local function FlatEnough(Points: {Vector}, Tolerance: number): boolean
	local Start: Vector = Points[1]
	local EndPoint: Vector = Points[#Points]
	local Line: Vector = EndPoint - Start
	local LengthSquared: number = Line:Dot(Line)

	if LengthSquared == 0 then return true end

	for Index: number = 2, #Points - 1 do
		local Offset: Vector = Points[Index] - Start
		local Projection: number = Offset:Dot(Line) / LengthSquared
		local ClosestPoint: Vector = Start + Line * Projection
		local Distance: number = (Points[Index] - ClosestPoint).Magnitude
		if Distance <= Tolerance then continue end
		return false
	end

	return true
end


-------------------------------------------------------------------------------------------------------------------
Enums.BackOff = {}

Enums.BackOff.Constant = function(Attempt: number): number return 5 end
Enums.BackOff.Linear = function(Attempt: number): number return 2 * Attempt + 3 end
Enums.BackOff.Exponential = function(Attempt: number): number return 2 ^ Attempt end

export type BackOff = typeof(Enums.BackOff)

-------------------------------------------------------------------------------------------------------------------
Enums.Observer = {}

Enums.Observer.Property = `Property`
Enums.Observer.Attribute = `Attribute`

export type Observer = typeof(Enums.Observer)

-------------------------------------------------------------------------------------------------------------------
Enums.BezierCompute = {}

Enums.BezierCompute.Bernstien = function(Curve: Bezier, Alpha: number): Vector
	local Degree: number = Curve.Degree
	local Points: {Vector} = Curve.Points
	local Result: Vector = Points[1] * 0

	for Index: number = 0, Degree do
		local Coefficient: number = Combinatorics[Degree][Index]
		local Basis: number = Coefficient * (Alpha ^ Index) * ((1 - Alpha) ^ (Degree - Index))

		Result += Points[Index + 1] * Basis
	end

	return Result
end

Enums.BezierCompute.DeCasteljau = function(Curve: Bezier, Alpha: number): Vector
	local Working: {Vector} = table.clone(Curve.Points)
	local Count: number = #Working

	for Level: number = 1, Count - 1 do
		for Index: number = 1, Count - Level do
			Working[Index] = Lerp(Working[Index], Working[Index + 1], Alpha)
		end
	end

	return Working[1]
end

export type BezierCompute = typeof(Enums.BezierCompute)

-------------------------------------------------------------------------------------------------------------------
Enums.BezierSampling = {}

Enums.BezierSampling.Default = function(Curve: Bezier, Tolerance: number)
	local Size: number = Curve.Size
	local Compute = Curve.ComputeFunction
	for Index: number = 1, Size do Curve.LookupTable[Index] = Compute(Curve, (Index - 1) / (Size - 1)) end
end

Enums.BezierSampling.Adaptive = function(Curve: Bezier, Tolerance: number)
	local Result: {Vector} = {}

	local function Subdivide(Points: {Vector})
		if FlatEnough(Points, Tolerance) then table.insert(Result, Points[1]) return end

		local Left: {Vector} = {}
		local Right: {Vector} = {}
		local Working: {Vector} = table.clone(Points)
		local Count: number = #Working

		Left[1] = Working[1]
		Right[Count] = Working[Count]

		for Level: number = 1, Count - 1 do
			for Index: number = 1, Count - Level do
				Working[Index] = Lerp(Working[Index], Working[Index + 1], 0.5)
			end

			Left[Level + 1] = Working[1]
			Right[Count - Level] = Working[Count - Level]
		end

		Subdivide(Left)
		Subdivide(Right)
	end

	Subdivide(Curve.Points)
	table.insert(Result, Curve.Points[#Curve.Points])

	Curve.LookupTable = Result
	Curve.Size = #Result
end

export type BezierSampling = typeof(Enums.BezierSampling)

-------------------------------------------------------------------------------------------------------------------
return Enums
