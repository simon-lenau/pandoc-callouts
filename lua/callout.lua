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

local overall_callout_count = 0

-- ========================= > Table definitions < ========================== --

local header_counts = {}
local headcounts = {}
local callout_count_reset_levels = {}
local callout_counts = {}
local callout_ids = {}
local callout_handlers = {}
local callout_references = {}

-- ───────────────────────────────── <end> ────────────────────────────────── --

-- ========================== > callout_handler < =========================== --

-- ┌┌──────────────────────────────────────────────────────────────────────┐┐ --
-- ││ Handler for running the handlers for callout utils.add_callout_style       ││ --
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

-- ========================= > Resolve references < ========================= --
function resolve_citations(cite)
    if cite.citations then
        for _, citation in ipairs(cite.citations) do
            if citation.id then
                if callout_references[citation.id] then
                    return pandoc.Link(callout_references[citation.id]["label"] .. " " ..
                                           callout_references[citation.id]["number"], "#" .. citation.id)
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

    local references = {
        callout_count_reset_levels = callout_count_reset_levels,
        callout_handlers = callout_handlers,
        overall_callout_count = overall_callout_count,
        callout_ids = callout_ids,
        callout_references = callout_references,
        header_counts = header_counts,
        headcounts = headcounts,
        callout_counts = callout_counts,
        styles = styles
    }

    -- Create callout type definitions
    utils.process_yaml(doc.meta, references)

    -- Add CSS to meta data
    utils.add_css_to_meta(doc.meta, references)

    -- First pass: Count headers & collect callouts
    doc.blocks = pandoc.walk_block(pandoc.Div(doc.blocks), {
        Header = function(header)
            utils.count_headers(header, references)
        end,
        Div = callout_handler
    }).content

    -- Process callouts
    for _, id in pairs(callout_ids) do
        utils.resolve_callout_references(id, references)
    end

    -- Second pass: Output callouts
    doc.blocks = pandoc.walk_block(pandoc.Div(doc.blocks), {
        Inlines = function(d)
            for i, _ in ipairs(d) do
                if d[i].t == "Str" then
                    d[i].text = string.gsub(d[i].text, utils.callout_field_regex_pattern(), function(id, field)
                        return callout_references[id][field]
                    end)

                end
            end
            return (d)
        end
    }).content

    -- Third pass: resolve citations
    doc.blocks = pandoc.walk_block(pandoc.Div(doc.blocks), {
        Cite = resolve_citations
    }).content

    return doc
end

return {{
    Pandoc = Pandoc
}}

