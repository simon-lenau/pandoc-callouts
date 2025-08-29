-- ============================ > shallow_copy < ============================ --
-- ┌┌──────────────────────────────────────────────────────────────────────┐┐ --
-- ││ DESCRIPTION                                                          ││ --
-- ││ Creates a shallow copy of the input table.                           ││ --
-- ││ ARGUMENTS:                                                           ││ --
-- ││  t (table):                                                          ││ --
-- ││      The table to be shallow copied.                                 ││ --
-- └└──────────────────────────────────────────────────────────────────────┘┘ --

local function shallow_copy(t)
    local copy = {}
    for k, v in pairs(t) do
        copy[k] = v
    end
    return copy
end

-- ───────────────────────────────── <end> ────────────────────────────────── --

return shallow_copy
