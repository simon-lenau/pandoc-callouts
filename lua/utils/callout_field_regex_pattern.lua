local names = {"insert_callout_reference"}
local utils = {}
for _, name in ipairs(names) do
    utils[name] = require("utils." .. name)
end

-- ==================== > callout_field_regex_pattern < ===================== --

-- ┌┌──────────────────────────────────────────────────────────────────────┐┐ --
-- ││ DESCRIPTION                                                          ││ --
-- ││ This function generates regex patterns for callout field references  ││ --
-- ││ for subsequent use in regex operations.                              ││ --
-- └└──────────────────────────────────────────────────────────────────────┘┘ --

-- ==================== > callout_field_regex_pattern < ===================== --

local function callout_field_regex_pattern()
    -- Define regex pattern
    local pattern = utils.insert_callout_reference({
        callout_id = "__capture__",
        field = "__capture__"
    })

    -- Escape brackets
    pattern = string.gsub(pattern, "([%[%(%{%}%)%]])", function(a)
        return "%" .. a
    end)

    -- Insert capture groups after escaping brackets
    pattern = string.gsub(pattern, "__capture__", "(.-)")
    return pattern
end

-- ───────────────────────────────── <end> ────────────────────────────────── --

return callout_field_regex_pattern
