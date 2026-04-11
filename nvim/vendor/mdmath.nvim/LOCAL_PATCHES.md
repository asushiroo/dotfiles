# Local patches

This vendored copy of `mdmath.nvim` contains local modifications for this dotfiles repo.

## Patched behavior

- block formulas (`$$...$$`) keep mdmath image rendering
- inline formulas (`$...$`) are auto-detected and rendered with inline extmarks
- inline formulas use smaller scale values than block formulas
- inline formulas use Tree-sitter-provided inline/block info when available
- selected inline descender glyphs (`\beta`, `\zeta`, `\xi`, `\phi`, `\psi`) are rendered with a slightly smaller scale so they fit inside a single terminal row without clipping
- selected slightly-tall inline glyphs (`\theta`, `\lambda`, `\mu`, `\chi`) are rendered with a mildly reduced scale for better baseline consistency
- inline expressions containing those glyphs also get a gentler expression-level scale reduction to avoid clipping in mixed formulas
- block formulas now use smaller default scales; single-symbol display equations render at inline-sized height, while fraction-style display equations render to unit heights (`\frac` ≈ 2 units, `\dfrac` ≈ 3 units)
- inline rendering cleans up its own extmarks/images on invalidate
- color handling is normalized to hex before requests are sent to the Node processor
- `mdmath-js/node_modules/mathjax` is vendored so the plugin works after dotfiles sync without requiring an immediate `npm install`
- when terminal `ioctl(TIOCGWINSZ)` does not report pixel dimensions correctly (common in SSH/tmux chains), cell size falls back to `tmux display-message` client cell metrics

## Important file

- `lua/mdmath/Equation.lua`

If you update from upstream later, re-check this file first.
