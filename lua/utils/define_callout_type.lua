local default_styles = require("styles.defaults")
local complete = require("utils.complete")
local header_level_format = require("utils.header_level_format")
local important = require("utils.important")
local add_callout_style = require("utils.add_callout_style")
local define_counters = require("utils.define_counters")
local define_callout_reference = require("utils.define_callout_reference")
local insert_callout_reference = require("utils.insert_callout_reference")
local assert_argument = require("utils.assert_argument")

-- ======================== > define_callout_type < ========================= --
-- ┌┌──────────────────────────────────────────────────────────────────────┐┐ --
-- ││ defining a callout type with corresponding                           ││ --
-- ││ handler function and utils.table_to_CSS style                              ││ -- 
-- └└──────────────────────────────────────────────────────────────────────┘┘ --
local function define_callout_type(options, references)
    -- Use default values for missing arguments
    local body_style = options.body_style or options.style or default_styles.body

    local class_name = options.class_name or options.label or "default-callout"
    local collapse = (options.collapse == nil) and true or options.collapse
    local counter = (options.counter == nil) and class_name or options.counter
    local header_level = tonumber(options.header_level or 0)
    local header_style = options.header_style or options.style or default_styles.header
    local icon = (options.collapse == nil) and false or options.icon
    local counter_format = (options.counter_format ~= nil) and options.counter_format or nil
    local label = options.label or class_name
    local style = options.style or default_styles.style

    if (counter_format == "") or (counter_format == nil) then
        if header_level and (header_level > 0) then
            counter_format = header_level_format(header_level)
        else
            counter_format = "{{{{parent}} or {{1}}.{{2}}}}.{{self}}"
        end
    end

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


    assert_argument({
        arguments = references,
        name = "callout_count_reset_levels",
        type = "table"
    })

    assert(type(label) == "string",
        "Expected a string for 'label' but got " .. type(label) .. "('" .. tostring(label) .. "')")
    assert(type(class_name) == "string",
        "Expected a string for 'class_name' but got " .. type(class_name) .. "('" .. tostring(class_name) .. "')")
    assert(type(counter_format) == "string",
        "Expected a string for 'counter_format' but got " .. type(counter_format) .. "('" .. tostring(counter_format) ..
            "')")
    assert(type(counter) == "string",
        "Expected a string for 'counter' but got " .. type(counter) .. "('" .. tostring(counter) .. "')")
    assert(type(header_level) == "number",
        "Expected a number for 'header_level' but got " .. type(header_level) .. "('" .. tostring(header_level) .. "')")
    assert(type(collapse) == "boolean",
        "Expected a boolean for 'collapse' but got " .. type(collapse) .. "('" .. tostring(collapse) .. "')")

    -- Complete style declarations using default values
    complete(style, default_styles.style)
    complete(header_style, default_styles.header)
    complete(body_style, default_styles.body)

    complete(header_style, default_styles.style)
    complete(body_style, default_styles.style)

    -- Add "!important" to each style entry if not already there
    --      (otherwise, quarto defaults will sometimes interfer)
    important(header_style)
    important(body_style)
    important(style)

    add_callout_style({
        class_name = class_name,
        body_style = body_style,
        style = style,
        header_style = header_style
    }, references)

    -- Define reset level for callout counter
    define_counters(counter,references)
    references.callout_count_reset_levels[class_name] = header_level

    references.headcounts = references.headcounts or {}
    references.headcounts[counter] = references.headcounts[counter] or {}

    references.callout_handlers[class_name] = function(div)
        if div.classes:includes(class_name) then

            references.overall_callout_count = references.overall_callout_count + 1

            callout_id = div.identifier

            references.callout_ids[references.overall_callout_count] = callout_id

            if not callout_id or callout_id == "" then
                callout_id = "__callout[" .. references.overall_callout_count .. "]__"
            end

            -- Check if the callout_id already exists
            if references.callout_references[callout_id] then
                local new_callout_id = callout_id .. "[" .. references.overall_callout_count .. "]"
                warn("Callout with ID '" .. callout_id .. "' already exists.\n\t Renamed to '" .. new_callout_id .. "'")
                callout_id = new_callout_id
            end

            define_callout_reference({
                callout_type = class_name,
                callout_type_label = label,
                callout_id = callout_id,
                counter_format = counter_format,
                callout_ref = "not needed",
                callout_title = (div.attributes["title"] or ""),
                header_counts = references.header_counts,
                callout_counter = counter,
                header_level = header_level or 2,
                inherits_counter = counter_format:match("%{%{parent%}%}") ~= nil

            }, references)

            div.content = pandoc.walk_block(pandoc.Div(div.content), {
                Div = function(el)
                    if el and el.identifier and el.identifier ~= "" then
                        table.insert(references.callout_references[el.identifier].parents, callout_id)
                        table.insert(references.callout_references[callout_id].children, el.identifier)
                    end
                    return el
                end
            })

            -- Create the callout object with the specified type
            local callout = quarto.Callout({
                type = class_name,
                content = div.content,
                title = insert_callout_reference({
                    callout_id = callout_id,
                    field = "header"
                }),
                collapse = collapse,
                icon = icon
            })

            return pandoc.Div(callout, pandoc.Attr(callout_id))

        end
    end
end

-- ───────────────────────────────── <end> ────────────────────────────────── --

return define_callout_type

