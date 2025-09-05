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
local resolvers = require("resolvers")

-- Main handler: runs after full document is loaded
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
    resolvers.process_yaml(doc.meta, references)

    -- Add CSS to meta data
    utils.add_css_to_meta(doc.meta, references)

    -- First pass: Count headers & collect callouts
    doc.blocks = pandoc.walk_block(pandoc.Div(doc.blocks), {
        Header = function(header)
            utils.count_headers(header, references)
        end,
        Div = function(div)
            return resolvers.Div(div, references)
        end
    }).content

    -- Process callouts
    for _, id in pairs(references.callout_ids) do
        utils.resolve_callout_references(id, references)
    end

    -- Second pass: Output callouts
    doc.blocks = pandoc.walk_block(pandoc.Div(doc.blocks), {
        Inlines = function(inline)
            return resolvers.Inlines(inline, references)
        end

    }).content

    -- Third pass: resolve citations
    doc.blocks = pandoc.walk_block(pandoc.Div(doc.blocks), {
        Cite = function(citation)
            return resolvers.Cite(citation, references)
        end
    }).content

    return doc
end

return {{
    Pandoc = Pandoc
}}
