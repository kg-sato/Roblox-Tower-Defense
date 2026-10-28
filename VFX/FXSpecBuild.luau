--!nocheck
-- Builds an instance tree from a JSON spec made by tools/rbxl_tree.py (--spec): {c = class, p = props, k = children}.
-- Used to rebuild a reference effect exactly as its .rbxl stores it, so ours can be compared in the same engine.
-- Value shapes: [[t,v,e],...] NumberSequence, [[t,r,g,b,e],...] ColorSequence, 2-list NumberRange or Vector2,
-- 3-list Color3 or Vector3, 12-list CFrame. Unknown or read-only properties are skipped silently.
local HttpService = game:GetService("HttpService")

local RANGE = { Lifetime = true, Speed = true, Rotation = true, RotSpeed = true }
local VEC2 = { SpreadAngle = true, FlipbookFramerate = true }

local function convert(cls, k, v)
	if type(v) ~= "table" then
		return v
	end
	local n = #v
	if n > 0 and type(v[1]) == "table" then
		if #v[1] == 5 then
			local kps = {}
			for _, x in v do
				table.insert(kps, ColorSequenceKeypoint.new(x[1], Color3.new(x[2], x[3], x[4])))
			end
			return ColorSequence.new(kps)
		end
		local kps = {}
		for _, x in v do
			table.insert(kps, NumberSequenceKeypoint.new(x[1], x[2], x[3] or 0))
		end
		return NumberSequence.new(kps)
	end
	if n == 2 then
		if RANGE[k] then
			return NumberRange.new(math.min(v[1], v[2]), math.max(v[1], v[2]))
		end
		return Vector2.new(v[1], v[2])
	end
	if n == 3 then
		if string.find(k, "Color") then
			return Color3.new(v[1], v[2], v[3])
		end
		return Vector3.new(v[1], v[2], v[3])
	end
	if n == 12 then
		return CFrame.new(table.unpack(v))
	end
	return nil
end

local function build(node, parent, ids, refs)
	local inst = Instance.new(node.c)
	if node.id then
		ids[node.id] = inst
	end
	for k, v in node.p do
		if type(v) == "table" and v.ref then
			table.insert(refs, { inst, k, v.ref })
			continue
		end
		local key = (k == "size") and "Size" or k
		local val = convert(node.c, key, v)
		if val ~= nil then
			pcall(function()
				inst[key] = val
			end)
		end
	end
	for _, child in node.k or {} do
		build(child, inst, ids, refs)
	end
	inst.Parent = parent
	return inst
end

-- Returns the built root. Reference props (Beam.Attachment0/1, Weld.Part0/1 ...) are linked after the whole tree exists.
return function(spec, parent)
	if type(spec) == "string" then
		spec = HttpService:JSONDecode(spec)
	end
	local ids, refs = {}, {}
	local root = build(spec, parent, ids, refs)
	for _, r in refs do
		if ids[r[3]] then
			pcall(function()
				r[1][r[2]] = ids[r[3]]
			end)
		end
	end
	return root
end
