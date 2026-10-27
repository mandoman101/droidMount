# DroidMount

**Native macOS Flutter desktop file manager & high-speed ADB sync transfer utility for Android devices.**

Built by [MANDO–MAN Software](https://github.com/mandoman101).

## Project Overview

DroidMount bridges macOS and Android in one polished desktop app. Connect via USB or wireless TLS, browse the device filesystem, manage file transfers with live telemetry — all with a slick Material 3 Dark/Aqua experience.

## Architecture & Directory Structure

```
lib/
├── main.dart              # Application entry point
├── app.dart               # MaterialApp root (Dark + Aqua #00F2FE theme)
├── droidmount_engine.dart # Core ADB orchestration: discoverDevices,
│                           #   connectWireless, browsePath (stat),
│                           #   streaming downloadFile/uploadFile
├── src/models/            # Immutable data classes
│   ├── adb_device_info.dart
│   ├── android_file_entry.dart
│   └── transfer_stats.dart
├── ui/
│   ├── home_page.dart             # Split-pane desktop layout, device selector
│   └── file_browser_pane.dart     # Directory browser + live transfer telemetry bar
└── services/
    └── macos_permission_service.dart  # FlutterMethodChannel → native permissions
macos/
└── Runner/AppDelegate.swift         # Swift native handler (Accessibility, Screen Recording)
```

### Key Design Decisions

- **ADB commands** use `stat -c '%F|%s|%Y|%n'` for fast, pipe-delimited directory entries.
- File transfers stream through `adb pull` / `adb push` with real-time progress tracking.
- macOS permissions (Accessibility, Screen Recording) are requested via a native `FlutterMethodChannel` (`com.mandoman.openclawdesktop/permissions`) in Swift.

## Quick Start

```bash
flutter pub get
flutter test
flutter run -d macos
```

For full setup, ADB connection guides, and troubleshooting, see the **[Startup Guide](./STARTUP_GUIDE.md)**.

## License

© 2026 MANDO–MAN Software. All rights reserved.
