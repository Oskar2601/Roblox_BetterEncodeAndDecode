local httpService = game:GetService("HttpService")

local sanitizationDatatypes = { "Vector3", "Vector3int16", "Vector2", "Vector2int16", "CFrame", "EnumItem", "BrickColor", "Color3", "string", "number", "userdata", "UDim", "UDim2", "Rect", "TweenInfo", "Random", "NumberSequenceKeypoint", "NumberSequence", "ColorSequenceKeypoint", "ColorSequence", "CatalogSearchParams" }
local non_utf8_regex = '[\"\\\0-\31\127-\255]'

local function safeNumber(...)
   local nums = {...}
   for i, v in pairs(nums) do
      nums[i] = (v == v and v ~= math.huge) and v or tostring(v)
   end
   return unpack(nums)
end

local function safeString(...)
   local strings = {...}
   for i, v in pairs(strings) do
      strings[i] = tostring(v):gsub(non_utf8_regex, "")
   end
   return unpack(strings)
end

local function betterToNumber(...)
   local nums = {...}
   for i, v in pairs(nums) do
      nums[i] = tonumber(v)
   end
   return unpack(nums)
end

local function enumTableToNumberTbl(tbl)
   assert(type(tbl) == "table", "Bad argument #1 to toNumberEnumTable")
   for i, v in pairs(tbl) do
      if(typeof(v) ~= "EnumItem") then return {} end
      tbl[i] = v.Name
   end
   return tbl
end

local function sanitizeDataForJSONEncode(data: any)
   if(typeof(data) == "Vector3") then
      return {safeNumber(data.x, data.y, data.z)}
   end

   if(typeof(data) == "Vector3int16") then
      return {safeNumber(data.x, data.y, data.z)}
   end

   if(typeof(data) == "Vector2") then
      return {safeNumber(data.x, data.y)}
   end

   if(typeof(data) == "Vector2int16") then
      return {safeNumber(data.x, data.y)}
   end

   if(typeof(data) == "NumberSequence") then
      local keypoints = { }
      for i, v in pairs(data.Keypoints) do
         table.insert(keypoints, {safeNumber(v.Time, v.Value, v.Envelope)})
      end

      return keypoints
   end

   if(typeof(data) == "NumberSequenceKeypoint") then
      return {safeNumber(data.Time, data.Value, data.Envelope)}
   end

   if(typeof(data) == "ColorSequence") then
      local keypoints = { }
      for i, v in pairs(data.Keypoints) do
         table.insert(keypoints, {Time = safeNumber(v.Time), Color = {r = safeNumber(v.Value.r), g = safeNumber(v.Value.g), b = safeNumber(v.Value.b)}})
      end

      return keypoints
   end

   if(typeof(data) == "ColorSequenceKeypoint") then
      return {Time = safeNumber(data.Time), Color = {r = safeNumber(data.Value.r), g = safeNumber(data.Value.g), b = safeNumber(data.Value.b)}}
   end

   if(typeof(data) == "Random") then
      return nil
   end

   if(typeof(data) == "UDim") then
      return {Scale = safeNumber(data.Scale), Offset = safeNumber(data.Offset)}
   end

   if(typeof(data) == "UDim2") then
      return {safeNumber(data.X.Scale, data.X.Offset, data.Y.Scale, data.Y.Offset)}
   end

   if(typeof(data) == "Rect") then
      return {safeNumber(data.Min.x, data.Max.x, data.Max.y, data.Min.y)}
   end

   if(typeof(data) == "CatalogSearchParams") then
      local a = data
      return {SearchKeyword = safeString(a.SearchKeyword), MinPrice = safeNumber(a.MinPrice), MaxPrice = safeNumber(a.MaxPrice), SortType = safeString(a.SortType.Name), SortAggregation = safeString(a.SortAggregation.Name), CategoryFilter = safeString(a.CategoryFilter.Name), SalesTypeFilter = safeString(a.SalesTypeFilter.Name), BundleTypes = enumTableToNumberTbl(a.BundleTypes), AssetTypes = enumTableToNumberTbl(a.AssetTypes), IncludeOffSale = a.IncludeOffSale, CreatorName = safeString(a.CreatorName)}
   end

   if(typeof(data) == "TweenInfo") then
      return {safeNumber(data.Time), data.EasingStyle.Value, data.EasingDirection.Value, safeNumber(data.RepeatCount), data.Reverses, safeNumber(data.DelayTime)}
   end

   if(typeof(data) == "CFrame") then
      return {safeNumber(data:GetComponents())}
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

   ---@diagnostic disable-next-line: invalid-class-name
   if(typeof(data) == "userdata") then
      return nil
   end

   if(type(data) == "string") then
      return data:gsub(non_utf8_regex, "")
   end

   if(type(data) == "number") then
      return safeNumber(data)
   end

   return data
end

local function desantizeDataFromJSONEncode(data)
   if(data.dataType == "Vector3") then
      return Vector3.new(unpack(data.value))
   end

   if(data.dataType == "Vector3int16") then
      return Vector3int16.new(unpack(data.value))
   end

   if(data.dataType == "Vector2") then
      return Vector2.new(unpack(data.value))
   end

   if(data.dataType == "Vector2int16") then
      return Vector2int16.new(unpack(data.value))
   end

   if(data.dataType == "NumberSequence") then
      local tbl = {}
      for i, v in pairs(data.value) do
         print(unpack(v))
         table.insert(tbl, NumberSequenceKeypoint.new(unpack(v)))
      end
      return NumberSequence.new(tbl)
   end

   if(data.dataType == "NumberSequenceKeypoint") then
      return NumberSequenceKeypoint.new(unpack(data.value))
   end

   if(data.dataType == "ColorSequence") then
      local tbl = {}
      for i, v in pairs(data.value) do
         table.insert(tbl, ColorSequenceKeypoint.new(v.Time, Color3.new(v.Color.r, v.Color.g, v.Color.b)))
      end
      return ColorSequence.new(tbl)
   end

   if(data.dataType == "ColorSequenceKeypoint") then
      return ColorSequenceKeypoint.new(data.value.Time, Color3.new(data.value.Color.r, data.value.Color.g, data.value.Color.b))
   end

   if(data.dataType == "Random") then
      return Random.new(tick())
   end

   if(data.dataType == "UDim") then
      return UDim.new(data.value.Scale, data.value.Offset)
   end

   if(data.dataType == "UDim2") then
      return UDim2.new(unpack(data.value))
   end

   if(data.dataType == "Rect") then
      return Rect.new(unpack(data.value))
   end

   if(data.dataType == "CatalogSearchParams") then
      local params = CatalogSearchParams.new()
      local enumsLookup = {
         SortAggregation = "CatalogSortAggregation",
         CategoryFilter = "CatalogCategoryFilter",
         SalesTypeFilter = "SalesTypeFilter",
         SortType = "CatalogSortType"
      }

      for i, v in pairs(data.value) do
         if(enumsLookup[i]) then v = Enum[enumsLookup[i]][v] end
         params[i] = v
      end

      return params
   end

   if(data.dataType == "TweenInfo") then
      print(unpack(data.value))
      return TweenInfo.new(unpack(data.value))
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

   if(data.dataType == "userdata") then
      return newproxy(false)
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

function betterJSONEncode(tbl)
   assert(typeof(tbl) == "table", "Bad argument #1 to betterJSONEncode")

   sanitizeTableRecursive(tbl)
   return httpService:JSONEncode(tbl)
end

function betterJSONDecode(str)
   assert(typeof(str) == "string", "Bad argument #1 to betterJSONDecode")
   local tbl = httpService:JSONDecode(str)

   desanitizeTableRecursive(tbl)
   return tbl
end

local json = {
   Encode = betterJSONEncode,
   Decode = betterJSONDecode,
   Sanitize = sanitizeDataForJSONEncode,
   Desanitize = desantizeDataFromJSONEncode
}

return json
