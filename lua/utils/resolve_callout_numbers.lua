local names = {"insert_callout_reference", "resolve_varblocks"}
local utils = {}
for _, name in ipairs(names) do
    utils[name] = require("utils." .. name)
end

-- ========================== > resolve_numbers < =========================== --

-- ┌┌──────────────────────────────────────────────────────────────────────┐┐ --
-- ││ DESCRIPTION                                                          ││ --
-- ││ Resolves callout numbers based on formatting template.               ││ --
-- ││                                                                      ││ --
-- ││ ARGUMENTS:                                                           ││ --
-- ││ - id (string): The unique identifier for the callout.                ││ --
-- ││ - references (table):                                                ││ --
-- ││   <todo>                                                             ││ --
-- └└──────────────────────────────────────────────────────────────────────┘┘ --

local function resolve_callout_numbers(id, references)
    if id and id ~= "" then
        if references.callout_references[id] then

            references.callout_references[id].number = utils.resolve_varblocks({
                format = references.callout_references[id].format,
                placeholders = {
                    parent = utils.insert_callout_reference({
                        callout_id = references.callout_references[id].parents[1],
                        field = "number"
                    }),
                    self = utils.insert_callout_reference({
                        callout_id = id,
                        field = "no"
                    })

                }
            })

            references.callout_references[id].number = utils.resolve_varblocks({
                format = references.callout_references[id].number,
                placeholders = references.callout_references[id].header_counts
            })

        end
    end
end

-- ───────────────────────────── <end> ────────────────────────────────── --

return resolve_callout_numbers
