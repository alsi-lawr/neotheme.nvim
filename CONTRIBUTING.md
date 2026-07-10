# Contributing to neotheme.nvim

Thanks for helping improve Neotheme. Changes should preserve the semantic palette model: themes choose colors for roles, and highlight modules consume those roles.

## Local setup

You need Neovim 0.12 or newer and StyLua.

Run the same checks used by CI from the repository root:

```sh
stylua --check .
./tests/run.sh
```

Format Lua changes before committing:

```sh
stylua .
```

## Making changes

### Themes and palettes

- Give palette fields semantic names that describe their purpose.
- Keep raw color values in theme definitions rather than repeating them in highlight modules.
- Supply every field defined by the palette schema when adding a built-in theme.
- Map UI behavior to palette roles instead of special-casing a built-in theme.

Tests should verify palette completeness, public behavior, or semantic role selection. Do not assert a built-in theme's exact hex values.

### Highlights and integrations

- Core, Tree-sitter, LSP, and terminal highlights belong under `lua/neotheme/highlights/`.
- Optional plugin support belongs in a focused module under `lua/neotheme/integrations/`.
- Add an integration to the configuration schema and integration loader, and leave it disabled by default.
- Test the general contract the integration relies on, not a snapshot of every generated color.
- Document new public options or integrations in the README.

## Pull requests

- Keep each commit focused and use a conventional commit message.
- Explain the user-visible effect and any compatibility implications.
- Include the commands you ran and their results.
- Keep unrelated formatting, renames, and cleanup out of the change.

All required CI checks must pass before merge. Neovim nightly is advisory and may expose upcoming compatibility work without blocking a contribution.
