import 'dart:async';
import 'dart:io'; // Required to check the system language
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required to lock screen orientation
import 'package:sensors_plus/sensors_plus.dart';

void main() {
  // Lock the app to portrait mode so the physical axes never swap relative to the screen
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]).then((_) {
    runApp(const BubbleLevelApp());
  });
}

class BubbleLevelApp extends StatefulWidget {
  const BubbleLevelApp({super.key});

  @override
  State<BubbleLevelApp> createState() => _BubbleLevelAppState();
}

class _BubbleLevelAppState extends State<BubbleLevelApp> {
  // ThemeMode.system automatically matches the user's iOS/Android system settings
  ThemeMode _themeMode = ThemeMode.system;

  // This function allows child screens to change the theme
  void changeTheme(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Check if the system language starts with 'it' (Italian)
    String currentLanguage = Platform.localeName;
    String appTitle = currentLanguage.startsWith('it') ? 'Livella' : 'Bubble Level';

    return MaterialApp(
      title: appTitle, // Dynamic title for the Android task switcher
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: _themeMode,
      home: LevelScreen(onThemeChanged: changeTheme),
    );
  }
}

class LevelScreen extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged;
  const LevelScreen({super.key, required this.onThemeChanged});

  @override
  State<LevelScreen> createState() => _LevelScreenState();
}

class _LevelScreenState extends State<LevelScreen> {
  // Smoothed sensor data
  double x = 0.0;
  double y = 0.0;
  double z = 0.0;

  // Calibration offsets (to handle camera bumps or uneven cases)
  double offsetX = 0.0;
  double offsetY = 0.0;
  double offsetZ = 0.0;

  // Tuned to 0.8 for instant, fluid hardware response without the jitter
  final double alpha = 0.8; 

  // Stream subscription for the memory leak fix
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;

  @override
  void initState() {
    super.initState();
    // Start listening to the hardware and save the connection
    _accelerometerSubscription = accelerometerEventStream().listen((AccelerometerEvent event) {
      setState(() {
        // Apply the Low-Pass Filter: blends new data with old data for fluidity
        x = x + alpha * (event.x - x);
        y = y + alpha * (event.y - y);
        z = z + alpha * (event.z - z);
      });
    });
  }

  @override
  void dispose() {
    // CRITICAL: Cancel the hardware stream when the app is closed or minimized
    _accelerometerSubscription?.cancel();
    super.dispose();
  }

  // Captures the current tilt and sets it as the new "zero" point
  void calibrateLevel() {
    setState(() {
      offsetX = x;
      offsetY = y;
      offsetZ = z - 9.8; 
    });
  }

  // Reset calibration back to factory defaults
  void resetCalibration() {
    setState(() {
      offsetX = 0.0;
      offsetY = 0.0;
      offsetZ = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Check language for the visible AppBar
    String currentLanguage = Platform.localeName;
    String appTitle = currentLanguage.startsWith('it') ? 'Livella' : 'Bubble Level';

    // Apply the calibration offsets to the smoothed data
    double calX = x - offsetX;
    double calY = y - offsetY;
    double calZ = z - offsetZ;

    // Determine the Dominant Axis to switch UI modes
    double absX = calX.abs();
    double absY = calY.abs();
    double absZ = calZ.abs();

    // THE GOLDEN MATH RULE:
    // Flutter's X matches standard math (Right is +1.0)
    // Flutter's Y is inverted (Bottom is +1.0, Top is -1.0)
    // Therefore, we only invert the Y-axis to simulate proper buoyancy.
    double alignX = (calX / 9.8).clamp(-1.0, 1.0);
    double alignY = -(calY / 9.8).clamp(-1.0, 1.0); 

    Widget currentLevelUI;

    if (absZ > absX && absZ > absY) {
      // FLAT MODE (Bullseye)
      bool isPerfect = absX < 0.5 && absY < 0.5;
      currentLevelUI = buildBullseyeLevel(alignX, alignY, isPerfect, isDarkMode);
    } else if (absY > absX && absY > absZ) {
      // PORTRAIT MODE
      bool isPerfect = absX < 0.5;
      // Y is locked to 0 (center), movement controlled strictly by X
      currentLevelUI = buildTubularLevel(alignX, 0, isPerfect, false, isDarkMode);
    } else {
      // LANDSCAPE MODE
      bool isPerfect = absY < 0.5;
      // X is locked to 0 (center), movement controlled strictly by Y
      currentLevelUI = buildTubularLevel(0, alignY, isPerfect, true, isDarkMode);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(appTitle),
        centerTitle: true,
        actions: [
          Row(
            children: [
              Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode),
              Switch(
                value: isDarkMode,
                onChanged: (bool value) {
                  widget.onThemeChanged(value ? ThemeMode.dark : ThemeMode.light);
                },
              ),
            ],
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // The dynamic level UI takes up exactly 300x300 space so the UI doesn't jump
            SizedBox(
              width: 300,
              height: 300,
              child: Center(child: currentLevelUI),
            ),
            
            const SizedBox(height: 60),

            // Calibration Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: calibrateLevel,
                  icon: const Icon(Icons.settings_overscan),
                  label: const Text('Calibrate Flat'),
                ),
                const SizedBox(width: 10),
                TextButton(
                  onPressed: resetCalibration,
                  child: const Text('Reset'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- THE 2D BULLSEYE LEVEL (For Flat Surfaces) ---
  Widget buildBullseyeLevel(double alignX, double alignY, bool isPerfect, bool isDarkMode) {
    return Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: isDarkMode ? Colors.white54 : Colors.black54, width: 3),
        color: isPerfect ? Colors.green.withOpacity(0.4) : (isDarkMode ? Colors.black12 : Colors.grey.shade200),
      ),
      child: Stack(
        children: [
          Center(child: Icon(Icons.add, color: isDarkMode ? Colors.white30 : Colors.black26, size: 60)),
          Align(
            alignment: Alignment(alignX, alignY),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle, 
                color: Colors.greenAccent.shade400,
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(2, 2))
                ]
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- THE 1D TUBULAR LEVEL (For Upright/Sideways Edges) ---
  Widget buildTubularLevel(double alignX, double alignY, bool isPerfect, bool isVertical, bool isDarkMode) {
    return Container(
      width: isVertical ? 80 : 300,
      height: isVertical ? 300 : 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: isDarkMode ? Colors.white54 : Colors.black54, width: 3),
        color: isPerfect ? Colors.green.withOpacity(0.4) : (isDarkMode ? Colors.black12 : Colors.grey.shade200),
      ),
      child: Stack(
        children: [
          Center(
            child: Container(
              width: isVertical ? 80 : 40,
              height: isVertical ? 40 : 80,
              decoration: BoxDecoration(
                border: isVertical
                    ? Border(
                        top: BorderSide(color: isDarkMode ? Colors.white30 : Colors.black26, width: 2),
                        bottom: BorderSide(color: isDarkMode ? Colors.white30 : Colors.black26, width: 2))
                    : Border(
                        left: BorderSide(color: isDarkMode ? Colors.white30 : Colors.black26, width: 2),
                        right: BorderSide(color: isDarkMode ? Colors.white30 : Colors.black26, width: 2)),
              ),
            ),
          ),
          Align(
            alignment: Alignment(alignX, alignY),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle, 
                color: Colors.greenAccent.shade400,
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(2, 2))
                ]
              ),
            ),
          ),
        ],
      ),
    );
  }
}
