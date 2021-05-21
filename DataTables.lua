if TBCEPGP == nil then TBCEPGP = {} end
TBCEPGP.InfoTable =
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
}
TBCEPGP.DataTable =
{
    ["Players"] =
    {

    },
	["Dates"] =
    {

    },
}

TBCEPGP.RegisteredEvents = {} -- DO NOT DELETE, DYNAMIC USE!