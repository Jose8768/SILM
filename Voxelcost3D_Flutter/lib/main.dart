import 'package:flutter/material.dart';
import 'screens.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VoxelcostApp());
}

class VoxelcostApp extends StatefulWidget {
  const VoxelcostApp({super.key});

  @override
  State<VoxelcostApp> createState() => _VoxelcostAppState();
}

class _VoxelcostAppState extends State<VoxelcostApp> {
  bool _authenticated = false;
  bool _isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Voxelcost3D',
      theme: voxelTheme(),
      home: _authenticated
          ? HomeScreen(
              isDarkMode: _isDarkMode,
              onThemeModeChanged: (isDarkMode) {
                setState(() => _isDarkMode = isDarkMode);
                setVoxelDarkMode(isDarkMode);
              },
              onLogout: () => setState(() => _authenticated = false),
            )
          : LoginScreen(
              onLoginSuccess: () => setState(() => _authenticated = true)),
    );
  }
}
