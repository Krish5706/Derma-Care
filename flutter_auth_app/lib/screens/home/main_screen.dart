import 'package:flutter/material.dart';
import 'package:flutter_auth_app/screens/home/skin_prediction_screen.dart';
import 'package:flutter_auth_app/widgets/app_bottom_nav.dart';
import 'home_screen.dart';
import 'history_screen.dart';
import 'skin_tips.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;
  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex.clamp(0, 2);
  }

  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    HistoryScreen(),
    SkinTipsPage(),
  ];

  // Navigation is handled by AppBottomNav via onIndexSelected

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _selectedIndex >= 1 ? _selectedIndex + 1 : _selectedIndex,
        onIndexSelected: (idx) {
          if (idx == 1) {
            // Navigate to Scan screen
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const SkinPredictionScreen()),
            );
          } else {
            setState(() {
              _selectedIndex = idx > 1 ? idx - 1 : idx;
            });
          }
        },
      ),
    );
  }
}
