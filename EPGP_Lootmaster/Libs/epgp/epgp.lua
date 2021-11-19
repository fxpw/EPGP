--[[
  EP/GP Item GP value calculation
  All credit to the Alkis at http://code.google.com/p/epgp/
]]

-- This is the high price equipslot multiplier.
local EQUIPSLOT_MULTIPLIER_1 = {
  INVTYPE_HEAD = 1,
  INVTYPE_NECK = 0.5,
  INVTYPE_SHOULDER = 0.75,
  INVTYPE_CHEST = 1,
  INVTYPE_ROBE = 1,
  INVTYPE_WAIST = 0.75,
  INVTYPE_LEGS = 1,
  INVTYPE_FEET = 0.75,
  INVTYPE_WRIST = 0.5,
  INVTYPE_HAND = 0.75,
  INVTYPE_FINGER = 0.5,
  INVTYPE_TRINKET = 0.75,
  INVTYPE_CLOAK = 0.5,
  INVTYPE_WEAPON = 1.5,
  INVTYPE_SHIELD = 1.5,
  INVTYPE_2HWEAPON = 2,
  INVTYPE_WEAPONMAINHAND = 1.5,
  INVTYPE_WEAPONOFFHAND = 0.5,
  INVTYPE_HOLDABLE = 0.5,
  INVTYPE_RANGED = 1.5,
  INVTYPE_RANGEDRIGHT = 1.5,
  INVTYPE_THROWN = 0.5,
  INVTYPE_RELIC = 0.5
}

-- This is the low price equipslot multiplier (off hand weapons, non
-- tanking shields).
local EQUIPSLOT_MULTIPLIER_2 = {
  INVTYPE_WEAPON = 0.5,
  INVTYPE_SHIELD = 0.5,
  INVTYPE_2HWEAPON = 1,
  INVTYPE_RANGED = 0.5,
  INVTYPE_RANGEDRIGHT = 0.5,
}

--Used to display GP values directly on tier tokens
local CUSTOM_ITEM_DATA = {
  -- Tier 4
  [29753] = { 4, 120, "INVTYPE_CHEST" },
  [29754] = { 4, 120, "INVTYPE_CHEST" },
  [29755] = { 4, 120, "INVTYPE_CHEST" },
  [29756] = { 4, 120, "INVTYPE_HAND" },
  [29757] = { 4, 120, "INVTYPE_HAND" },
  [29758] = { 4, 120, "INVTYPE_HAND" },
  [29759] = { 4, 120, "INVTYPE_HEAD" },
  [29760] = { 4, 120, "INVTYPE_HEAD" },
  [29761] = { 4, 120, "INVTYPE_HEAD" },
  [29762] = { 4, 120, "INVTYPE_SHOULDER" },
  [29763] = { 4, 120, "INVTYPE_SHOULDER" },
  [29764] = { 4, 120, "INVTYPE_SHOULDER" },
  [29765] = { 4, 120, "INVTYPE_LEGS" },
  [29766] = { 4, 120, "INVTYPE_LEGS" },
  [29767] = { 4, 120, "INVTYPE_LEGS" },

  -- Tier 5
  [30236] = { 4, 133, "INVTYPE_CHEST" },
  [30237] = { 4, 133, "INVTYPE_CHEST" },
  [30238] = { 4, 133, "INVTYPE_CHEST" },
  [30239] = { 4, 133, "INVTYPE_HAND" },
  [30240] = { 4, 133, "INVTYPE_HAND" },
  [30241] = { 4, 133, "INVTYPE_HAND" },
  [30242] = { 4, 133, "INVTYPE_HEAD" },
  [30243] = { 4, 133, "INVTYPE_HEAD" },
  [30244] = { 4, 133, "INVTYPE_HEAD" },
  [30245] = { 4, 133, "INVTYPE_LEGS" },
  [30246] = { 4, 133, "INVTYPE_LEGS" },
  [30247] = { 4, 133, "INVTYPE_LEGS" },
  [30248] = { 4, 133, "INVTYPE_SHOULDER" },
  [30249] = { 4, 133, "INVTYPE_SHOULDER" },
  [30250] = { 4, 133, "INVTYPE_SHOULDER" },

  -- Tier 5 - BoE recipes - BoP crafts
  [30282] = { 4, 128, "INVTYPE_BOOTS" },
  [30283] = { 4, 128, "INVTYPE_BOOTS" },
  [30305] = { 4, 128, "INVTYPE_BOOTS" },
  [30306] = { 4, 128, "INVTYPE_BOOTS" },
  [30307] = { 4, 128, "INVTYPE_BOOTS" },
  [30308] = { 4, 128, "INVTYPE_BOOTS" },
  [30323] = { 4, 128, "INVTYPE_BOOTS" },
  [30324] = { 4, 128, "INVTYPE_BOOTS" },

  -- Tier 6
  [31089] = { 4, 146, "INVTYPE_CHEST" },
  [31090] = { 4, 146, "INVTYPE_CHEST" },
  [31091] = { 4, 146, "INVTYPE_CHEST" },
  [31092] = { 4, 146, "INVTYPE_HAND" },
  [31093] = { 4, 146, "INVTYPE_HAND" },
  [31094] = { 4, 146, "INVTYPE_HAND" },
  [31095] = { 4, 146, "INVTYPE_HEAD" },
  [31096] = { 4, 146, "INVTYPE_HEAD" },
  [31097] = { 4, 146, "INVTYPE_HEAD" },
  [31098] = { 4, 146, "INVTYPE_LEGS" },
  [31099] = { 4, 146, "INVTYPE_LEGS" },
  [31100] = { 4, 146, "INVTYPE_LEGS" },
  [31101] = { 4, 146, "INVTYPE_SHOULDER" },
  [31102] = { 4, 146, "INVTYPE_SHOULDER" },
  [31103] = { 4, 146, "INVTYPE_SHOULDER" },
  [34848] = { 4, 154, "INVTYPE_WRIST" },
  [34851] = { 4, 154, "INVTYPE_WRIST" },
  [34852] = { 4, 154, "INVTYPE_WRIST" },
  [34853] = { 4, 154, "INVTYPE_WAIST" },
  [34854] = { 4, 154, "INVTYPE_WAIST" },
  [34855] = { 4, 154, "INVTYPE_WAIST" },
  [34856] = { 4, 154, "INVTYPE_FEET" },
  [34857] = { 4, 154, "INVTYPE_FEET" },
  [34858] = { 4, 154, "INVTYPE_FEET" },

  -- Tier 6 - BoE recipes - BoP crafts
  [32737] = { 4, 141, "INVTYPE_SHOULDER" },
  [32739] = { 4, 141, "INVTYPE_SHOULDER" },
  [32745] = { 4, 141, "INVTYPE_SHOULDER" },
  [32747] = { 4, 141, "INVTYPE_SHOULDER" },
  [32749] = { 4, 141, "INVTYPE_SHOULDER" },
  [32751] = { 4, 141, "INVTYPE_SHOULDER" },
  [32753] = { 4, 141, "INVTYPE_SHOULDER" },
  [32755] = { 4, 141, "INVTYPE_SHOULDER" },

  -- Magtheridon's Head
  [32385] = { 4, 125, "INVTYPE_FINGER" },
  [32386] = { 4, 125, "INVTYPE_FINGER" },

  -- Kael'thas' Sphere
  [32405] = { 4, 138, "INVTYPE_NECK" },

  -- T7
  [40610] = { 4, 200, "INVTYPE_CHEST" },
  [40611] = { 4, 200, "INVTYPE_CHEST" },
  [40612] = { 4, 200, "INVTYPE_CHEST" },
  [40613] = { 4, 200, "INVTYPE_HAND" },
  [40614] = { 4, 200, "INVTYPE_HAND" },
  [40615] = { 4, 200, "INVTYPE_HAND" },
  [40616] = { 4, 200, "INVTYPE_HEAD" },
  [40617] = { 4, 200, "INVTYPE_HEAD" },
  [40618] = { 4, 200, "INVTYPE_HEAD" },
  [40619] = { 4, 200, "INVTYPE_LEGS" },
  [40620] = { 4, 200, "INVTYPE_LEGS" },
  [40621] = { 4, 200, "INVTYPE_LEGS" },
  [40622] = { 4, 200, "INVTYPE_SHOULDER" },
  [40623] = { 4, 200, "INVTYPE_SHOULDER" },
  [40624] = { 4, 200, "INVTYPE_SHOULDER" },

  -- T7 (heroic)
  [40625] = { 4, 213, "INVTYPE_CHEST" },
  [40626] = { 4, 213, "INVTYPE_CHEST" },
  [40627] = { 4, 213, "INVTYPE_CHEST" },
  [40628] = { 4, 213, "INVTYPE_HAND" },
  [40629] = { 4, 213, "INVTYPE_HAND" },
  [40630] = { 4, 213, "INVTYPE_HAND" },
  [40631] = { 4, 213, "INVTYPE_HEAD" },
  [40632] = { 4, 213, "INVTYPE_HEAD" },
  [40633] = { 4, 213, "INVTYPE_HEAD" },
  [40634] = { 4, 213, "INVTYPE_LEGS" },
  [40635] = { 4, 213, "INVTYPE_LEGS" },
  [40636] = { 4, 213, "INVTYPE_LEGS" },
  [40637] = { 4, 213, "INVTYPE_SHOULDER" },
  [40638] = { 4, 213, "INVTYPE_SHOULDER" },
  [40639] = { 4, 213, "INVTYPE_SHOULDER" },

  -- Key to the Focusing Iris
  [44569] = { 4, 213, "INVTYPE_NECK" },
  [44577] = { 4, 226, "INVTYPE_NECK" },

  -- T8
  [45635] = { 4, 219, "INVTYPE_CHEST" },
  [45636] = { 4, 219, "INVTYPE_CHEST" },
  [45637] = { 4, 219, "INVTYPE_CHEST" },
  [45647] = { 4, 219, "INVTYPE_HEAD" },
  [45648] = { 4, 219, "INVTYPE_HEAD" },
  [45649] = { 4, 219, "INVTYPE_HEAD" },
  [45644] = { 4, 219, "INVTYPE_HAND" },
  [45645] = { 4, 219, "INVTYPE_HAND" },
  [45646] = { 4, 219, "INVTYPE_HAND" },
  [45650] = { 4, 219, "INVTYPE_LEGS" },
  [45651] = { 4, 219, "INVTYPE_LEGS" },
  [45652] = { 4, 219, "INVTYPE_LEGS" },
  [45659] = { 4, 219, "INVTYPE_SHOULDER" },
  [45660] = { 4, 219, "INVTYPE_SHOULDER" },
  [45661] = { 4, 219, "INVTYPE_SHOULDER" },

  -- T8 (heroic)
  [45632] = { 4, 226, "INVTYPE_CHEST" },
  [45633] = { 4, 226, "INVTYPE_CHEST" },
  [45634] = { 4, 226, "INVTYPE_CHEST" },
  [45638] = { 4, 226, "INVTYPE_HEAD" },
  [45639] = { 4, 226, "INVTYPE_HEAD" },
  [45640] = { 4, 226, "INVTYPE_HEAD" },
  [45641] = { 4, 226, "INVTYPE_HAND" },
  [45642] = { 4, 226, "INVTYPE_HAND" },
  [45643] = { 4, 226, "INVTYPE_HAND" },
  [45653] = { 4, 226, "INVTYPE_LEGS" },
  [45654] = { 4, 226, "INVTYPE_LEGS" },
  [45655] = { 4, 226, "INVTYPE_LEGS" },
  [45656] = { 4, 226, "INVTYPE_SHOULDER" },
  [45657] = { 4, 226, "INVTYPE_SHOULDER" },
  [45658] = { 4, 226, "INVTYPE_SHOULDER" },

  -- Archivum Data Disc
  [45857] = { 4, 239, "INVTYPE_RING" },
  [45506] = { 4, 226, "INVTYPE_RING" },
}

local GPTooltip = nil
local GP = LibStub("LibGearPoints-1.0", true) -- Load this library silent

GetCustomSlotInfo = function(itemLink)
  if not itemLink then return end

  if GP and GP.GetValue then
    local high, low, level, rarity, equipLoc = GP:GetValue(itemLink)
    return equipLoc, rarity, level
  end

  -- Get the item ID to check against known token IDs
  local itemID = tonumber(string.match(itemLink, "item:(%d+)"))
  -- Check to see if there is custom data for this item ID
  local rarity, level, equipLoc
  if CUSTOM_ITEM_DATA[itemID] then
    rarity, level, equipLoc = unpack(CUSTOM_ITEM_DATA[itemID])
  else
    _, _, rarity, level, _, _, _, _, equipLoc = GetItemInfo(itemLink)
  end
  return equipLoc, rarity, level
end

GetGPValue = function (itemLink)
  if not itemLink then return end

  if GP and GP.GetValue then return GP:GetValue(itemLink) end
  if EPGP then    
    if not GPTooltip then GPTooltip = EPGP:GetModule("EPGP_GPTooltip", true) end
    if not GPTooltip then GPTooltip = EPGP:GetModule("gptooltip", true) end
    if GPTooltip and GPTooltip.GetGPValue then return GPTooltip:GetGPValue(itemLink) end
  end

  -- Get the item ID to check against known token IDs
  local itemID = tonumber(string.match(itemLink, "item:(%d+)"))
  -- Check to see if there is custom data for this item ID
  local rarity, level, equipLoc
  if CUSTOM_ITEM_DATA[itemID] then
    rarity, level, equipLoc = unpack(CUSTOM_ITEM_DATA[itemID])
  else
    _, _, rarity, level, _, _, _, _, equipLoc = GetItemInfo(itemLink)
  end

  -- Non-rare and above items do not have GP value
  if rarity and rarity < 2 then
    return nil, nil, level, rarity, equipLoc
  end

  local slot_multiplier1 = EQUIPSLOT_MULTIPLIER_1[equipLoc]
  local slot_multiplier2 = EQUIPSLOT_MULTIPLIER_2[equipLoc]

  if not slot_multiplier1 then return nil, nil, level, rarity, equipLoc end
  local gp_base = 0.483 * 2 ^ (level/26 + (rarity - 4))
  local high = math.floor(gp_base * slot_multiplier1)
  local low = slot_multiplier2 and math.floor(gp_base * slot_multiplier2) or nil
  return high, low, level, rarity, equipLoc
end
