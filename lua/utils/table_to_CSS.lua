-- ============================ > table_to_CSS < ============================ --

-- ┌┌──────────────────────────────────────────────────────────────────────┐┐ --
-- ││ Format style table as CSS string                                     ││ --
-- └└──────────────────────────────────────────────────────────────────────┘┘ --

local function table_to_CSS(tbl, concat)
    -- Make sure concat is a string
    concat = concat == nil and "; " or concat
    assert(type(concat) == "string", "Expected a string for 'concat'")
    -- Construct key: value pairs
    local parts = {}
    for k, v in pairs(tbl) do
        if (not k ~= "class_name") then
            if (pandoc.utils.type(v) == "table") then
                for ik, iv in pairs(v) do
                    table.insert(parts, ik .. ": " .. pandoc.utils.stringify(iv))
                end
            else
                table.insert(parts, k .. ": " .. tostring(v))
            end
        end
    end
    -- Concatenate the key: value pairs with the separator
    return table.concat(parts, concat)
end

-- ───────────────────────────────── <end> ────────────────────────────────── --

return table_to_CSS