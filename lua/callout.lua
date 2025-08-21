local overall_callout_count = 0

-- ========================= > Style definitions < ========================== --
local style_default = {
    ["border"] = "1px solid"
}

local header_style_default = {
    ["color"] = "white",
    ["background-color"] = "black",
    ["border"] = "0px solid"
}

local body_style_default = {
    ["background-color"] = "white",
    ["color"] = "black",
    ["border"] = "0px solid"
}

-- ───────────────────────────────── <end> ────────────────────────────────── --

-- ========================= > Table definitions < ========================== --
local identation_level = 0

local header_counts = {}
local callout_count_reset_levels = {}
local callout_counts = {}
local callout_numberings = {}
local callout_handlers = {}
local callout_styles = {}

local callout_references = {}

-- ───────────────────────────────── <end> ────────────────────────────────── --

-- ============================== > complete < ============================== --
-- ┌┌──────────────────────────────────────────────────────────────────────┐┐ --
-- ││ Complete parameters with default values if they are not provided.    ││ --  
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

-- =========================== > yaml_to_table < ============================ --
-- ┌┌──────────────────────────────────────────────────────────────────────┐┐ --
-- ││ Convert yaml specification to named lua table                        ││ -- 
-- └└──────────────────────────────────────────────────────────────────────┘┘ --
function yaml_to_table(list)
    local output = {}
    for k, v in pairs(list) do
        if (pandoc.utils.type(k) == "string") then
            if (pandoc.utils.type(v) == "table") then
                output[k] = yaml_to_table(v)
                class_name = k:match("^%s*(.-)%s*$"):lower()
                if (not class_name:match("_style$")) then
                    output[k]['class_name'] = class_name
                end
            elseif (pandoc.utils.type(v) == "boolean") then
                output[k] = v
            elseif (pandoc.utils.type(v) == "string" and v:match("^%s*$")) then
                output['class_name'] = k:match("^%s*(.-)%s*$"):lower()
            else
                output[k] = pandoc.utils.stringify(v)
            end
        elseif (pandoc.utils.type(k) == "number" and pandoc.utils.type(v) == "table") then
            output[k] = yaml_to_table(v)
        elseif (pandoc.utils.type(k) == "number" and pandoc.utils.type(v) == "Inlines") then
            output[k] = {
                class_name = pandoc.utils.stringify(v):lower()
            }
        end
    end
    return output
end

-- ───────────────────────────────── <end> ────────────────────────────────── --

-- ============================ > table_to_CSS < ============================ --

-- ┌┌──────────────────────────────────────────────────────────────────────┐┐ --
-- ││ Format style table as CSS string                                     ││ --
-- └└──────────────────────────────────────────────────────────────────────┘┘ --

function table_to_CSS(tbl, concat)
    -- Make sure concat is a string
    concat = concat == nil and "; " or concat
    assert(type(concat) == "string", "Expected a string for 'concat'")
    -- Construct key: value pairs
    local parts = {}
    for k, v in pairs(tbl) do
        if (not k ~= "class_name") then
            if (pandoc.utils.type(v) == "table") then
                for ik, iv in pairs(v) do
                    table.insert(parts, ik .. ": " .. pandoc.utils.stringify(iv))
                end
            else
                table.insert(parts, k .. ": " .. tostring(v))
            end
        end
    end
    -- Concatenate the key: value pairs with the separator
    return table.concat(parts, concat)
end

-- ───────────────────────────────── <end> ────────────────────────────────── --

-- ========================= > add_callout_style < ========================== --

-- ┌┌──────────────────────────────────────────────────────────────────────┐┐ --
-- ││ Add a callout style                                                  ││ --
-- └└──────────────────────────────────────────────────────────────────────┘┘ --

function add_callout_style(options)
    -- Default options
    local class_name = options.class_name or "default-callout"
    local style = options.style or {}
    local body_style = options.body_style or {}
    local header_style = options.header_style or {}

    -- Make sure arguments are of appropriate type
    assert(type(class_name) == "string", "Expected a string for 'class_name'")
    assert(type(style) == "table", "Expected a table for 'style'")
    assert(type(header_style) == "table", "Expected a table for 'header_style'")
    assert(type(body_style) == "table", "Expected a table for 'body_style'")

    -- Create CSS styles and add to callout styles table
    table.insert(callout_styles, ".callout-" .. class_name .. " {\n" .. table_to_CSS(style) .. "\n}")

    table.insert(callout_styles, ".callout-" .. class_name .. " > .callout-header " .. " {\n" ..
        table_to_CSS(header_style, "; ") .. "\n}")

    -- Needed for content
    table.insert(callout_styles, ".callout-" .. class_name .. " .callout-body-container" .. " {\n" ..
        table_to_CSS(body_style, "; ") .. "\n}")

end
-- ───────────────────────────────── <end> ────────────────────────────────── --

-- =========================== > count_headers < ============================ --

-- ┌┌──────────────────────────────────────────────────────────────────────┐┐ --
-- ││ count headers in a document                                          ││ --
-- └└──────────────────────────────────────────────────────────────────────┘┘ --

function count_headers(header)
    local level = header.level
    -- Reset lower-level counters
    for i = level + 1, 6 do
        header_counts[i] = 0
    end

    for c, l in pairs(callout_count_reset_levels) do
        if l >= level then
            callout_counts[c] = 0
        end
    end

    -- Increment current level
    header_counts[level] = (header_counts[level] or 0) + 1

    -- print("Counted header " .. tostring(header))
    return header
end

-- ───────────────────────────────── <end> ────────────────────────────────── --

-- ================================ > warn < ================================ --

-- ┌┌──────────────────────────────────────────────────────────────────────┐┐ --
-- ││ warn                                                                 ││ --
-- └└──────────────────────────────────────────────────────────────────────┘┘ --
function warn(message)
    io.stderr:write(string.rep("-", 80, ""), "\n", "WARNING: " .. message, "\n", string.rep("-", 80, ""), "\n")
end

-- ───────────────────────────────── <end> ────────────────────────────────── --

-- ========================== > assert_argument < =========================== --

-- ┌┌──────────────────────────────────────────────────────────────────────┐┐ --
-- ││ x                                                                    ││ --
-- └└──────────────────────────────────────────────────────────────────────┘┘ --

-- ───────────────────────────────── <end> ────────────────────────────────── --

function assert_argument(options)
    -- Ensure options is a table
    assert(type(options) == "table", "Expected a table for 'options' but got " .. type(options))

    -- Retrieve values from the options table
    local arguments = options.arguments
    local name = options.name
    local type_name = options.type

    -- Make sure argument is of appropriate type
    assert(type(arguments) == "table",
        "Expected a string for 'arguments' but got " .. type(arguments) .. "('" .. tostring(arguments) .. "')")
    assert(type(name) == "string",
        "Expected a string for 'name' but got " .. type(name) .. "('" .. tostring(name) .. "')")
    assert(type(type_name) == "string",
        "Expected a string for 'type' but got " .. type(type_name) .. "('" .. tostring(type_name) .. "')")

    assert(type(arguments[name]) == type_name,
        "Expected type '" .. type_name .. "' for argument '" .. name .. "' but got " .. type(arguments[name]) .. "('" ..
            tostring(arguments[name]) .. "')")

end

-- ========================= > callout_ref_number < ========================= --

-- ┌┌──────────────────────────────────────────────────────────────────────┐┐ --
-- ││ x                                                                    ││ --
-- ││ y                                                                    ││ --
-- └└──────────────────────────────────────────────────────────────────────┘┘ --

function callout_no_placeholder(id)
    return "<<the@value@" .. id .. ">>"
end

function use_callout_reference(options)
    -- Ensure options is a table
    assert(type(options) == "table", "Expected a table for 'options' but got " .. type(options))

    -- Make sure arguments are of appropriate type
    assert_argument({
        arguments = options,
        name = "callout_id",
        type = "string"
    })
    assert_argument({
        arguments = options,
        name = "field",
        type = "string"
    })

    return "[[callout_meta_infos[" .. options.callout_id .. "][" .. options.field .. "]]]"
end

function resolve_callout_reference(div)
    div.content = pandoc.walk_block(pandoc.Div(div.content), {
        Inline = function(iline)
            if iline and iline.t == "Str" then
                new_text = iline.text:gsub("%[%[callout_meta_infos%[(.-)%]%[(.-)%]%]%]", function(id, field)
                    return callout_references[id][field]
                end)
                iline.text = new_text
            end
            return iline
        end
    }).content
    return div

end

-- ───────────────────────────────── <end> ────────────────────────────────── --

-- ========================== > define_reference < ========================== --
-- ┌┌──────────────────────────────────────────────────────────────────────┐┐ --
-- ││ Define references                                                    ││ --
-- └└──────────────────────────────────────────────────────────────────────┘┘ --
function define_callout_reference(options)
    -- Ensure options is a table
    assert(type(options) == "table", "Expected a table for 'options' but got " .. type(options))

    -- Retrieve values from the options table
    local callout_id = options.callout_id
    local callout_no = options.callout_no
    local callout_ref = options.callout_ref
    local callout_title = options.callout_title
    local callout_type = options.callout_type
    local callout_type_label = options.callout_type_label

    -- Check if the callout_id already exists
    if callout_references[callout_id] then
        warn("Callout with ID '" .. callout_id .. "' already exists.")
        return
    end

    -- Check if the callout type is defined
    if not callout_handlers[callout_type] then
        warn("callout_handlers['" .. callout_type .. "'] is not defined.")
        return
    end

    -- Make sure arguments are of appropriate type
    assert(type(callout_id) == "string",
        "Expected a string for 'callout_id' but got " .. type(callout_id) .. "('" .. tostring(callout_id) .. "')")
    assert(type(callout_no) == "string",
        "Expected a string for 'callout_no' but got " .. type(callout_no) .. "('" .. tostring(callout_no) .. "')")
    assert(type(callout_ref) == "string",
        "Expected a string for 'callout_ref' but got " .. type(callout_ref) .. "('" .. tostring(callout_ref) .. "')")
    assert(type(callout_title) == "string", "Expected a string for 'callout_title' but got " .. type(callout_title) ..
        "('" .. tostring(callout_title) .. "')")
    assert(type(callout_type_label) == "string",
        "Expected a string for 'callout_type_label' but got " .. type(callout_type_label) .. "('" ..
            tostring(callout_type_label) .. "')")

    callout_references[callout_id] = {
        ["type"] = callout_type,
        ["label"] = callout_type_label,
        ["id"] = callout_id,
        ["no"] = callout_no,
        ["ref"] = callout_ref,
        ["title"] = callout_title,
        ["level"] = 0
    }
end

-- ───────────────────────────────── <end> ────────────────────────────────── --

-- -- ========================== > use_callout_reference < ========================== --
-- -- ┌┌──────────────────────────────────────────────────────────────────────┐┐ --
-- -- ││ Use references                                                    ││ -- 
-- -- └└──────────────────────────────────────────────────────────────────────┘┘ --
-- local callout_reference_placeholders = {"id", "no", "ref", "title", "type", "label"}
-- function use_callout_reference(options)
--     -- Ensure options is a table
--     assert(type(options) == "table", "Expected a table for 'options' but got " .. type(options))

--     -- Retrieve values from the options table
--     local callout_id = options.callout_id
--     local format = options.format

--     -- Make sure arguments are of appropriate type
--     assert(type(callout_id) == "string",
--         "Expected a string for 'callout_id' but got " .. type(callout_id) .. "('" .. tostring(callout_id) .. "')")
--     assert(type(format) == "string",
--         "Expected a string for 'format' but got " .. type(format) .. "('" .. tostring(format) .. "')")

--     -- callout_references[callout_id][placeholder]
--     for _, placeholder in ipairs(callout_reference_placeholders) do
--         format = format:gsub("%%" .. placeholder, use_callout_reference({
--             callout_id = callout_id,
--             field = placeholder
--         }))
--     end
--     return format
-- end

-- -- ───────────────────────────────── <end> ────────────────────────────────── --

-- ======================== > define_callout_type < ========================= --

-- ┌┌──────────────────────────────────────────────────────────────────────┐┐ --
-- ││ defining a callout type with corresponding                           ││ --
-- ││ handler function and table_to_CSS style                              ││ --
-- └└──────────────────────────────────────────────────────────────────────┘┘ --

function define_callout_type(options)
    -- Use default values for missing arguments
    local body_style = options.body_style or options.style or body_style_default

    local class_name = options.class_name or options.label or "default-callout"
    local collapse = (options.collapse == nil) and true or options.collapse
    local counter = (options.counter == nil) and class_name or options.counter
    local header_level = tonumber(options.header_level or 2)
    local header_style = options.header_style or options.style or header_style_default
    local icon = (options.collapse == nil) and false or options.icon
    local inherit_counter = (options.inherit_counter ~= nil) and options.inherit_counter or false
    local label = options.label or class_name
    local style = options.style or style_default

    -- Make sure arguments are of appropriate type
    assert(type(label) == "string",
        "Expected a string for 'label' but got " .. type(label) .. "('" .. tostring(label) .. "')")
    assert(type(class_name) == "string",
        "Expected a string for 'class_name' but got " .. type(class_name) .. "('" .. tostring(class_name) .. "')")
    assert(type(counter) == "string",
        "Expected a string for 'counter' but got " .. type(counter) .. "('" .. tostring(counter) .. "')")
    assert(type(header_level) == "number",
        "Expected a number for 'header_level' but got " .. type(header_level) .. "('" .. tostring(header_level) .. "')")
    assert(type(collapse) == "boolean",
        "Expected a boolean for 'collapse' but got " .. type(collapse) .. "('" .. tostring(collapse) .. "')")
    assert(type(inherit_counter) == "boolean",
        "Expected a boolean for 'inherit_counter' but got " .. type(inherit_counter) .. "('" ..
            tostring(inherit_counter) .. "')")

    -- Complete style declarations using default values
    complete(style, style_default)
    complete(header_style, header_style_default)
    complete(body_style, body_style_default)

    complete(header_style, style_default)
    complete(body_style, style_default)

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
    })

    -- Define reset level for callout counter
    callout_count_reset_levels[class_name] = header_level

    callout_handlers[class_name] = function(div)
        if div.classes:includes(class_name) then
            overall_callout_count = overall_callout_count + 1
            -- Check if current class_name uses own or inherited counter
            local numberings = {}

            if not inherit_counter then
                -- Increase counter for current callout type
                callout_counts[counter] = (callout_counts[counter] or 0) + 1
                -- Build callout number like "1.2.3" using header levels up to `header_level`
                for i = 1, header_level do
                    if (header_counts[i] and header_counts[i] > 0) then
                        table.insert(numberings, tostring(header_counts[i]))
                    else
                        table.insert(numberings, tostring("_"))
                    end
                end
                table.insert(numberings, tostring(callout_counts[counter]))
            else
                numberings = {callout_no_placeholder("parent")}
            end

            callout_id = div.identifier

            if not callout_id or callout_id == "" then
                callout_id = "__callout:::" .. overall_callout_count .. "__"
            end

            define_callout_reference({
                callout_type = class_name,
                callout_type_label = label,
                callout_id = callout_id,
                callout_no = table.concat(numberings, "."),
                callout_ref = "not needed",
                callout_title = (div.attributes["title"] or "")
            })

            div.content = pandoc.walk_block(pandoc.Div(div.content), {
                Div = function(el)
                    if el and el.identifier and el.identifier ~= "" then
                        -- ident_str = string.rep("  ", callout_references[el.identifier].level + 1)
                        -- print(ident_str .. el.identifier .. " is child of " .. callout_id)
                        -- print(ident_str .. "Replacing\n" .. ident_str .. callout_no_placeholder("parent") .. "\n" ..
                        --           ident_str .. "by\n" .. ident_str .. use_callout_reference({
                        --     callout_id = callout_id,
                        --     field = "no"
                        -- }) .. "\n" .. ident_str .. "in\n" .. ident_str .. callout_references[el.identifier].no .. "\n" ..
                        --           ident_str .. "----------\n")
                        callout_references[el.identifier].level = callout_references[el.identifier].level + 1
                        callout_references[el.identifier].no =
                            callout_references[el.identifier].no:gsub(callout_no_placeholder("parent"),
                                use_callout_reference({
                                    callout_id = callout_id,
                                    field = "no"
                                }))
                    end
                    return el
                end
            })

            -- Create the callout object with the specified type
            local callout = quarto.Callout({
                type = class_name,
                content = div.content,
                title = use_callout_reference({
                    callout_id = callout_id,
                    field = "label"
                }) .. " " .. use_callout_reference({
                    callout_id = callout_id,
                    field = "no"
                }) .. ": " .. use_callout_reference({
                    callout_id = callout_id,
                    field = "title"
                }),
                collapse = collapse,
                icon = icon
            })

            identation_level = identation_level - 1
            return pandoc.Div(callout, pandoc.Attr(callout_id))

        end
    end
end

-- ───────────────────────────────── <end> ────────────────────────────────── --

-- ========================== > callout_handler < =========================== --

-- ┌┌──────────────────────────────────────────────────────────────────────┐┐ --
-- ││ Handler for running the handlers for callout add_callout_style       ││ --
-- └└──────────────────────────────────────────────────────────────────────┘┘ --

function callout_handler(div)
    -- Apply defined callout handlers
    for type, handler in pairs(callout_handlers) do
        local result = handler(div)
        if result then
            return result
        end
    end
    return div
end

-- ───────────────────────────────── <end> ────────────────────────────────── --

-- ========================== > add_css_to_meta < =========================== --

-- ┌┌──────────────────────────────────────────────────────────────────────┐┐ --
-- ││ adding callout CSS styles to the HTML output                         ││ --
-- └└──────────────────────────────────────────────────────────────────────┘┘ --

function add_css_to_meta(meta)
    -- Check if there are any callout styles created by this file
    if #callout_styles == 0 then
        return meta
    end

    -- ... if yes, add them to the meta data
    local css_block = "<style>\n" .. table.concat(callout_styles, "\n") .. "\n</style>"

    meta['header-includes'] = meta['header-includes'] or {}
    table.insert(meta['header-includes'], pandoc.RawBlock("html", css_block))

    return meta
end

-- ───────────────────────────────── <end> ────────────────────────────────── --

-- ============== > Callout definitions based on meta blocks < ============== --

-- ┌┌──────────────────────────────────────────────────────────────────────┐┐ --
-- ││ This will define callout types based on the yaml header_counts       ││ --
-- └└──────────────────────────────────────────────────────────────────────┘┘ --

function process_yaml(meta)
    local callout_types = meta['callout-types']
    if type(callout_types) ~= "table" then
        return meta
    end

    local callout_types_tbl = yaml_to_table(callout_types)

    for class, _ in pairs(callout_types_tbl) do
        define_callout_type(callout_types_tbl[class])
    end
end

-- ───────────────────────────────── <end> ────────────────────────────────── --

-- ========================= > Resolve references < ========================= --
function resolve_references(el)
    if el.citations then
        for _, citation in ipairs(el.citations) do
            if citation.id then
                if callout_references[citation.id] then
                    return pandoc.Link(callout_references[citation.id]["ref"], "#" .. citation.id)
                end
            end
        end
    end
    return el
end
-- ───────────────────────────────── <end> ────────────────────────────────── --

-- ========================== > resolve_numbers < =========================== --

-- ┌┌──────────────────────────────────────────────────────────────────────┐┐ --
-- ││ x                                                                    ││ --
-- ││ y                                                                    ││ --
-- └└──────────────────────────────────────────────────────────────────────┘┘ --
function resolve_numbers(element)
    if element.identifier and element.identifier ~= "" then
        -- print(">" .. element.identifier .. ":")
        -- print("\t"..pandoc.utils.stringify(element))
        return pandoc.walk_block(pandoc.Div(element), {
            Inline = function(el)
                if el and el.t == "Str" then
                    -- print("\t" .. el.text)
                    -- print(el.text)
                    -- el.text = el.text:gsub("__(.-)__", element.identifier)
                    -- function(inner)
                    --     print("match: ", inner, "\n")
                    --     return 
                    -- end)

                end

                return el
            end
        })
    end
end
-- ───────────────────────────── <end> ────────────────────────────────── --

-- Master handler: runs after full document is loaded
function Pandoc(doc)
    -- Only run if any callout-types are defined in yaml header
    if not doc.meta['callout-types'] then
        return doc
    end

    -- Create callout type definitions
    process_yaml(doc.meta)

    -- Add CSS to meta data
    add_css_to_meta(doc.meta)

    -- First pass: Construct callouts
    doc.blocks = pandoc.walk_block(pandoc.Div(doc.blocks), {
        Header = count_headers,
        Div = callout_handler
    }).content

    doc.blocks = pandoc.walk_block(pandoc.Div(doc.blocks), {
        Div = resolve_callout_reference
    }).content

    -- Third pass: resolve citations
    doc.blocks = pandoc.walk_block(pandoc.Div(doc.blocks), {
        Cite = resolve_references
    }).content

    return doc
end

return {{
    Pandoc = Pandoc
}}

