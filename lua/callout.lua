local function file_path()
    local info = debug.getinfo(1, 'S')
    local source = info.source
    if source:sub(1, 1) == '@' then
        local fullpath = source:sub(2) -- "/some/path/filter.lua"
        local dir = fullpath:match("(.*/)")
        local file = fullpath:match("([^/]+)$") -- "filter.lua"
        return dir, file, fullpath
    else
        return nil, nil, nil -- running from string, not a file
    end
end

local script_path, _, _ = file_path()

if script_path then
    package.path = script_path .. "?.lua;" .. package.path
end

local styles = require("styles")
local utils = require("utils")
local data = require("data")

-- ========================== > callout_handler < =========================== --

-- ┌┌──────────────────────────────────────────────────────────────────────┐┐ --
-- ││ Handler for running the handlers for callout utils.add_callout_style ││ --                
-- └└──────────────────────────────────────────────────────────────────────┘┘ --

function callout_handler(div, references)
    -- Apply defined callout handlers
    for _, handler in pairs(references.callout_handlers) do
        local result = handler(div)
        if result then
            return result
        end
    end
    return div
end

-- ───────────────────────────────── <end> ────────────────────────────────── --

-- ========================= > Resolve references < ========================= --
function resolve_citations(cite, references)
    utils.assert_argument({
        arguments = references,
        name = "callout_references",
        type = "table"
    })

    if cite.citations then
        for _, citation in ipairs(cite.citations) do
            if citation.id then
                if references.callout_references[citation.id] then
                    return pandoc.Link(references.callout_references[citation.id]["label"] .. " " ..
                                           references.callout_references[citation.id]["number"], "#" .. citation.id)
                end
            end
        end
    end
    return cite
end
-- ───────────────────────────────── <end> ────────────────────────────────── --

-- Master handler: runs after full document is loaded
function Pandoc(doc)
    -- Only run if any callout-types are defined in yaml header
    if not doc.meta['callout-types'] then
        return doc
    end

    local references = data.new.references({
        callout_count_reset_levels = data.new.empty_table(),
        callout_handlers = data.new.empty_table(),
        overall_callout_count = 0,
        callout_ids = data.new.empty_table(),
        callout_references = data.new.empty_table(),
        header_counts = data.new.empty_table(),
        headcounts = data.new.empty_table(),
        callout_counts = data.new.empty_table(),
        styles = styles
    })

    -- Create callout type definitions
    utils.process_yaml(doc.meta, references)

    -- Add CSS to meta data
    utils.add_css_to_meta(doc.meta, references)

    -- First pass: Count headers & collect callouts
    doc.blocks = pandoc.walk_block(pandoc.Div(doc.blocks), {
        Header = function(header)
            utils.count_headers(header, references)
        end,
        Div = function(div)
            return callout_handler(div, references)
        end
    }).content

    -- Process callouts
    for _, id in pairs(references.callout_ids) do
        utils.resolve_callout_references(id, references)
    end

    -- Second pass: Output callouts
    doc.blocks = pandoc.walk_block(pandoc.Div(doc.blocks), {
        Inlines = function(inline)
            for i, _ in ipairs(inline) do
                if inline[i].t == "Str" then
                    inline[i].text = string.gsub(inline[i].text, utils.callout_field_regex_pattern(),
                        function(id, field)
                            return references.callout_references[id][field]
                        end)

                end
            end
            return inline
        end
    }).content

    -- Third pass: resolve citations
    doc.blocks = pandoc.walk_block(pandoc.Div(doc.blocks), {
        Cite = function(citation)
            return resolve_citations(citation, references)
        end
    }).content

    return doc
end

return {{
    Pandoc = Pandoc
}}
