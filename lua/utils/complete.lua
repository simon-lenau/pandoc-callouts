-- ============================== > complete < ============================== --
-- ┌┌──────────────────────────────────────────────────────────────────────┐┐ --
-- ││ DESCRIPTION                                                          ││ --
-- ││ Completes a table of parameters with                                 ││ --
-- ││ default values from a second table if they are not provided.         ││ --
-- ││                                                                      ││ --
-- ││ ARGUMENTS:                                                           ││ --
-- ││ - params (table):                                                    ││ --
-- ││   The table containing the parameters to be completed.             ││ --
-- ││ - defaults (table):                                                  ││ --
-- ││   The table containing default values for the parameters.          ││ --
-- └└──────────────────────────────────────────────────────────────────────┘┘ --
local function complete(params, defaults)
    for param, default in pairs(defaults) do
        if params[param] == nil then
            if pandoc.utils.type(default) == "Inlines" then
                default_val = pandoc.utils.stringify(default)
            elseif pandoc.utils.type(default) == "Bool" then
                default_val = default
            else
                default_val = default
            end
            params[param] = default_val
        end
    end
end

-- ───────────────────────────────── <end> ────────────────────────────────── --

return complete
