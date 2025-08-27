-- ========================== > add_css_to_meta < =========================== --
-- ┌┌──────────────────────────────────────────────────────────────────────┐┐ --
-- ││ adding callout CSS styles to the HTML output                         ││ --
-- └└──────────────────────────────────────────────────────────────────────┘┘ --
local function add_css_to_meta(meta, references)
    -- Check if there are any callout references.styles created by this file
    if #references.styles.callouts == 0 then
        return meta
    end

    -- ... if yes, add them to the meta data
    local css_block = "<style>\n" .. table.concat(references.styles.callouts, "\n") .. "\n</style>"

    meta['header-includes'] = meta['header-includes'] or {}
    table.insert(meta['header-includes'], pandoc.RawBlock("html", css_block))

    return meta
end

-- ───────────────────────────────── <end> ────────────────────────────────── --

return add_css_to_meta
