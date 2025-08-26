local function insert_callout_reference(options)
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

return insert_callout_reference