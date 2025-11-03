
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Aplicación Principal'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Text(
          '¡Dispositivo enrolado correctamente!',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
