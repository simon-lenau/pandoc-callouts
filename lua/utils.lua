local utils = {}

local names = {"complete", "important", "is_empty", "yaml_to_table", "table_to_CSS", "define_callout_type",
               "header_level_format", "add_callout_style", "assert_argument", "define_counters",
               "define_callout_reference", "insert_callout_reference", "shallow_copy", "resolve_callout_references",
               "callout_field_regex_pattern", "resolve_callout_numbers", "resolve_varblocks", "count_headers", "warn","add_css_to_meta", "process_yaml"}

for _, name in ipairs(names) do
    utils[name] = require("utils." .. name)
end

return utils
