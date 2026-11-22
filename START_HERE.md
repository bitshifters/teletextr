# teletextr: start here

Teletextr, the Bitshifters MODE 7 (teletext) demo for the BBC Master 128, released June 2017 ("SHIP IT").
A demo: a collection of teletext effects (rotozoom, plasma, vector balls, raster bars, dot scroller, ...)
driven by a script, with VGM music, written in beebasm.

| | |
|---|---|
| GitHub | https://github.com/bitshifters/teletextr (public, Bitshifters org) |
| Local path | D:\beeb\mine\teletextr (moved from OneDrive\BEEB\Repos\teletextr on 2026-11-22) |
| Branch | `bugfix-rotozoom` (one commit past `master`: "Fixed rotozoom glitch", 2017-07-21, pushed) |
| Other branches | `master`, `wip/2026-11-tidy`, `feature-musicbars`, `feature-raycaster`, `investigation-*` (mirrorfloor, mode750, rtw-bresenham), `kieran-*` (colour-balls, crescendo, intro-timing, type-intros: their origin branches are gone) |
| Last commit | 2017-07-21: Fixed rotozoom glitch |

## What's in here
- `teletextr.asm` - the top level; `src/` - `main.asm`, `script.asm` (the sequence), `boot.asm`, `config.asm`, `fx/` (one file per effect).
- `lib/` - shared code (exomizer, VGM player, ...); `data/` - pages (`data/pages/*.exo`) and music (`*.raw.exo`), with `data/pages/compile.bat`.
- `tools/` - `exomizer.exe` and helpers; `bin/` - created by the build bat files.
- `MemoryMap.md`, `TODO.md` (the original task list), `README.md` (one line).
- `teletextr-notes.txt` - demo ideas and to-dos (see Local changes).

## Build and run
- `make`: runs `makekc.bat`: `..\..\bin\BeebAsm.exe -v -i teletextr.asm -do teletextr.ssd -boot Teletxr > compile.txt`.
  `make.bat` is the original, expecting `BeebAsm.exe` on the PATH (it is not on this machine).
- The build rewrites the committed `teletextr.ssd` and the result is not byte-identical to the committed
  image (same size), so `git status` shows it modified after a build.
- Tools: beebasm from D:\beeb\Bin. Run: `runkc.bat` opens `teletextr.ssd` in B-em (Master 128).

## Local changes
- `teletextr-notes.txt` is staged (added to the index, not committed). A copy is committed on
  `wip/2026-11-tidy` (pushed to origin 2026-11-21).
- New, uncommitted: `Makefile`, `START_HERE.md`.

## Status and next steps
- Released 2017; no work since July 2017. The `investigation-*` and `feature-*` branches are old prototypes;
  the `kieran-*` branches were merged and deleted on GitHub (local copies remain).
- Decide whether `bugfix-rotozoom` should be merged to `master`.

## See also
- `TODO.md`, `MemoryMap.md`, `teletextr-notes.txt`. Related on D: `D:\beeb\mine\teletext-broadcast`,
  `D:\beeb\mine\teletext-slojd`, `D:\beeb\mine\vgm-player-bbc`.
