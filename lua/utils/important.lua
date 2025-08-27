-- ============================= > important < ============================== --

-- ┌┌──────────────────────────────────────────────────────────────────────┐┐ --
-- ││ Function for making all table values !important for css formatting   ││ --
-- └└──────────────────────────────────────────────────────────────────────┘┘ --
function important(style)
    for key, value in pairs(style) do
        if type(value) == "string" and not value:match("!important") then
            style[key] = value .. " !important"
        end
    end
end

-- ───────────────────────────────── <end> ────────────────────────────────── --

return important