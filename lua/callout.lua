local function get_script_path()
    local info = debug.getinfo(1, 'S')
    local source = info.source
    if source:sub(1, 1) == '@' then
        return source:sub(2):match("(.*/)")
    else
        return nil -- running from string, not a file
    end
end

local script_path = get_script_path()
if script_path then
    package.path = script_path .. "?.lua;" .. package.path
end

local styles = require("styles")

local overall_callout_count = 0

-- ========================= > Table definitions < ========================== --
local identation_level = 0

local header_counts = {}
local callout_count_reset_levels = {}
local callout_counts = {}
local callout_ids = {}
local callout_handlers = {}
local callout_styles = {}

local callout_references = {}

-- ───────────────────────────────── <end> ────────────────────────────────── --

-- ============================== > complete < ============================== --
-- ┌┌──────────────────────────────────────────────────────────────────────┐┐ --
-- ││ Complete parameters with default values if they are not provided.    ││ --  
-- └└──────────────────────────────────────────────────────────────────────┘┘ --
local function complete(params, defaults)
    print(defaults)
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

-- ========================== > define_counters < =========================== --

-- ┌┌──────────────────────────────────────────────────────────────────────┐┐ --
-- ││ X                                                                    ││ --
-- └└──────────────────────────────────────────────────────────────────────┘┘ --

function define_counters(callout_type)
    if not headcounts then
        headcounts = {}
    end

    if not headcounts[callout_type] then
        headcounts[callout_type] = {}
    end
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

function insert_callout_reference(options)
    -- Ensure options is a table
    assert(type(options) == "table", "Expected a table for 'options' but got " .. type(options))

    -- Make sure arguments are of appropriate type
    if options.callout_id then
        assert_argument({
            arguments = options,
            name = "callout_id",
            type = "string"
        })
    end

    assert_argument({
        arguments = options,
        name = "field",
        type = "string"
    })

    if options.callout_id then
        return "[[callout_meta_infos[" .. options.callout_id .. "][" .. options.field .. "]]]"
    else
        return ""
    end
end

-- ───────────────────────────────── <end> ────────────────────────────────── --
-- ============================ > shallow_copy < ============================ --

-- ┌┌──────────────────────────────────────────────────────────────────────┐┐ --
-- ││ create a shallow copy of a table                                     ││ --
-- └└──────────────────────────────────────────────────────────────────────┘┘ --
function shallow_copy(t)
    local copy = {}
    for k, v in pairs(t) do
        copy[k] = v
    end
    return copy
end

-- ───────────────────────────────── <end> ────────────────────────────────── --

-- ==================== > callout_field_regex_pattern < ===================== --

-- ┌┌──────────────────────────────────────────────────────────────────────┐┐ --
-- ││ x                                                                    ││ --
-- └└──────────────────────────────────────────────────────────────────────┘┘ --
function callout_field_regex_pattern()
    -- Define regex pattern
    local pattern = insert_callout_reference({
        callout_id = "__capture__",
        field = "__capture__"
    })

    -- Escape brackets
    pattern = string.gsub(pattern, "([%[%(%{%}%)%]])", function(a)
        return "%" .. a
    end)

    -- Insert capture groups after escaping brackets
    pattern = string.gsub(pattern, "__capture__", "(.-)")
    return pattern
end
-- ───────────────────────────────── <end> ────────────────────────────────── --

-- ===================== > resolve_callout_reference < ====================== --
-- ┌┌──────────────────────────────────────────────────────────────────────┐┐ --
-- ││ x                                                                    ││ --
-- └└──────────────────────────────────────────────────────────────────────┘┘ --
function resolve_callout_reference(options)
    -- Ensure options is a table
    assert(type(options) == "table", "Expected a table for 'options' but got " .. type(options))

    -- Make sure arguments are of appropriate type
    if options.callout_id then
        assert_argument({
            arguments = options,
            name = "callout_id",
            type = "string"
        })
    end

    assert_argument({
        arguments = options,
        name = "field",
        type = "string"
    })

    callout_references[options.callout_id][options.field] = string.gsub(
        callout_references[options.callout_id][options.field], callout_field_regex_pattern(), function(id, field)
            return callout_references[id][field]
        end)
end
-- ───────────────────────────────── <end> ────────────────────────────────── --
-- ============================== > is_empty < ============================== --

-- ┌┌──────────────────────────────────────────────────────────────────────┐┐ --
-- ││ x                                                                    ││ --
-- └└──────────────────────────────────────────────────────────────────────┘┘ --
function is_empty(t)
    return next(t) == nil
end

-- ───────────────────────────────── <end> ────────────────────────────────── --

-- ===================== > resolve_callout_references < ===================== --

-- ┌┌──────────────────────────────────────────────────────────────────────┐┐ --
-- ││ x                                                                    ││ --
-- └└──────────────────────────────────────────────────────────────────────┘┘ --

function resolve_callout_references(id)
    if (not id) or (id == "") then
        return
    end
    -- Resolve only un-resolved references
    if callout_references[id].resolved then
        return
    end

    if not (id and callout_references[id]) then
        return
    end

    -- Count children
    local child_counters = {}
    for _, child_id in ipairs(callout_references[id].children) do
        if child_id and not callout_references[child_id].counted then
            callout_references[child_id].counted = true
            child_counters[callout_references[child_id].type] =
                (child_counters[callout_references[child_id].type] or 0) + 1
            callout_references[child_id].no = child_counters[callout_references[child_id].type]
        end
    end

    -- Resolve parents first
    --      inherited information may be needed
    for _, parent_id in pairs(callout_references[id].parents) do
        if parent_id then
            resolve_callout_references(parent_id)
        end
    end
    if (is_empty(callout_references[id].parents) or not callout_references[id].inherits_counter) then
        local reset_counter = false
        for i = 1, callout_references[id].header_level do
            reset_counter = ((headcounts[callout_references[id].counter][i] or 0) ~=
                                callout_references[id].header_counts[i])

            if reset_counter then
                break
            end
        end

        if reset_counter then
            headcounts[callout_references[id].counter] = callout_references[id].header_counts
            callout_counts[callout_references[id].type] = 0
        end

        -- Increase counter for current callout type
        callout_counts[callout_references[id].type] = (callout_counts[callout_references[id].type] or 0) + 1
        callout_references[id].no = callout_counts[callout_references[id].type]

    end

    for key, _ in pairs(callout_references[id]) do
        if type(callout_references[id][key]) ~= "table" and type(callout_references[id][key]) ~= "boolean" then
            resolve_callout_reference({
                callout_id = id,
                field = key
            })
        end
    end
    resolve_callout_numbers(id)
    resolve_callout_reference({
        callout_id = id,
        field = "number"
    })

    resolve_callout_reference({
        callout_id = id,
        field = "header"
    })
    callout_references[id].resolved = true
end
-- ───────────────────────────────── <end> ────────────────────────────────── --

-- ========================== > define_reference < ========================== --
-- ┌┌──────────────────────────────────────────────────────────────────────┐┐ --
-- ││ Define references                                                    ││ --
-- └└──────────────────────────────────────────────────────────────────────┘┘ --
function define_callout_reference(options)
    -- Ensure options is a table
    assert(type(options) == "table", "Expected a table for 'options' but got " .. type(options))

    -- Check if the callout type is defined
    if not callout_handlers[options.callout_type] then
        warn("callout_handlers['" .. options.callout_type .. "'] is not defined.")
        return
    end

    -- Make sure arguments are of appropriate type
    assert_argument({
        arguments = options,
        name = "callout_id",
        type = "string"
    })

    assert_argument({
        arguments = options,
        name = "callout_ref",
        type = "string"
    })

    assert_argument({
        arguments = options,
        name = "callout_title",
        type = "string"
    })

    assert_argument({
        arguments = options,
        name = "callout_type_label",
        type = "string"
    })

    assert_argument({
        arguments = options,
        name = "counter_format",
        type = "string"
    })

    assert_argument({
        arguments = options,
        name = "inherits_counter",
        type = "boolean"
    })

    assert_argument({
        arguments = options,
        name = "header_level",
        type = "number"
    })

    callout_references[options.callout_id] = {
        ["type"] = options.callout_type,
        ["label"] = options.callout_type_label,
        ["id"] = options.callout_id,
        ["no"] = -1,
        ["format"] = options.counter_format,
        ["ref"] = options.callout_ref,
        ["title"] = options.callout_title,
        ["counter"] = options.callout_counter,
        ["header_level"] = options.header_level,
        ["inherits_counter"] = options.inherits_counter,
        ["header"] = insert_callout_reference({
            callout_id = options.callout_id,
            field = "label"
        }) .. " " .. insert_callout_reference({
            callout_id = options.callout_id,
            field = "number"
        }) .. ": " .. insert_callout_reference({
            callout_id = options.callout_id,
            field = "title"
        }),
        ["parents"] = {},
        ["children"] = {},
        ["header_counts"] = {},
        ["resolved"] = false,
        ["counted"] = false
    }

    if options.header_counts then
        callout_references[options.callout_id]["header_counts"] = shallow_copy(options.header_counts)
    end
end

-- ───────────────────────────────── <end> ────────────────────────────────── --

-- ========================= > construct_counter < ========================== --

-- ┌┌──────────────────────────────────────────────────────────────────────┐┐ --
-- ││ x                                                                    ││ --
-- └└──────────────────────────────────────────────────────────────────────┘┘ --
function var(varname)
    return "{{" .. varname .. "}}"
end

function resolve_varblocks(options)
    -- Ensure options is a table
    assert(type(options) == "table", "Expected a table for 'options' but got " .. type(options))

    if not options.placeholders then
        options.placeholders = {}
    end

    -- Make sure arguments are of appropriate type
    assert_argument({
        arguments = options,
        name = "format",
        type = "string"
    })

    assert_argument({
        arguments = options,
        name = "placeholders",
        type = "table"
    })

    local result = options.format
    -- Resolve placeholders
    for key, val in pairs(options.placeholders) do
        if string.find(result, var(key)) then
            -- print(var(key),"->", (val or "_"),"in",result)
            result = result:gsub(var(key), (val or "_"))
        end
    end

    -- Resolve 'or' statements
    result = string.gsub(result, "%{%{%s*(.-)%s*or%s*(.+)%s*%}%}", function(a, b)
        if a and a ~= "" then
            return a
        else
            return b
        end
    end)

    -- result = string.gsub(result, "[%{%}]", "")

    return result

end

-- ───────────────────────────────── <end> ────────────────────────────────── --

function header_level_format(level)
    counter_format_table = {}
    -- Build callout number format "1.2.3" using header levels up to `header_level`
    for i = 1, level do
        table.insert(counter_format_table, var(i))
    end
    return table.concat(counter_format_table, ".")

end

-- ======================== > define_callout_type < ========================= --

-- ┌┌──────────────────────────────────────────────────────────────────────┐┐ --
-- ││ defining a callout type with corresponding                           ││ --
-- ││ handler function and table_to_CSS style                              ││ --
-- └└──────────────────────────────────────────────────────────────────────┘┘ --

function define_callout_type(options)
    -- Use default values for missing arguments
    local body_style = options.body_style or options.style or styles.defaults.body

    local class_name = options.class_name or options.label or "default-callout"
    local collapse = (options.collapse == nil) and true or options.collapse
    local counter = (options.counter == nil) and class_name or options.counter
    local header_level = tonumber(options.header_level or 0)
    local header_style = options.header_style or options.style or styles.defaults.header
    local icon = (options.collapse == nil) and false or options.icon
    local counter_format = (options.counter_format ~= nil) and options.counter_format or nil
    local label = options.label or class_name
    local style = options.style or styles.defaults.style

    if (counter_format == "") or (counter_format == nil) then
        if header_level and (header_level > 0) then
            counter_format = header_level_format(header_level)
        else
            counter_format = "{{{{parent}} or {{1}}.{{2}}}}.{{self}}"
        end
    end

    -- Make sure arguments are of appropriate type
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
    complete(style, styles.defaults.style)
    complete(header_style, styles.defaults.header)
    complete(body_style, styles.defaults.body)

    complete(header_style, styles.defaults.style)
    complete(body_style, styles.defaults.style)

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
    define_counters(counter)
    callout_count_reset_levels[class_name] = header_level

    callout_handlers[class_name] = function(div)
        if div.classes:includes(class_name) then

            overall_callout_count = overall_callout_count + 1

            callout_id = div.identifier

            callout_ids[overall_callout_count] = callout_id

            if not callout_id or callout_id == "" then
                callout_id = "__callout[" .. overall_callout_count .. "]__"
            end

            -- Check if the callout_id already exists
            if callout_references[callout_id] then
                local new_callout_id = callout_id .. "[" .. overall_callout_count .. "]"
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
                header_counts = header_counts,
                callout_counter = counter,
                header_level = header_level or 2,
                inherits_counter = counter_format:match("%{%{parent%}%}") ~= nil

            })

            div.content = pandoc.walk_block(pandoc.Div(div.content), {
                Div = function(el)
                    if el and el.identifier and el.identifier ~= "" then
                        table.insert(callout_references[el.identifier].parents, callout_id)
                        table.insert(callout_references[callout_id].children, el.identifier)
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
                    return pandoc.Link(callout_references[citation.id]["label"] .. " " ..
                                           callout_references[citation.id]["no"], "#" .. citation.id)
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
function resolve_callout_numbers(id)
    if id and id ~= "" then
        if callout_references[id] then

            callout_references[id].number = resolve_varblocks({
                format = callout_references[id].format,
                placeholders = {
                    parent = insert_callout_reference({
                        callout_id = callout_references[id].parents[1],
                        field = "number"
                    }),
                    self = insert_callout_reference({
                        callout_id = id,
                        field = "no"
                    })

                }
            })

            callout_references[id].number = resolve_varblocks({
                format = callout_references[id].number,
                placeholders = callout_references[id].header_counts
            })

        end
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

    -- First pass: Count headers & collect callouts
    doc.blocks = pandoc.walk_block(pandoc.Div(doc.blocks), {
        Header = count_headers,
        Div = callout_handler
    }).content

    -- Process callouts
    for _, id in pairs(callout_ids) do
        resolve_callout_references(id)
    end

    -- Second pass: Output callouts
    doc.blocks = pandoc.walk_block(pandoc.Div(doc.blocks), {
        Inlines = function(d)
            for i, _ in ipairs(d) do
                if d[i].t == "Str" then
                    d[i].text = string.gsub(d[i].text, callout_field_regex_pattern(), function(id, field)
                        return callout_references[id][field]
                    end)

                end
            end
            return (d)
        end
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

