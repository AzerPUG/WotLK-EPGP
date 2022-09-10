if WOTLKEPGP == nil then WOTLKEPGP = {} end
if WOTLKEPGP.SlashCommands == nil then
    WOTLKEPGP.SlashCommands = {}
    SLASH_EPGP1 = '/epgp'
    SlashCmdList['EPGP'] = function(arg)
        local spaceLoc = arg:find(" ")
        local command, value = nil, nil
        if spaceLoc == nil then
            command = arg
            value = nil
        else
            command = arg:sub(0, spaceLoc - 1)
            value = arg:sub(spaceLoc + 1, #arg)
        end
        local fn = WOTLKEPGP.SlashCommands[command]
        if type(fn) == "function" then
            fn(value)
        end
    end
end