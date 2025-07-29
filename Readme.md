# Quarto Lua Callout Filter

A [Quarto](https://quarto.org) / [Pandoc](https://pandoc.org) Lua filter to define and style arbitrary callouts via a `callout-types` block in your YAML header. Supports numbering based on header levels, collapse behavior, and reference resolution.
CSS styles and lua handlers are dynamically generated.

## Features

- Dynamic callout type definitions from YAML metadata
- Customizable labels, CSS styles (header, body, container)
- Collapsible callouts
- Automatic numbering based on document structure
- CSS injection into HTML output
- Citation link resolution to callout references

## Installation

1. Copy `callout.lua` (e.g. into your project's `lua/` directory)
2. Add the filter to your document's YAML header:

```yaml
filters:
  - lua/callout.lua
```

## Usage

Define your callout types in the YAML header:

```yaml
callout-types:
  - task:
      label: "Task"
      collapse: false
      header_style:
        background-color: red
  - hint:
      label: "Hint"
      collapse: true
      header_style:
        background-color: blue
```

Use callouts in your document:

```markdown
::: { .task title="Setup Environment" }
Install all dependencies.
:::

::: { .hint title="Remember" }
You can use virtual environments.
:::
```

## Options

- `label` (string): The displayed label for the callout (default: class name with first letter capitalized).
- `class_name` (string): The CSS class suffix for callout (default: key in `callout-types`).
- `collapse` (boolean): Whether the callout is collapsed by default (default: `true`).
- `header_level` (number): How many header levels to include in automatic numbering (default: `2`).
- `icon` (boolean): Whether to show an icon (default: `false`).
- `style`, `header_style`, `body_style` (tables): CSS settings for the outer container, header, and body. Defaults include a 1px solid border, black header text on white background, etc.

## Example

See [examples/main.qmd](examples/main.qmd) for a full example:

```yaml
title: "Advanced quarto callouts"
filters:
  - lua/callout.lua
callout-types:
  - task:
      label: "Task"
      collapse: false
      header_style:
        background-color: red
  - hint:
      label: "Hint"
      collapse: true
```

```markdown
## Subheader

::: { .task title = "Title" }

::: { .hint title = "ABC" }
::: { .hint title = "DEF" }
  Some more text
:::
:::
::: { .sol title = "This is a solution" }
  Some more more text
:::
:::
```

## Under the Hood

The filter workflow:

1. **Metadata parsing**: Reads `callout-types` from document metadata (`process_yaml`).
2. **YAML conversion**: Converts each YAML entry to a Lua table (`yaml_to_table`).
3. **Callout definition** (`define_callout_type`):
   - Fills missing style parameters with defaults (`complete`).
   - Appends `!important` to CSS properties.
   - Generates CSS rules, inserted into the document header (`add_css_to_meta`).
   - Registers a handler for `Div` elements matching the class, leveraging [Quarto's Callout API](https://quarto.org/docs/prerelease/1.3/custom-ast-nodes/callout.html) to produce HTML with titles and collapse behavior.
4. **Document transformation**:
   - First pass: Counts headers and injects callout Divs (`callout_handler`).
   - Second pass: Resolves citation links to callout references (`resolve_references`).
5. Returns the transformed `Pandoc` document.

## Contributing

Contributions welcome! Please open issues or pull requests to improve styles, add features, or fix bugs.

## License

GPL-3 License. See [LICENSE](LICENSE) for details.

