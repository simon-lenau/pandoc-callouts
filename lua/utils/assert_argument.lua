-- ========================== > assert_argument < =========================== --
-- ┌┌──────────────────────────────────────────────────────────────────────┐┐ --
-- ││ DESCRIPTION                                                          ││ --
-- ││ Validates that a specific argument in a table is of expected type.   ││ --
-- ││                                                                      ││ --
-- ││ ARGUMENTS:                                                           ││ --
-- ││ options (table): Table containing the following fields:              ││ --
-- ││      - arguments (table):                                            ││ --
-- ││          Table of arguments containing the argument to validate.     ││ --
-- ││      - name (string):                                                ││ --
-- ││          Name of the argument to validate.                           ││ --
-- ││      - type_name (string):                                           ││ --
-- ││          Expected type for the argument to validate.                 ││ --
-- └└──────────────────────────────────────────────────────────────────────┘┘ --
function assert_argument(options)
    -- Ensure options is a table
    assert(type(options) == "table", "Expected a table for 'options' but got " .. type(options))

    -- Retrieve values from the options table
    local arguments = options.arguments
    local name = options.name
    local type_name = options.type

    -- Make sure argument is of appropriate type
    assert(type(arguments) == "table",
        "Expected a string for 'arguments' but got " .. type(arguments) .. " ('" .. tostring(arguments) .. "')")
    assert(type(name) == "string",
        "Expected a string for 'name' but got " .. type(name) .. " ('" .. tostring(name) .. "')")
    assert(type(type_name) == "string",
        "Expected a string for 'type' but got " .. type(type_name) .. " ('" .. tostring(type_name) .. "')")

    assert(type(arguments[name]) == type_name,
        "Expected type '" .. type_name .. "' for argument '" .. name .. "' but got " .. type(arguments[name]) .. " ('" ..
            tostring(arguments[name]) .. "')")

end

-- ───────────────────────────────── <end> ────────────────────────────────── --
return assert_argument
