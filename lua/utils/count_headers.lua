-- =========================== > count_headers < ============================ --

-- ┌┌──────────────────────────────────────────────────────────────────────┐┐ --
-- ││ count headers in a document                                          ││ --
-- └└──────────────────────────────────────────────────────────────────────┘┘ --

local function count_headers(header,references)
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