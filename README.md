# Bump (open source)

**Control your Mac with taps.** Bump on your MacBook's chassis — or tap the trackpad — and turn single / double / triple bumps into actions: mute, lock, screenshot, switch desktops, run scripts, and more.

A free, open-source, native macOS alternative to paid tap-control apps. No subscription, no Pro tier — every feature is free.

> **Status:** early. The native accelerometer engine works (unprivileged, ~800 Hz on Apple Silicon MacBooks). UI, actions, and onboarding are in progress.

## How it works

Apple Silicon MacBooks have a built-in accelerometer. Bump reads it directly (via the undocumented `AppleSPUHIDDevice` HID interface — **no root required**), watches for the sharp vibration spikes a physical tap makes, and groups them into single/double/triple gestures. Typing is suppressed so your keystrokes don't fire false bumps.

Macs without the sensor (or any Mac you prefer) can use **Trackpad Tap Mode** instead.

## Install (unsigned build)

This app is **not notarized** (notarization requires a paid Apple Developer account). macOS Gatekeeper will warn you. To run it:

1. Download `Bump.app.zip` from [Releases](#) and unzip.
2. Move `Bump.app` to `/Applications`.
3. Remove the quarantine flag:
   ```sh
   xattr -dr com.apple.quarantine /Applications/Bump.app
   ```
   (or right-click the app → **Open** → **Open** the first time.)
4. Launch it — Bump lives in the menu bar.

On first run, grant **Accessibility** and **Input Monitoring** when prompted (needed to run actions and suppress typing).

## Build from source

Requires Xcode / the Swift toolchain.

```sh
git clone <repo-url> bump && cd bump
./Scripts/bundle.sh release      # → build/Bump.app
open build/Bump.app
```

Or open `Package.swift` in Xcode and Run.

## Contributing

PRs welcome. See [CONTRIBUTING.md](CONTRIBUTING.md). MIT licensed.
