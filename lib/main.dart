import 'package:flutter/material.dart';
import 'package:suerte/login.dart';
import 'package:suerte/ranking.dart';
import 'package:suerte/registro.dart';

/// Punto de entrada de la aplicación.
void main() {
  runApp(const Ruleta());
}

/// Widget raíz de la aplicación.
///
/// Configura el [MaterialApp] con el título, la ruta inicial
/// y el mapa de rutas nombradas disponibles.
class Ruleta extends StatelessWidget {
  const Ruleta({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ruleta de la suerte',
      initialRoute: '/registro',
      routes: {
        '/registro': (BuildContext context) => Registro(),
        '/login':    (BuildContext context) => LoginStateful(),
        '/ranking':  (BuildContext context) => Ranking(),
      },
    );
  }
}
