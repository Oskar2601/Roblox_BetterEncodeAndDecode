local httpService = game:GetService("HttpService")

local sanitizationDatatypes = { "Vector3", "CFrame", "EnumItem", "BrickColor", "Color3", "string", "number" }
local non_utf8_regex = '[\"\\\0-\31\127-\255]'

local function sanitizeDataForJSONEncode(data: any)
   if(typeof(data) == "Vector3") then
      return {x = tostring(data.x), y = tostring(data.y), z = tostring(data.z)}
   end

   if(typeof(data) == "CFrame") then
      return {data:GetComponents()}
   end

   if(typeof(data) == "EnumItem") then
      return data.Value
   end

   if(typeof(data) == "BrickColor") then
      return tostring(data)
   end

   if(typeof(data) == "Color3") then
      return {r = data.r, g = data.g, b = data.b}
   end

   if(type(data) == "string") then
      return data:gsub(non_utf8_regex, "")
   end

   if(type(data) == "number") then
      return (data == data and data ~= math.huge) and data or tostring(data)
   end

   return data
end

local function desantizeDataFromJSONEncode(data)
   if(data.dataType == "Vector3") then
      return Vector3.new(data.value.x, data.value.y, data.value.z)
   end

   if(data.dataType == "CFrame") then
      return CFrame.new(unpack(data.value))
   end

   if(data.dataType == "EnumItem") then
      return data.value
   end

   if(data.dataType == "BrickColor") then
      return BrickColor.new(data.value)
   end

   if(data.dataType == "Color3") then
      print(data)
      return Color3.new(data.value.r, data.value.g, data.value.b)
   end

   if(data.dataType == "number") then
      return tonumber(data.value)
   end

   return data.value
end

local maxStackCalls = 600 -- roblox stack size: 19996
local stack1, stack2 = 0, 0
local function sanitizeTableRecursive(parent)
   stack1 += 1; if(stack1 >= maxStackCalls) then warn("Hit callstack limit during sanitization (probaby a huge table?)") return end
   for i, v in pairs(parent) do
      if(table.find(sanitizationDatatypes, typeof(v))) then parent[i] = { dataType = typeof(v), value = sanitizeDataForJSONEncode(v) } continue end
      if(type(v) == "table") then sanitizeTableRecursive(v) end
   end
end

local function desanitizeTableRecursive(parent)
   stack2 += 1; if(stack2 >= maxStackCalls) then warn("Hit callstack limit during desanitization (probaby a huge table?)") return end
   for i, v in pairs(parent) do
      if(type(v) ~= "table") then continue end
      if(v.dataType) then parent[i] = desantizeDataFromJSONEncode(v) continue end
      desanitizeTableRecursive(v)
   end
end

function betterHttpEncode(tbl)
   assert(typeof(tbl) == "table", "Bad argument #1 to betterHttpEncode")

   sanitizeTableRecursive(tbl)
   return httpService:JSONEncode(tbl)
end

function betterHttpDecode(str)
   assert(typeof(str) == "string", "Bad argument #1 to betterHttpDecode")
   local tbl = httpService:JSONDecode(str)

   desanitizeTableRecursive(tbl)
   return tbl
end





local encoded = betterHttpEncode({
   cframe = CFrame.new(1, 5, 6),
   vector3 = Vector3.new(4, 9, 8),
   nanNumber = 0/0,
   color3 = Color3.new(.5, .2, .9),
   brickColor = BrickColor.new("Bright blue")
})


local decodedTbl = betterHttpDecode(encoded)
for i, v in pairs(decodedTbl) do
   print(i, v)
end

--[[
   output:
      color3 = 0.5, 0.2, 0.9
      nanNumber = nan
      cframe = 1, 5, 6, 1, 0, 0, 0, 1, 0, 0, 0, 1
      brickColor = Bright blue
      vector3 = 4, 9, 8
]]--
