local names = {"assert_argument","callout_field_regex_pattern"}
local utils = {}
for _, name in ipairs(names) do
    utils[name] = require("utils." .. name)
end

-- ===================== > resolve_callout_reference < ====================== --
-- ┌┌──────────────────────────────────────────────────────────────────────┐┐ --
-- ││ DESCRIPTION                                                          ││ --
-- ││ Resolves a single callout reference                                  ││ --
-- ││                                                                      ││ --
-- ││ ARGUMENTS:                                                           ││ --
-- ││ - options (table):                                                   ││ --
-- ││   <todo>                                                             ││ --
-- ││ - references (table):                                                ││ --
-- ││   <todo>                                                             ││ --
-- └└──────────────────────────────────────────────────────────────────────┘┘ --

local function resolve_callout_reference(options, references)
    -- Ensure options is a table
    assert(type(options) == "table", "Expected a table for 'options' but got " .. type(options))

    -- Make sure arguments are of appropriate type
    if options.callout_id then
        utils.assert_argument({
            arguments = options,
            name = "callout_id",
            type = "string"
        })
    end

    utils.assert_argument({
        arguments = references,
        name = "callout_references",
        type = "table"
    })

    utils.assert_argument({
        arguments = options,
        name = "field",
        type = "string"
    })

    references.callout_references[options.callout_id][options.field] = string.gsub(
        references.callout_references[options.callout_id][options.field], utils.callout_field_regex_pattern(),
        function(id, field)
            return references.callout_references[id][field]
        end)
end
-- ───────────────────────────────── <end> ────────────────────────────────── --

return resolve_callout_reference
