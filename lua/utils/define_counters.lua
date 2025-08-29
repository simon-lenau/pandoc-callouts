-- ========================== > define_counters < =========================== --
-- ┌┌──────────────────────────────────────────────────────────────────────┐┐ --
-- ││ Creates a new counter for a given callout type if it doesn't exist.  ││ --
-- ││ ARGUMENTS:                                                           ││ --
-- ││ callout_type (string):                                               ││ --
-- ││     The type of the callout for which to create a counter.           ││ --
-- └└──────────────────────────────────────────────────────────────────────┘┘ --
local function define_counters(callout_type,references)
    if not references.headcounts then
        references.headcounts = {}
    end

    if not references.headcounts[callout_type] then
       references.headcounts[callout_type] = {}
    end
end

-- ───────────────────────────────── <end> ────────────────────────────────── --
return define_counters
