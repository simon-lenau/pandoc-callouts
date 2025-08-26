local function header_level_format(level)
    counter_format_table = {}
    -- Build callout number format "1.2.3" using header levels up to `header_level`
    for i = 1, level do
        table.insert(counter_format_table, var(i))
    end
    return table.concat(counter_format_table, ".")
end
return header_level_format

