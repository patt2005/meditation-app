import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:meditation_app/utilities/appcolors.dart';
import 'package:meditation_app/screens/home_screen.dart';
import 'package:meditation_app/providers/app_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _loadDataAndNavigate();
  }
  
  Future<void> _loadDataAndNavigate() async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    await appProvider.loadAllData();
    
    await Future.delayed(const Duration(seconds: 3));
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.gradientStart,
              AppColors.gradientEnd,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.self_improvement,
                size: 100,
                color: AppColors.white,
              ),
              const SizedBox(height: 24),
              Text(
                'Meditation App',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                  fontFamily: 'Montserrat',
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Find your inner peace',
                style: TextStyle(
                  fontSize: 18,
                  color: AppColors.white.withValues(alpha: 0.8),
                  fontFamily: 'Montserrat',
                ),
              ),
              const SizedBox(height: 48),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}