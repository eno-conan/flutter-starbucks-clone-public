// lib/screens/splash/splash_screen.dart
import 'package:flutter/material.dart';
import '../../constants/my_colors.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  static const routeName = '/splash';

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator(color: MyColors.greenButton)),
    );
  }
}
