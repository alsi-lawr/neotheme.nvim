# Simplified palette guide

Built-in themes start with a compact `NeothemeSimplifiedPalette`. Each color has a visual responsibility, not just a literal name. Several fields deliberately fan out across syntax, diagnostics, markup, version control, and editor chrome, so choose them by the effect described below.

A color being present in the palette does not make it part of the theme's visible identity. Keywords, functions, strings, types, properties, and literals occur with very different frequency in ordinary code, while diagnostics and conflicts may be absent from a normal editing session. Put defining flavor colors on roles that appear often enough to establish the intended character, and use sparse roles for focused signals. Conversely, only give `syntax_keyword` a color that should dominate both code and editor chrome, because its effect extends far beyond language keywords.

## Surfaces

- **`surface_deepest`** is the strongest depth color. It appears behind deep shadows and, unless overridden, becomes the foreground placed on accent-colored blocks.
- **`surface_dark`** separates secondary and inactive chrome from the main editor, including inactive status areas, tab lines, side panels, and recessed UI.
- **`surface_base`** is the main editor canvas. It carries normal buffers, ordinary panels, and the terminal background, so every foreground color must work against it.
- **`surface_raised`** lifts temporary or focused structure above the base: cursor lines, floating windows, popup menus, prompts, and changed-line backgrounds.
- **`surface_selected`** marks deliberate selection and active emphasis. It is used for visual selections, selected menu entries, references, active status sections, and strong diff emphasis.
- **`surface_border`** draws structural edges such as window separators, float borders, menu borders, and plugin panel outlines.
- **`surface_muted`** is low-priority chrome. It colors line numbers, whitespace, separators, scrollbar details, ignored version-control states, and other information that should recede.
- **`surface_addition`** is the quiet positive background used for added content and read-reference emphasis. It should support a success foreground without becoming a full alert.
- **`surface_error`** is the solid error background used when an error must read as a block rather than a foreground mark. It is paired with `text_on_error`.

## Text

- **`text_primary`** is ordinary readable text: identifiers, prose, messages, menus, panels, and the terminal foreground.
- **`text_bright`** is a brighter supporting foreground for punctuation, winbars, filenames, and UI text that needs more presence than normal text without becoming the strongest emphasis.
- **`text_strong`** is the highest neutral emphasis. It appears in selected rows, active status sections, diff focus, and other places that should remain prominent even without an accent hue. It also supplies the strongest regular terminal text, including ANSI bright white (color 15).
- **`text_muted`** is annotation text: inactive UI, inlay hints, code lenses, metadata, secondary labels, and de-emphasized content. If omitted, `syntax_type` supplies it.
- **`text_on_accent`** must remain readable when placed directly on the accent color, including cursors, search blocks, active snippets, prompts, and mode sections. If omitted, `surface_deepest` supplies it.
- **`text_on_error`** is the foreground placed on semantic error and conflict blocks, including error messages and substitute highlights. It is not a general or terminal text color.

## Syntax and semantic accents

- **`syntax_comment`** controls comments and other reflective or quoted material, including folds, markup quotes, low-priority preprocessor text, and the quietest heading level.
- **`syntax_string`** is broader than quoted strings. It also expresses success, additions, checked items, and raw markup, making it the palette's ordinary positive color.
- **`syntax_keyword`** has the largest visual footprint. It colors keywords and operators, but also warnings, primary headings, changed content, search matches, the cursor, and the general UI accent. This color often determines the theme's overall identity.
- **`syntax_function_name`** identifies functions, methods, tags, links, directories, and informational diagnostics. It is the main navigational and callable-symbol color.
- **`syntax_type`** covers types and attributes, plus secondary structural markup and unchecked items. It also becomes muted text when `text_muted` is absent.
- **`syntax_property`** is the narrow field/member color. It is useful for separating object structure without affecting broad UI or diagnostic categories.
- **`syntax_literal`** colors numbers, booleans, constants, and similar literal values. It also appears in hints, matches, mathematical markup, and a few positional or completion details, so it provides visible but non-dominant contrast.

## Errors and conflicts

- **`diagnostic_error`** is the active error signal. It also colors removed content, regular expressions, special syntax, spelling errors, and other exceptional tokens, so it should be distinct without overwhelming normal code.
- **`version_control_conflict`** is reserved for merge conflicts, conflicting changes, and substitute-style conflict emphasis. It can be related to the error color, but should remain distinguishable from it.

The authoritative expansion is implemented in [`lua/neotheme/themes/simplified.lua`](lua/neotheme/themes/simplified.lua). After changing a compact field, inspect both the palette card and an editor capture: the card verifies the input, while the capture reveals its full visual footprint.

## Persistent editor records

The `:NeothemePalette` workspace can retain either this 24-field Simplified source or a complete
59-field Full source. Themes `a` visibly selects **Simplified palette** or **Full palette** before
asking for a name; cancellation at either step changes nothing. Simplified groups the required flat
fields into Surface (9), Text (6), Syntax (7), and Signals (`diagnostic_error` and
`version_control_conflict`). Full uses Surface, Text, Syntax, Diagnostic, Markup, Version control,
and UI. The role title labels the mode, numeric tabs and `[`/`]` stay within that mode, and the
adjacent `background = dark|light` row controls theme metadata. Every visible valid token uses its
color and a readable foreground. An invalid field is diagnosed in place, keeps the last valid
private preview, and blocks category movement and `:write`; bundled palettes remain templates and
must be cloned before editing.

The navigator keeps its tabs and contextual controls outside the scrolling inventory. Use `1` for
Families, `2` for Themes, or `<Tab>`/`<S-Tab>` to cycle. Families provide `a` create, `v` visibility,
and `d` deletion for empty user-created families. On Themes, `a` adds the selected mode from its
separate fixed neutral dark or light source following `vim.o.background`; it does not inherit
another palette. Use `c` to clone the selected theme instead. Persisted user clones preserve mode
and authoritative source; bundled, configured, custom, and empty-family configured snapshots clone
as Full expanded palettes. `e` edits user themes, while `d` deletes user themes that are not
configured, active, or retained session overrides. Built-in and user entries are labelled
explicitly. Delete actions use `delete? Y/n`; only `Y`, `y`, or the default confirms.

Use `C` in either editable panel for the confirmed `commit? Y/n` path, or `:write` for an
unprompted commit. Both validate and atomically persist the complete palette. Declining or
cancelling a confirmed commit leaves the dirty in-memory palette and the existing JSON bytes
unchanged. Press `q` or `<Esc>` from either panel to close a clean workspace. Dirty workspaces stay
open with every edit preserved; use `C` or `:write` to save, or `:q!` to discard and close.

New and committed theme records use schema version 2 with an explicit `simplified` or `full` mode.
Strict mode-less v1 records continue to load as Full and upgrade on commit without changing their
expanded palette. Simplified records must contain exactly all 24 compact colors, including
`text_muted` and `text_on_accent`; runtime lookup always returns a fresh complete expansion through
this module. Mode conversion and overrides of roles derived from a Simplified source are out of
scope.
