local names = {"yaml_to_table","define_callout_type"}
local utils = {}
for _, name in ipairs(names) do
    utils[name] = require("utils." .. name)
end



-- ============================ > process_yaml < ============================ --

-- ┌┌──────────────────────────────────────────────────────────────────────┐┐ --
-- ││ This will define callout types based on the yaml header_counts       ││ --
-- └└──────────────────────────────────────────────────────────────────────┘┘ --

local function process_yaml(meta,references)
    local callout_types = meta['callout-types']
    if type(callout_types) ~= "table" then
        return meta
    end

    local callout_types_tbl = utils.yaml_to_table(callout_types)

    for class, _ in pairs(callout_types_tbl) do
        utils.define_callout_type(callout_types_tbl[class], references)
    end
end

-- ───────────────────────────────── <end> ────────────────────────────────── --

return process_yaml