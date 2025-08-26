-- =========================== > yaml_to_table < ============================ --
-- ┌┌──────────────────────────────────────────────────────────────────────┐┐ --
-- ││ Convert yaml specification to named lua table                        ││ -- 
-- └└──────────────────────────────────────────────────────────────────────┘┘ --
local function yaml_to_table(list)
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
return yaml_to_table