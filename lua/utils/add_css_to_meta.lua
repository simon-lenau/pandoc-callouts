-- ========================== > add_css_to_meta < =========================== --
-- ┌┌──────────────────────────────────────────────────────────────────────┐┐ --
-- ││ Adds CSS styles to the HTML output based on yaml in.                 ││ --
-- ││                                                                      ││ --
-- ││ ARGUMENTS:                                                           ││ --
-- ││ - meta (table):                                                      ││ --
-- ││       The metadata table from the pandoc document to which           ││ --
-- ││       CSS styles are added                                           ││ --
-- ││ - references (table):                                                ││ --
-- ││       A table containing fields:                                     ││ --
-- ││       - 'styles' (table):                                            ││ --
-- ││           A table containing fields:                                 ││ --
-- ││           - 'callouts' (table): A table containing CSS style strings ││ --
-- ││              extracted from YAML input.                              ││ --
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
