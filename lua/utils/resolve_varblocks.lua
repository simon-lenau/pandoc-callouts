local names = {"assert_argument"}
local utils = {}
for _, name in ipairs(names) do
    utils[name] = require("utils." .. name)
end

local function var(varname)
    return "{{" .. varname .. "}}"
end

-- ========================= > resolve_varblocks < ========================== --

-- ┌┌──────────────────────────────────────────────────────────────────────┐┐ --
-- ││ DESCRIPTION                                                          ││ --
-- ││ Resolves variable blocks in number formatting templates              ││ --
-- ││                                                                      ││ --
-- ││ ARGUMENTS:                                                           ││ --
-- ││ - options (table):                                                   ││ --
-- ││   <todo>                                                             ││ --
-- ││ - references (table):                                                ││ --
-- ││   <todo>                                                             ││ --
-- └└──────────────────────────────────────────────────────────────────────┘┘ --

local function resolve_varblocks(options)
    -- Ensure options is a table
    assert(type(options) == "table", "Expected a table for 'options' but got " .. type(options))

    if not options.placeholders then
        options.placeholders = {}
    end

    -- Make sure arguments are of appropriate type
    utils.assert_argument({
        arguments = options,
        name = "format",
        type = "string"
    })

    utils.assert_argument({
        arguments = options,
        name = "placeholders",
        type = "table"
    })

    local result = options.format

    -- Resolve placeholders
    for key, val in pairs(options.placeholders) do
        if string.find(result, var(key)) then
            result = result:gsub(var(key), (val or "_"))
        end
    end

    -- Resolve 'or' statements
    result = string.gsub(result, "%{%{%s*(.-)%s*or%s*(.+)%s*%}%}", function(a, b)
        if a and a ~= "" then
            return a
        else
            return b
        end
    end)

    return result

end
-- ───────────────────────────────── <end> ────────────────────────────────── --

return resolve_varblocks
