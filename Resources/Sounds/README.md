# Combo sounds

Drop short audio clips here and Bump plays a **random one on each combo hit**
(so a streak of knocks varies — like Jet Set Radio's spray cans).

- Supported: `.wav`, `.mp3`, `.m4a`, `.aiff`, `.caf`
- Name them anything, e.g. `spray1.wav`, `spray2.wav`, `spray3.wav`, …
- `Scripts/bundle.sh` copies this folder into `Bump.app/Contents/Resources/Sounds`.

If this folder has no audio clips, Bump falls back to the system "Pop" sound.

> Note: ship only audio you have the rights to. The "Jet Set Radio" spray SFX
> are copyrighted by Sega — add them locally for personal use; don't redistribute
> them in the public release build.
