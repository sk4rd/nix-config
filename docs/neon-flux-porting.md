# Neon Flux porting reference

The authoritative base colors are in
[`palette.json`](../modules/features/desktop/neon-flux-theme/palette.json).
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
is defined in `ansiBright` in both
[`neon-flux-theme.nix`](../modules/features/desktop/neon-flux-theme.nix) and
[`zed.nix`](../modules/features/zed.nix); it is not fully represented in the base
palette JSON. Inspect those definitions when porting; keep them consistent rather
than maintaining another table here. Derive faint (SGR 2) colors halfway to the
canvas per channel when needed.

## Typography

- Editor: `JetBrainsMono NFM`, `calt` ligatures and slashed `zero`.
- Terminal and prompt: `BlexMono Nerd Font Mono`.
- Use the installed Nerd Font family names (`NF`, `NFM`, `NFP` where applicable).
  Verify the actual font instead of trusting the configured string; spelled-out
  JetBrains names have caused silent fallback on Windows.
- Do not claim which `ss01`/`ss02` set is “Classic” or “Closed” without evidence.

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
  the [theme README](../modules/features/desktop/neon-flux-theme/README.md).
  Do not restart an active display manager or lock a session just for a screenshot.

Windows surfaces belong to the separate `neon-flux` repository. Its palette and
`docs/surface-mechanics.md` are the references for those ports; do not assume
that checkout exists or its colors are synchronized with this repository.
