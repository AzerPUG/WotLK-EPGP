if WOTLKEPGP == nil then WOTLKEPGP = {} end
WOTLKEPGP.InfoTable =
{
    ["Quality"] =
    {
        [2] = function(iLevel) return (iLevel - 4) / 2 end,
        [3] = function(iLevel) return (iLevel - 1.84) / 1.6 end,
        [4] = function(iLevel) return (iLevel - 1.3) / 1.3 end,
        [5] = function(iLevel) return iLevel / 0.9 end,     -- SelfMade, Legendary Quality. RealCalc?
    },
    ["Slot"] =
    {
        ["INVTYPE_HEAD"]           = 1,
        ["INVTYPE_ROBE"]           = 1,
        ["INVTYPE_CHEST"]          = 1,
        ["INVTYPE_LEGS"]           = 1,
        ["INVTYPE_2HWEAPON"]       = 1,

        ["INVTYPE_SHOULDER"]       = 0.777,
        ["INVTYPE_HAND"]           = 0.777,
        ["INVTYPE_WAIST"]          = 0.777,
        ["INVTYPE_FEET"]           = 0.777,

        ["INVTYPE_TRINKET"]        = 0.7,

        ["INVTYPE_WRIST"]          = 0.55,
        ["INVTYPE_NECK"]           = 0.55,
        ["INVTYPE_CLOAK"]          = 0.55,
        ["INVTYPE_FINGER"]         = 0.55,
        ["INVTYPE_HOLDABLE"]       = 0.55,
        ["INVTYPE_SHIELD"]         = 0.55,

        ["INVTYPE_WEAPON"]         = 0.42,
        ["INVTYPE_WEAPONMAINHAND"] = 0.42,
        ["INVTYPE_WEAPONOFFHAND"]  = 0.42,
        ["INVTYPE_RANGEDRIGHT"]    = 0.42,
        ["INVTYPE_RELIC"]          = 0.42,
    },
    ["PreCalculatedItems"] =
    {
        -- Tier 4 Token
        [29767] = { itemLevel = 120, itemQuality = 4, itemEquipLoc = "INVTYPE_LEGS"    , itemName =   "Leggings of the Fallen Defender",},
        [29753] = { itemLevel = 120, itemQuality = 4, itemEquipLoc = "INVTYPE_CHEST"   , itemName = "Chestguard of the Fallen Defender",},
        [29764] = { itemLevel = 120, itemQuality = 4, itemEquipLoc = "INVTYPE_SHOULDER", itemName =  "Pauldrons of the Fallen Defender",},
        [29758] = { itemLevel = 120, itemQuality = 4, itemEquipLoc = "INVTYPE_HAND"    , itemName =     "Gloves of the Fallen Defender",},
        [29761] = { itemLevel = 120, itemQuality = 4, itemEquipLoc = "INVTYPE_HEAD"    , itemName =       "Helm of the Fallen Defender",},

        [29765] = { itemLevel = 120, itemQuality = 4, itemEquipLoc = "INVTYPE_LEGS"    , itemName =   "Leggings of the Fallen Hero",},
        [29755] = { itemLevel = 120, itemQuality = 4, itemEquipLoc = "INVTYPE_CHEST"   , itemName = "Chestguard of the Fallen Hero",},
        [29762] = { itemLevel = 120, itemQuality = 4, itemEquipLoc = "INVTYPE_SHOULDER", itemName =  "Pauldrons of the Fallen Hero",},
        [29756] = { itemLevel = 120, itemQuality = 4, itemEquipLoc = "INVTYPE_HAND"    , itemName =     "Gloves of the Fallen Hero",},
        [29759] = { itemLevel = 120, itemQuality = 4, itemEquipLoc = "INVTYPE_HEAD"    , itemName =       "Helm of the Fallen Hero",},

        [29766] = { itemLevel = 120, itemQuality = 4, itemEquipLoc = "INVTYPE_LEGS"    , itemName =   "Leggings of the Fallen Champion",},
        [29754] = { itemLevel = 120, itemQuality = 4, itemEquipLoc = "INVTYPE_CHEST"   , itemName = "Chestguard of the Fallen Champion",},
        [29763] = { itemLevel = 120, itemQuality = 4, itemEquipLoc = "INVTYPE_SHOULDER", itemName =  "Pauldrons of the Fallen Champion",},
        [29757] = { itemLevel = 120, itemQuality = 4, itemEquipLoc = "INVTYPE_HAND"    , itemName =     "Gloves of the Fallen Champion",},
        [29760] = { itemLevel = 120, itemQuality = 4, itemEquipLoc = "INVTYPE_HEAD"    , itemName =       "Helm of the Fallen Champion",},

        -- Tier 5 Token
        [30246] = { itemLevel = 133, itemQuality = 4, itemEquipLoc = "INVTYPE_LEGS"    , itemName =   "Leggings of the Vanquished Defender",},
        [30237] = { itemLevel = 133, itemQuality = 4, itemEquipLoc = "INVTYPE_CHEST"   , itemName = "Chestguard of the Vanquished Defender",},
        [30249] = { itemLevel = 133, itemQuality = 4, itemEquipLoc = "INVTYPE_SHOULDER", itemName =  "Pauldrons of the Vanquished Defender",},
        [30240] = { itemLevel = 133, itemQuality = 4, itemEquipLoc = "INVTYPE_HAND"    , itemName =     "Gloves of the Vanquished Defender",},
        [30243] = { itemLevel = 133, itemQuality = 4, itemEquipLoc = "INVTYPE_HEAD"    , itemName =       "Helm of the Vanquished Defender",},

        [30247] = { itemLevel = 133, itemQuality = 4, itemEquipLoc = "INVTYPE_LEGS"    , itemName =   "Leggings of the Vanquished Hero",},
        [30238] = { itemLevel = 133, itemQuality = 4, itemEquipLoc = "INVTYPE_CHEST"   , itemName = "Chestguard of the Vanquished Hero",},
        [30250] = { itemLevel = 133, itemQuality = 4, itemEquipLoc = "INVTYPE_SHOULDER", itemName =  "Pauldrons of the Vanquished Hero",},
        [30241] = { itemLevel = 133, itemQuality = 4, itemEquipLoc = "INVTYPE_HAND"    , itemName =     "Gloves of the Vanquished Hero",},
        [30244] = { itemLevel = 133, itemQuality = 4, itemEquipLoc = "INVTYPE_HEAD"    , itemName =       "Helm of the Vanquished Hero",},

        [30245] = { itemLevel = 133, itemQuality = 4, itemEquipLoc = "INVTYPE_LEGS"    , itemName =   "Leggings of the Vanquished Champion",},
        [30236] = { itemLevel = 133, itemQuality = 4, itemEquipLoc = "INVTYPE_CHEST"   , itemName = "Chestguard of the Vanquished Champion",},
        [30248] = { itemLevel = 133, itemQuality = 4, itemEquipLoc = "INVTYPE_SHOULDER", itemName =  "Pauldrons of the Vanquished Champion",},
        [30239] = { itemLevel = 133, itemQuality = 4, itemEquipLoc = "INVTYPE_HAND"    , itemName =     "Gloves of the Vanquished Champion",},
        [30242] = { itemLevel = 133, itemQuality = 4, itemEquipLoc = "INVTYPE_HEAD"    , itemName =       "Helm of the Vanquished Champion",},

        -- Tier 6 Tokens
        [31098] = { itemLevel = 146, itemQuality = 4, itemEquipLoc = "INVTYPE_LEGS"    , itemName =   "Leggings of the Forgotten Conqueror",},
        [31089] = { itemLevel = 146, itemQuality = 4, itemEquipLoc = "INVTYPE_CHEST"   , itemName = "Chestguard of the Forgotten Conqueror",},
        [31101] = { itemLevel = 146, itemQuality = 4, itemEquipLoc = "INVTYPE_SHOULDER", itemName =  "Pauldrons of the Forgotten Conqueror",},
        [34853] = { itemLevel = 146, itemQuality = 4, itemEquipLoc = "INVTYPE_WAIST"   , itemName =       "Belt of the Forgotten Conqueror",},
        [34856] = { itemLevel = 146, itemQuality = 4, itemEquipLoc = "INVTYPE_FEET"    , itemName =      "Boots of the Forgotten Conqueror",},
        [31092] = { itemLevel = 146, itemQuality = 4, itemEquipLoc = "INVTYPE_HAND"    , itemName =     "Gloves of the Forgotten Conqueror",},
        [31097] = { itemLevel = 146, itemQuality = 4, itemEquipLoc = "INVTYPE_HEAD"    , itemName =       "Helm of the Forgotten Conqueror",},
        [34848] = { itemLevel = 146, itemQuality = 4, itemEquipLoc = "INVTYPE_WRIST"   , itemName =    "Bracers of the Forgotten Conqueror",},

        [31100] = { itemLevel = 146, itemQuality = 4, itemEquipLoc = "INVTYPE_LEGS"    , itemName =   "Leggings of the Forgotten Protector",},
        [31091] = { itemLevel = 146, itemQuality = 4, itemEquipLoc = "INVTYPE_CHEST"   , itemName = "Chestguard of the Forgotten Protector",},
        [31103] = { itemLevel = 146, itemQuality = 4, itemEquipLoc = "INVTYPE_SHOULDER", itemName =  "Pauldrons of the Forgotten Protector",},
        [34854] = { itemLevel = 146, itemQuality = 4, itemEquipLoc = "INVTYPE_WAIST"   , itemName =       "Belt of the Forgotten Protector",},
        [34857] = { itemLevel = 146, itemQuality = 4, itemEquipLoc = "INVTYPE_FEET"    , itemName =      "Boots of the Forgotten Protector",},
        [31094] = { itemLevel = 146, itemQuality = 4, itemEquipLoc = "INVTYPE_HAND"    , itemName =     "Gloves of the Forgotten Protector",},
        [31095] = { itemLevel = 146, itemQuality = 4, itemEquipLoc = "INVTYPE_HEAD"    , itemName =       "Helm of the Forgotten Protector",},
        [34851] = { itemLevel = 146, itemQuality = 4, itemEquipLoc = "INVTYPE_WRIST"   , itemName =    "Bracers of the Forgotten Protector",},

        [31099] = { itemLevel = 146, itemQuality = 4, itemEquipLoc = "INVTYPE_LEGS"    , itemName =   "Leggings of the Forgotten Vanquisher",},
        [31090] = { itemLevel = 146, itemQuality = 4, itemEquipLoc = "INVTYPE_CHEST"   , itemName = "Chestguard of the Forgotten Vanquisher",},
        [31102] = { itemLevel = 146, itemQuality = 4, itemEquipLoc = "INVTYPE_SHOULDER", itemName =  "Pauldrons of the Forgotten Vanquisher",},
        [34855] = { itemLevel = 146, itemQuality = 4, itemEquipLoc = "INVTYPE_WAIST"   , itemName =       "Belt of the Forgotten Vanquisher",},
        [34858] = { itemLevel = 146, itemQuality = 4, itemEquipLoc = "INVTYPE_FEET"    , itemName =      "Boots of the Forgotten Vanquisher",},
        [31093] = { itemLevel = 146, itemQuality = 4, itemEquipLoc = "INVTYPE_HAND"    , itemName =     "Gloves of the Forgotten Vanquisher",},
        [31096] = { itemLevel = 146, itemQuality = 4, itemEquipLoc = "INVTYPE_HEAD"    , itemName =       "Helm of the Forgotten Vanquisher",},
        [34852] = { itemLevel = 146, itemQuality = 4, itemEquipLoc = "INVTYPE_WRIST"   , itemName =    "Bracers of the Forgotten Vanquisher",},
    }
}

WOTLKEPGP.DataTable = {["Players"] = {},} -- DO NOT DELETE, DYNAMIC USE!
WOTLKEPGP.RegisteredEvents = {} -- DO NOT DELETE, DYNAMIC USE!