local table_to_CSS = require("utils.table_to_CSS")
local assert_argument = require("utils.assert_argument")

-- ========================= > add_callout_style < ========================== --
-- ┌┌──────────────────────────────────────────────────────────────────────┐┐ --
-- ││ Add a callout style                                                  ││ --
-- └└──────────────────────────────────────────────────────────────────────┘┘ --
local function add_callout_style(options, references)
    -- Default options
    local class_name = options.class_name or "default-callout"
    local style = options.style or {}
    local body_style = options.body_style or {}
    local header_style = options.header_style or {}

    -- Make sure arguments are of appropriate type
    assert_argument({
        arguments = references,
        name = "styles",
        type = "table"
    })

    assert_argument({
        arguments = references.styles,
        name = "callouts",
        type = "table"
    })

    assert(type(class_name) == "string", "Expected a string for 'class_name'")
    assert(type(style) == "table", "Expected a table for 'style'")
    assert(type(header_style) == "table", "Expected a table for 'header_style'")
    assert(type(body_style) == "table", "Expected a table for 'body_style'")

    -- Create CSS styles and add to callout styles table
    table.insert(references.styles.callouts, ".callout-" .. class_name .. " {\n" .. table_to_CSS(style) .. "\n}")

    table.insert(references.styles.callouts, ".callout-" .. class_name .. " > .callout-header " .. " {\n" ..
        table_to_CSS(header_style, "; ") .. "\n}")

    -- Needed for content
    table.insert(references.styles.callouts, ".callout-" .. class_name .. " .callout-body-container" .. " {\n" ..
        table_to_CSS(body_style, "; ") .. "\n}")

end
-- ───────────────────────────────── <end> ────────────────────────────────── --

return add_callout_style

