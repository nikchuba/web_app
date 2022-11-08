import 'package:flutter/material.dart';
import 'package:web_app/presentation/screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TruckLoader());
}

class TruckLoader extends StatelessWidget {
  const TruckLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Truck Loader',
      home: HomeScreen(),
    );
  }
}
