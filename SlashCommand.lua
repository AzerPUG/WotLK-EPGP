if TBCEPGP == nil then TBCEPGP = {} end
if TBCEPGP.SlashCommands == nil then
    TBCEPGP.SlashCommands = {}
    SLASH_EPGP1 = '/epgp'
    SlashCmdList['EPGP'] = function(arg)
        local spaceLoc = arg:find(" ")
        local command = arg:sub(0, spaceLoc - 1)
        local value = arg:sub(spaceLoc + 1, #arg)
        local fn = TBCEPGP.SlashCommands[command]
        if type(fn) == "function" then
            fn(value)
        end
    end
end