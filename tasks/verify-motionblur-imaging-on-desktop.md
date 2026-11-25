# Run `chapt06/motionblur` and `chapt07/imaging` on a real desktop

**Status:** blocked **Priority:** 3 **Difficulty:** 1
**Blocked on:** the maintainer running the two demos on a real display after a rebuild.
**Recheck:** `cmake --build build/cmake`, then run `build/cmake/bin/chapt06/motionblur/motionblur` and `build/cmake/bin/chapt07/imaging/imaging`; cleared when both look right (motion blur trails, imaging operations apply).
**Created:** 2026-11-25 (William Emerison Six <billsix@gmail.com>)
**Source:** the verification list at the end of `tasks/archive/2026/11/23/headless-demo-gaps.md`.

## BLUF

The accumulation-buffer replacement in `chapt06/motionblur` and the CPU imaging operations in `chapt07/imaging` were checked only under Xvfb. Done = both run correctly on a real desktop; record the result here and archive.
