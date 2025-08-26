


local names = {"assert_argument","insert_callout_reference","shallow_copy","warn"}
local utils = {}
for _, name in ipairs(names) do
    utils[name] = require("utils." .. name)
end


-- ========================== > define_reference < ========================== --
-- ┌┌──────────────────────────────────────────────────────────────────────┐┐ --
-- ││ Define references                                                    ││ --
-- └└──────────────────────────────────────────────────────────────────────┘┘ --
local function define_callout_reference(options,references)
    -- Ensure options is a table
    assert(type(options) == "table", "Expected a table for 'options' but got " .. type(options))

    -- Check if the callout type is defined
    if not references.callout_handlers[options.callout_type] then
        utils.warn("Handler for callout type '" .. options.callout_type .. "' is not defined.")
        return
    end

    -- Make sure arguments are of appropriate type
    utils.assert_argument({
        arguments = options,
        name = "callout_id",
        type = "string"
    })

    utils.assert_argument({
        arguments = options,
        name = "callout_ref",
        type = "string"
    })

    utils.assert_argument({
        arguments = options,
        name = "callout_title",
        type = "string"
    })

    utils.assert_argument({
        arguments = options,
        name = "callout_type_label",
        type = "string"
    })

    utils.assert_argument({
        arguments = options,
        name = "counter_format",
        type = "string"
    })

    utils.assert_argument({
        arguments = options,
        name = "inherits_counter",
        type = "boolean"
    })

    utils.assert_argument({
        arguments = options,
        name = "header_level",
        type = "number"
    })

    references.callout_references[options.callout_id] = {
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
        ["header"] = utils.insert_callout_reference({
            callout_id = options.callout_id,
            field = "label"
        }) .. " " .. utils.insert_callout_reference({
            callout_id = options.callout_id,
            field = "number"
        }) .. ": " .. utils.insert_callout_reference({
            callout_id = options.callout_id,
            field = "title"
        }),
        ["parents"] = {},
        ["children"] = {},
        ["header_counts"] = {},
        ["resolved"] = false,
        ["counted"] = false
    }

    if references.header_counts then
        references.callout_references[options.callout_id]["header_counts"] = utils.shallow_copy(references.header_counts)
    end
end

-- ───────────────────────────────── <end> ────────────────────────────────── --
return define_callout_reference