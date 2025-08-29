-- =========================== > count_headers < ============================ --
-- ┌┌──────────────────────────────────────────────────────────────────────┐┐ --
-- ││ DESCRIPTION                                                          ││ --
-- ││ This function counts the number of headers at a given level,         ││ --
-- ││ resets lower-level and callout counters                              ││ --
-- ││                                                                      ││ --
-- ││ ARGUMENTS:                                                           ││ --
-- ││ header (table):                                                      ││ --
-- ││      A pandoc header object.                                         ││ --
-- ││ references (table):                                                  ││ --
-- ││      A table containing counters for headers and callouts.           ││ --
-- ││          It is modified by this function.                            ││ --
-- └└──────────────────────────────────────────────────────────────────────┘┘ --
local function count_headers(header, references)

    local level = header.level
    -- Reset lower-level counters
    for i = level + 1, 6 do
        references.header_counts[i] = 0
    end

    for c, l in pairs(references.callout_count_reset_levels) do
        if l >= level then
            references.callout_counts[c] = 0
        end
    end

    -- Increment current level
    references.header_counts[level] = (references.header_counts[level] or 0) + 1
    return header
end

-- ───────────────────────────────── <end> ────────────────────────────────── --

return count_headers
