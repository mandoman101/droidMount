# DroidMount — Startup Guide

A Flutter desktop app for browsing and downloading files from connected Android devices over USB or Wireless TLS (ADB over TLS).

---

## Prerequisites

- **macOS** (Apple Silicon or Intel)
- **Xcode** & **CocoaPods** installed
- **Flutter SDK** `>=3.0.0` with macOS desktop support enabled:
  ```bash
  flutter config --enable-macos-desktop
  ```
- **Android SDK Platform-Tools** (`adb`) available at one of:
  - `$ANDROID_HOME/platform-tools/adb`
  - `~/Library/Android/sdk/platform-tools/adb`

---

## Connecting Your Android Device

### USB Debugging

1. On your Android device, open **Settings → About phone** and tap **Build number** 7 times to enable **Developer Options**.
2. Go to **Settings → Developer Options → USB debugging** and enable it.
3. Connect the device via USB-C cable.
4. Verify the connection:
   ```bash
   adb devices -l
   ```

### Wireless Debugging (ADB over TLS)

1. On your Android device, enable **Wireless Debugging** in Developer Options (e.g., Samsung Galaxy S24+ `SM-S926U`).
2. Pair the device from your Mac:
   ```bash
   adb pair <ip>:<port>
   ```
3. Connect via IP:port or mDNS serial:
   ```bash
   adb connect <ip>:<port>
   ```

---

## macOS Permissions Setup

On first launch, DroidMount will prompt for or provide in-app buttons for:

- **Accessibility** — `AXIsProcessTrustedWithOptions`
- **Screen Recording** — handled via the `com.mandoman.openclawdesktop/permissions` MethodChannel in `macos/Runner/AppDelegate.swift`

Grant both permissions when prompted, or use the AppBar permission buttons.

---

## Installing Dependencies & Running

```bash
cd droidmount
flutter pub get
dart analyze          # expects 0 issues
flutter test          # 11 unit + widget tests
```

**Debug mode:**
```bash
flutter run -d macos
```

**Production build:**
```bash
flutter build macos --release
```
The app bundle is located at:
`build/macos/Build/Products/Release/droidmount.app`

---

## Using DroidMount

- **Left sidebar** — select a connected USB or Wireless TLS Android device.
- **Right pane (`FileBrowserPane`)** — browse `/sdcard`:
  - Tap folders to drill down.
  - Click the **Up arrow** in the AppBar to go to the parent directory.
  - Click the **Download** icon on any file to pull it to `/tmp/<filename>`.
- **Bottom status bar** — shows real-time download throughput in MB/s.
