# Neon Flux porting reference

The authoritative base colors are in
[`palette.json`](../themes/neon-flux/palette.json).
Read it from disk before porting; this document intentionally does not duplicate
its hex values. Map roles to the target's supported names, not colors by position.

## Surface and syntax roles

Use `canvas` for the main background, `surface` for adjacent chrome, and `raised`
for widgets and inputs. Use `currentLine`, `border`, and `selection` for their
named purposes; `selectionTranslucent` needs compositing over the actual background.
Use `text` for body text, `muted` for secondary/disabled UI, and `lineNumber` for
inactive line numbers. Active line numbers and cursors use `accent`.

| Syntax role | Palette token |
|---|---|
| Namespace, type, class, enum, interface, struct | `info` |
| Keyword, modifier | `purple` |
| Function, method | `accent` |
| String, decorator | `warning` |
| Property, operator, type parameter | `accentBright` |
| Number, macro, enum member, label | `hot` |
| Variable, parameter | `text` |
| Comment | `comment`, italic |
| Regular expression | `error` |

Use `structure` for violet framing, and `success`, `warning`, `error`, and `info`
for status. Unstyled tokens fall back to `muted`. Cyan is the primary accent;
pink and violet are restrained highlights, not large saturated surfaces.

## Terminal colors

Use `canvas`, `text`, `selection`, and `accent` for the terminal background,
foreground, selection, and cursor respectively.

Normal ANSI slots map to `surface`, `error`, `success`, `warning`, `info`,
`purple`, `accent`, and `text` in black-to-white order. The existing bright row
is defined in `ansiBright` in
[`neon-flux-theme.nix`](../modules/features/desktop/neon-flux-theme.nix); it is not fully represented in the base
palette JSON. Inspect that definition when porting; keep consumers consistent rather
than maintaining another table here. Derive faint (SGR 2) colors halfway to the
canvas per channel when needed.

## Typography

- Editor: `JetBrainsMono NFM`, `calt` ligatures and slashed `zero`.
- Terminal and prompt: `BlexMono Nerd Font Mono`.
- Use the installed Nerd Font family names (`NF`, `NFM`, `NFP` where applicable).
  Verify the actual font instead of trusting the configured string; spelled-out
  JetBrains names have caused silent fallback on Windows.
- Do not claim which `ss01`/`ss02` set is “Classic” or “Closed” without evidence.

## Dark Reader

The Brave aspect installs Dark Reader and Proton Pass from the Chrome Web Store.
Brave Shields provides built-in ad and tracker blocking.

The Brave Neon Flux aspect generates Dark Reader settings and CSS from the shared
palette. It uses dynamic rendering with the canvas/text colors, selection, and
scrollbar mapped to Neon Flux. Neutral background colors are pinned through Dark
Reader's `--darkreader-background-<source hex>` variables: white/off-white panels
use `surface`, mid-gray headers use `raised`, and neutral borders use `border`.
Common cream backgrounds (including the portal's `#f6f3ec`) use `surface` instead
of turning brown. These overrides are `!important` because Dark Reader updates
its palette variables at runtime. This avoids blanket element backgrounds that
would destroy transparency, semantic warning colors, SVG artwork, or images.
CSS also supplies cyan links, purple visited links, raised inputs, surface
buttons/dialogs/code blocks, muted placeholders, and cyan focus rings. Site syntax
highlighting remains handled by Dark Reader. Automatic
dark-site detection is disabled so native dark themes can also receive Neon Flux.

After activating Home Manager:

1. Open Dark Reader's **More → All settings → Advanced → Import Settings** and
   select `~/.config/BraveSoftware/neon-flux-dark-reader.json`.
2. Open Dark Reader's **Dev tools** (Developer Tools) and select the
   **Dynamic Theme Editor** if an editor selector is shown.
3. In the first, global `*` block, replace the previous Neon Flux CSS with
   `~/.config/BraveSoftware/neon-flux-dark-reader.css` at the end of its `CSS`
   section, before the next directive or `====` separator. The generated CSS has
   `BEGIN NEON FLUX` / `END NEON FLUX` markers for subsequent replacements. Keep
   the existing Dark Reader global rules and site-specific blocks, then click **Apply**.
4. Reload an ordinary website to check the result. Brave internal pages and other
   extensions' pages cannot be styled by Dark Reader.

The dynamic engine ignores `theme.stylesheet`; custom CSS must go through its
Developer Tools fixes. Repeat the import and replace the appended CSS after palette
changes. Chromium extension storage is owned by the browser, so Home Manager does
not overwrite these settings on activation. Importing the JSON updates the global
theme; existing site-specific themes or presets can still take precedence.

The browser regression test uses the same Dark Reader 4.9.133 version as Brave.
Install `playwright-core` and `darkreader@4.9.133` into a scratch directory, then
run against the generated CSS (no live profile is modified):

```sh
NODE_PATH=<scratch>/node_modules node modules/features/brave/test-dark-reader.cjs \
  ~/.config/BraveSoftware/neon-flux-dark-reader.css /path/to/brave
```

It checks neutral panels, headers, borders, cream and dynamically added inline
backgrounds, while ensuring transparency, warning colors, SVG fills and gradients
survive. The neutral overrides depend on Dark Reader's variable naming; rerun the
test after extension upgrades. Unlisted tinted colors remain Dark Reader-managed.

Brave uses dark browser chrome and a locally loaded Manifest V3 extension for the
Neon Flux new-tab page. The same launchpad is configured as its homepage. Restart
Brave after activation to pick up the generated extension and command-line flags.

## Verification

- Validate color keys against the installed target version. Unknown keys can be
  ignored even when configuration generation succeeds.
- Run the generated script or format validator when applicable. Be careful with
  newline escaping when writing JavaScript through JSON tools.
- Inspect stylesheet order and specificity: equal-specificity overrides must
  follow the rules they replace.
- Inspect a full-resolution render. Pixel-sample solid blocks where possible;
  judge small text visually rather than demanding exact counts from antialiasing.
- Compute translucent composites over their actual backgrounds; do not expect
  the literal alpha token to appear as an opaque screenshot color.
- Do not infer exact colors from a scaled screenshot. If a render is unavailable,
  report generated-output validation separately from unverified appearance.
- For SDDM and screen-lock previews, follow the safe test-mode instructions in
  the [theme README](../themes/neon-flux/README.md).
  Do not restart an active display manager or lock a session just for a screenshot.

Windows surfaces belong to the separate `neon-flux` repository. Its palette and
`docs/surface-mechanics.md` are the references for those ports; do not assume
that checkout exists or its colors are synchronized with this repository.
