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

local header_counts = {}
local callout_counts = {}
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
        -- print("k is " .. pandoc.utils.stringify(k) .. "(" .. pandoc.utils.type(k) .. "  | " .. type(k) .. ")")
        -- print("v is " .. pandoc.utils.stringify(v) .. "(" .. pandoc.utils.type(v) .. " | " .. type(v) .. ")")
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

    -- Increment current level
    header_counts[level] = (header_counts[level] or 0) + 1
    return header
end

-- ───────────────────────────────── <end> ────────────────────────────────── --
-- ============================ > ensure_type < ============================= --

-- ┌┌──────────────────────────────────────────────────────────────────────┐┐ --
-- ││ Ensure that an argument is of appropriate type,                      ││ --
-- ││ throw error otherwise                                                ││ --
-- └└──────────────────────────────────────────────────────────────────────┘┘ --
function ensure_type(arguments, arg_name, expected_type)
    if type(arguments[arg_name]) ~= expected_type then
        error(string.format("Argument '%s' must be of type '%s' but is '%s'", arg_name, expected_type,
            type(arguments[arg_name])))
    end
end
-- ───────────────────────────────── <end> ────────────────────────────────── --

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
    local header_level = tonumber(options.header_level or 2)
    local header_style = options.header_style or options.style or header_style_default
    local icon = (options.collapse == nil) and false or options.icon
    local label = options.label or class_name
    local style = options.style or style_default

    -- Make sure arguments are of appropriate type
    assert(type(label) == "string",
        "Expected a string for 'label' but got " .. type(label) .. "('" .. tostring(label) .. "')")
    assert(type(class_name) == "string",
        "Expected a string for 'class_name' but got " .. type(class_name) .. "('" .. tostring(class_name) .. "')")
    assert(type(header_level) == "number",
        "Expected a number for 'header_level' but got " .. type(header_level) .. "('" .. tostring(header_level) .. "')")
    assert(type(collapse) == "boolean",
        "Expected a boolean for 'collapse' but got " .. type(collapse) .. "('" .. tostring(collapse) .. "')")

    -- Complete style declarations using default values
    complete(style, style_default)
    complete(header_style, header_style_default)
    complete(body_style, body_style_default)

    complete(header_style, style_default)
    complete(body_style, style_default)

    -- Add to each style entry if not already there
    important(header_style)
    important(body_style)
    important(style)

    add_callout_style({
        class_name = class_name,
        body_style = body_style,
        style = style,
        header_style = header_style
    })

    -- Make (only) first letter of label uppercase
    label = label:gsub("^%l", label.upper)

    callout_handlers[class_name] = function(div)
        if div.classes:includes(class_name) then
            -- Increase counter for current callout
            callout_counts[class_name] = (callout_counts[class_name] or 0) + 1
            -- Build callout number like "1.2.3" using header levels up to `header_level`
            local numberings = {}
            for i = 1, header_level do
                if header_counts[i] then
                    table.insert(numberings, tostring(header_counts[i]))
                else
                    table.insert(numberings, tostring(0))
                end
            end
            table.insert(numberings, tostring(callout_counts[class_name]))

            -- Begin callout title with the label and formatted number
            callout_title = (label or "") .. " " .. table.concat(numberings, ".")
            callout_id = div.identifier or callout_title

            callout_references[callout_id] = {
                ["ref"] = callout_title,
                ["title"] = div.attributes["title"]
            }

            -- If there is a title attribute, append it to the callout title
            if (div.attributes["title"] or "") ~= "" then
                callout_title = callout_title .. ": " .. div.attributes["title"]
            end

            -- Create the callout object with the specified type
            local callout = quarto.Callout({
                type = class_name,
                content = div.content,
                title = callout_title,
                collapse = collapse,
                icon = icon
            })

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
    for _, handler in pairs(callout_handlers) do
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
        -- print("class: ", class)
        -- print("class_name:" .. tostring(callout_types_tbl[class]["class_name"]) .. "X")
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

    -- First pass: Count headers and construct callouts
    doc.blocks = pandoc.walk_block(pandoc.Div(doc.blocks), {
        Header = count_headers,
        Div = callout_handler
    }).content

    -- Second pass: resolve citations
    doc.blocks = pandoc.walk_block(pandoc.Div(doc.blocks), {
        Cite = resolve_references
    }).content

    return doc
end

return {{
    Pandoc = Pandoc
}}

