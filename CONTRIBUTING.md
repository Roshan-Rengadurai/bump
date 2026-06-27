# Contributing to Bump

Thanks for helping! Bump is a native macOS (SwiftUI + AppKit) Swift package.

## Layout

```
Sources/Bump/
  App/        SwiftUI entry, menu bar, AppState orchestrator
  Core/
    Accelerometer/  SPUAccelerometer — IOKit HID read of the SPU accelerometer
    Signal/         ImpulseDetector, DetectionPipeline
    GestureEngine/  burst grouping → single/double/triple
  Onboarding/   CalibrationView (Bump Test)
  Settings/     WaveformView, settings UI
  Models/       BumpGesture, InputSource
Resources/Info.plist     bundle metadata (LSUIElement)
Scripts/bundle.sh        builds Bump.app
spike/spike.swift        standalone proof of the unprivileged sensor read
```

## Build & run

```sh
swift build                 # compile
./Scripts/bundle.sh         # → build/Bump.app (debug)
./Scripts/bundle.sh release # optimized
```

## Permissions & code signing

macOS ties Accessibility / Input Monitoring grants (TCC) to an app's **code signature**. A pure ad-hoc signature (`-`) changes every build, so macOS forgets your grants and re-prompts each time. To keep a stable identity while developing:

1. Make a self-signed code-signing cert once (Keychain Access → Certificate Assistant → *Create a Certificate* → name it e.g. `Bump Dev`, type *Code Signing*).
2. Build with it:
   ```sh
   BUMP_SIGN_IDENTITY="Bump Dev" ./Scripts/bundle.sh
   ```

Grants then persist across rebuilds.

## Notes on the sensor

`SPUAccelerometer` reads an **undocumented** interface (`AppleSPUHIDDevice`, usage page `0xFF00`, usage 3). It can break on future macOS releases — keep it isolated behind the source so the rest of the app degrades gracefully to Trackpad Tap Mode.
