import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'models.dart';

/// Muestra un diálogo de aviso sencillo con un mensaje y un botón de cierre.
///
/// [context] es el contexto de construcción desde el que se lanza el diálogo.
/// [mensaje] es el texto principal que se mostrará al usuario.
/// [boton] es la etiqueta del botón de confirmación.
/// [s] es un parámetro reservado para uso futuro.
Future<void> dialogAviso(
    BuildContext context, String mensaje, String boton, String s) {
  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        mensaje,
        style: const TextStyle(fontSize: 14),
        textAlign: TextAlign.center,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(boton),
        ),
      ],
    ),
  );
}

/// Muestra un diálogo modal con la tabla de clasificación global.
///
/// El diálogo no se puede cerrar pulsando fuera de él. Muestra el nombre
/// y las monedas de cada usuario en [listRanking], formateadas con separador
/// de miles en formato español.
///
/// [context] es el contexto de construcción.
/// [listRanking] es la lista de usuarios a mostrar, ya ordenada por puntuación.
Future<void> dialogRanking(BuildContext context, List<Usuario> listRanking) {
  // Formateador de números con separador de miles para el locale español.
  final formatter = NumberFormat.decimalPattern('es_ES');

  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => Dialog(
      backgroundColor: Colors.black.withOpacity(0.7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25),
        side: BorderSide(color: Colors.brown.withOpacity(0.7), width: 3),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(50, 25, 50, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Título del diálogo.
            Text(
              'Ranking 🏆',
              style: TextStyle(
                fontFamily: 'Fell',
                fontSize: 30,
                color: Colors.amber[500],
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 15),

            // Lista de jugadores con posición, nombre y monedas.
            ListView.builder(
              shrinkWrap: true,
              itemCount: listRanking.length,
              itemBuilder: (context, index) {
                final usuario = listRanking[index];
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 0),
                  child: Row(
                    children: [
                      // Número de posición.
                      Text(
                        '${index + 1}.',
                        style: TextStyle(
                          fontFamily: 'Fell',
                          color: Colors.amber[300],
                          fontSize: 26,
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Nombre de usuario.
                      Expanded(
                        child: Text(
                          usuario.username,
                          style: TextStyle(
                            fontFamily: 'Fell',
                            color: Colors.amber[300],
                            fontSize: 22,
                          ),
                        ),
                      ),

                      // Monedas formateadas con separador de miles.
                      Text(
                        formatter.format(usuario.monedasGlobales),
                        style: TextStyle(
                          fontFamily: 'Fell',
                          color: Colors.amber[300],
                          fontSize: 26,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            SizedBox(height: 20),

            // Botón de cierre del diálogo.
            SizedBox(
              width: 80,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.black.withOpacity(0.9),
                  foregroundColor: Colors.amber[200],
                  side: BorderSide(
                      color: Colors.brown.withOpacity(0.9), width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 5),
                ),
                child: Text(
                  'OK',
                  style: TextStyle(
                    fontFamily: 'Fell',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
