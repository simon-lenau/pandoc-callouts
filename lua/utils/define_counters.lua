-- ========================== > define_counters < =========================== --

-- ┌┌──────────────────────────────────────────────────────────────────────┐┐ --
-- ││ X                                                                    ││ --
-- └└──────────────────────────────────────────────────────────────────────┘┘ --

local function define_counters(callout_type)
    if not headcounts then
        headcounts = {}
    end

    if not headcounts[callout_type] then
        headcounts[callout_type] = {}
    end
end

-- ───────────────────────────────── <end> ────────────────────────────────── --
return define_counters