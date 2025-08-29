-- =============================== > header_level_format < ================================ --
-- ┌┌──────────────────────────────────────────────────────────────────────┐┐ --
-- ││ DESCRIPTION                                                          ││ --
-- ││ This function generates a callout number format string based on the  ││ --
-- ││ provided header level. It creates a sequence of numbers separated    ││ --
-- ││ by dots, starting from 1 up to the specified level.                  ││ --
-- └└──────────────────────────────────────────────────────────────────────┘┘ --

-- ARGUMENTS:
--  level (number):
--      The header level for which to generate the callout number format.

local function header_level_format(level)
    counter_format_table = {}
    -- Build callout number format "1.2.3" using header levels up to `header_level`
    for i = 1, level do
        table.insert(counter_format_table, var(i))
    end
    return table.concat(counter_format_table, ".")
end

-- ───────────────────────────────── <end> ────────────────────────────────── --
return header_level_format
