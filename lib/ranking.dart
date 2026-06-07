import 'package:flutter/material.dart';
import 'package:suerte/connection.dart';
import 'package:suerte/models.dart';

/// Pantalla que muestra la tabla de clasificación global de jugadores.
///
/// Carga los datos desde la base de datos de forma asíncrona y los presenta
/// sobre una imagen de fondo temática.
// ignore: use_key_in_widget_constructors
class Ranking extends StatefulWidget {
  @override
  // ignore: library_private_types_in_public_api
  _RankingState createState() => _RankingState();
}

/// Estado asociado a [Ranking].
class _RankingState extends State<Ranking> {
  /// Instancia de acceso a la base de datos.
  final ConexionDB conexion = ConexionDB();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Imagen de fondo del ranking.
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('images/ranking.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Espacio superior para que las filas queden dentro del marco visual.
                const SizedBox(height: 160),

                // Lista de jugadores cargada asíncronamente.
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 35),
                    child: FutureBuilder<List<Usuario>>(
                      future: conexion.obtenerRanking(),
                      builder: (context, snapshot) {
                        // Estado de carga.
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                                color: Colors.amber),
                          );
                        }

                        // Error al obtener los datos.
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              "Error: ${snapshot.error}",
                              style:
                                  const TextStyle(color: Colors.white),
                            ),
                          );
                        }

                        // Sin datos disponibles.
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(
                            child: Text(
                              "No hay datos",
                              style: TextStyle(color: Colors.white),
                            ),
                          );
                        }

                        final listaUsuarios = snapshot.data!;

                        return ListView.builder(
                          padding: const EdgeInsets.only(
                              top: 10, bottom: 20),
                          itemCount: listaUsuarios.length,
                          itemBuilder: (context, index) {
                            final user = listaUsuarios[index];
                            return _disenhoFilaRanking(
                              index + 1,
                              user.username,
                              user.monedasGlobales,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),

                // Botón para volver a la pantalla de login.
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: IconButton(
                    icon: const Icon(Icons.home,
                        color: Colors.amber, size: 40),
                    onPressed: () => Navigator.of(context)
                        .pushNamedAndRemoveUntil(
                            '/login', (route) => false),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Construye una fila del ranking con posición, nombre y puntuación.
  ///
  /// Los tres primeros puestos reciben colores diferenciados:
  /// oro (1.º), plata (2.º) y bronce (3.º). El resto usa blanco semitransparente.
  ///
  /// [posicion] es el número de puesto (empezando en 1).
  /// [nombre] es el nombre de usuario del jugador.
  /// [puntos] es el total de monedas acumuladas.
  Widget _disenhoFilaRanking(int posicion, String nombre, int puntos) {
    Color colorPosicion;
    if (posicion == 1) {
      colorPosicion = Colors.amber;
    } else if (posicion == 2) {
      colorPosicion = Colors.grey.shade300;
    } else if (posicion == 3) {
      colorPosicion = Colors.brown.shade300;
    } else {
      colorPosicion = Colors.white70;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          // Número de posición con color según el puesto.
          Text(
            "$posicion. ",
            style: TextStyle(
              color: colorPosicion,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),

          // Nombre de usuario en mayúsculas.
          Expanded(
            child: Text(
              nombre.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.1,
              ),
            ),
          ),

          // Puntuación con el color del puesto.
          Text(
            "$puntos €",
            style: TextStyle(
              color: colorPosicion,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
