---
name: neon-flux-theme
description: "Use when applying or porting Neon Flux: read its canonical palette, map colors by role, preserve typography, and verify the rendered surface."
---

# Neon Flux theme

Dark navy surfaces, cyan as the primary accent, violet structure, and sparing
pink highlights: **cyan does the work, pink marks hot spots, violet frames.**

## Sources

Paths below are relative to the repository root, not this skill directory.

- Read `modules/features/desktop/neon-flux-theme/palette.json` before choosing
  colors. It is the canonical base palette; generate consumer values from its
  tokens rather than copying hex literals.
- Read `docs/neon-flux-porting.md` for semantic roles, ANSI sources, typography,
  and rendering checks. Bright ANSI values currently live in the Nix consumers,
  not the base JSON; do not invent a replacement scheme.
- `modules/features/desktop/neon-flux-theme.nix` implements Plasma, Konsole,
  SDDM, and wallpaper configuration. `modules/features/zed.nix` implements Zed.
  The adjacent theme `README.md` documents wallpaper and safe greeter previews.

## Porting workflow

1. Inspect the target's existing theme and supported keys in the installed build.
2. Map palette tokens by semantic role, not position. Keep dark surfaces dominant,
   accents restrained, body text on `text`, and comments on italic `comment`.
3. Generate the target format from the palette. Prefer one theme; replace obsolete
   theme rules rather than layering a second hidden configuration.
4. Preserve typography: `JetBrainsMono NFM` for the editor and
   `BlexMono Nerd Font Mono` for terminals. Verify actual font rendering.
5. Validate generated output and inspect the rendered surface. Check stylesheet
   order/specificity and composite translucent colors before judging mismatches.
   A successful write or evaluation does not prove a visible change.

Windows ports belong to the separate `neon-flux` checkout; consult its palette
and `docs/surface-mechanics.md` there rather than assuming it matches this repo.
