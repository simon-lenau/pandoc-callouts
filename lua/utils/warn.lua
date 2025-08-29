-- ================================ > warn < ================================ --
-- ┌┌──────────────────────────────────────────────────────────────────────┐┐ --
-- ││ DESCRIPTION                                                          ││ --
-- ││ Prints warning message to stderr                                     ││ --
-- ││                                                                      ││ --
-- ││ ARGUMENTS:                                                           ││ --
-- ││ - message (string):                                                  ││ --
-- ││   The warning message to be printed                                  ││ --
-- └└──────────────────────────────────────────────────────────────────────┘┘ --
local function warn(message)
    local sep = string.rep("-", 80, "")
    io.stderr:write(sep, "\n", "WARNING:\n\t", message, "\n", sep, "\n")
end

-- ───────────────────────────────── <end> ────────────────────────────────── --

return warn
