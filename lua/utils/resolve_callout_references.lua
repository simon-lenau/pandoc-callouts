local names = {"assert_argument", "is_empty", "resolve_callout_reference","resolve_callout_numbers"}
local utils = {}
for _, name in ipairs(names) do
    utils[name] = require("utils." .. name)
end

-- ===================== > resolve_callout_references < ===================== --

-- ┌┌──────────────────────────────────────────────────────────────────────┐┐ --
-- ││ x                                                                    ││ --
-- └└──────────────────────────────────────────────────────────────────────┘┘ --

local function resolve_callout_references(id, references)

    utils.assert_argument({
        arguments = references,
        name = "callout_references",
        type = "table"
    })

    utils.assert_argument({
        arguments = references,
        name = "headcounts",
        type = "table"
    })

    if (not id) or (id == "") then
        return
    end
    -- Resolve only un-resolved references
    if references.callout_references[id].resolved then
        return
    end

    if not (id and references.callout_references[id]) then
        return
    end

    -- Count children
    local child_counters = {}
    for _, child_id in ipairs(references.callout_references[id].children) do
        if child_id and not references.callout_references[child_id].counted then
            references.callout_references[child_id].counted = true
            child_counters[references.callout_references[child_id].type] =
                (child_counters[references.callout_references[child_id].type] or 0) + 1
            references.callout_references[child_id].no = child_counters[references.callout_references[child_id].type]
        end
    end

    -- Resolve parents first
    --      inherited information may be needed
    for _, parent_id in pairs(references.callout_references[id].parents) do
        if parent_id then
            resolve_callout_references(parent_id, references)
        end
    end
    if (utils.is_empty(references.callout_references[id].parents) or
        not references.callout_references[id].inherits_counter) then
        local reset_counter = false
        for i = 1, references.callout_references[id].header_level do

            reset_counter = ((references.headcounts[references.callout_references[id].counter][i] or -2) ~=
                                (references.callout_references[id].header_counts[i] or -1))

            if reset_counter then
                break
            end
        end

        if reset_counter then
            references.headcounts[references.callout_references[id].counter] =
                references.callout_references[id].header_counts
            references.callout_counts[references.callout_references[id].type] = 0
        end

        -- Increase counter for current callout type
        references.callout_counts[references.callout_references[id].type] =
            (references.callout_counts[references.callout_references[id].type] or 0) + 1
        references.callout_references[id].no = references.callout_counts[references.callout_references[id].type]

    end

    for key, _ in pairs(references.callout_references[id]) do
        if type(references.callout_references[id][key]) ~= "table" and type(references.callout_references[id][key]) ~=
            "boolean" then
            utils.resolve_callout_reference({
                callout_id = id,
                field = key
            },references)
        end
    end
    utils.resolve_callout_numbers(id,references)
    utils.resolve_callout_reference({
        callout_id = id,
        field = "number"
    }, references)

    utils.resolve_callout_reference({
        callout_id = id,
        field = "header"
    }, references)
    references.callout_references[id].resolved = true
end
-- ───────────────────────────────── <end> ────────────────────────────────── --

return resolve_callout_references
