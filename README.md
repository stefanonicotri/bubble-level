# Bubble Level

A minimalist digital bubble level application built with Flutter.

## Features

* **Real-Time Orientation:** Uses the device's built-in accelerometer to provide highly accurate bubble level readings.
* **Custom Level UI:** A reactive UI featuring flat, portrait, and landscape modes that smoothly adjust against a fixed center marker.
* **Sensor Calibration:** Manual calibration override so users know exactly when their device requires physical calibration (the "Calibrate Flat" button).
* **Dynamic Dark/Light Mode:** Seamlessly inherits the system's default theme on launch, with a manual override toggle in the app bar.
* **Native Localization:** The Android app name dynamically changes based on the system language (e.g., "Bubble Level" in English, "Livella" in Italian).
* **Optimized App Icon:** Fully configured adaptive Android launcher icons using the `flutter_launcher_icons` package.

## Getting Started

To run this project locally, you will need the [Flutter SDK](https://flutter.dev/docs/get-started/install) installed on your machine.

1. **Clone the repository:**
   ```bash
   git clone [https://github.com/stefanonicotri/bubble-level.git](https://github.com/stefanonicotri/bubble-level.git)
   ```
2. **Navigate to the directory:**
   ```bash
   cd my_compass
   ```
3. **Install dependencies:**
   ```bash
   flutter clean && flutter pub get
   ```
4. **Compile the app:**
   ```bash
   flutter build apk --split-per-abi --obfuscate --split-debug-info=debug_info
   ```
*Note: This app relies on a physical accelerometer. Testing on a computer emulator will result in missing sensor data.*

## Built With
* [Flutter](https://flutter.dev/) - UI Toolkit
* [Dart](https://dart.dev/) - Programming Language
* [sensors_plus](https://pub.dev/packages/sensors_plus) - Hardware Sensor Package

## Author

**Stefano Nicotri**

* **GitHub:** [@stefanonicotri](https://github.com/stefanonicotri)

*(Feel free to reach out with questions, discussions on differential geometry, or contributions to this educational tool!)*

## License

This project is licensed under the GNU General Public License v3.0 (GPL-3.0) - see the [LICENSE](LICENSE) file for details.
