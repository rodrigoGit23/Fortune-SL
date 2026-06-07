import 'package:flutter/material.dart';
import 'package:suerte/connection.dart';

/// Pantalla de la tienda donde el jugador puede comprar ítems con sus monedas.
///
/// Recibe el saldo actual, el identificador del usuario y un callback
/// que notifica a la pantalla principal cuando se realiza una compra.
class TiendaPage extends StatelessWidget {
  /// Monedas disponibles del jugador en el momento de abrir la tienda.
  final int monedasActuales;

  /// Identificador del usuario en la base de datos.
  final int idUsuario;

  /// Callback invocado tras confirmar una compra.
  ///
  /// Recibe el coste del ítem y su nombre para que la pantalla principal
  /// actualice el marcador y active el efecto del ítem.
  final Function(int, String) onComprar;

  const TiendaPage({
    super.key,
    required this.monedasActuales,
    required this.idUsuario,
    required this.onComprar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Imagen de fondo de la tienda.
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('images/vale.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Barra superior con botón de retroceso y saldo actual.
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Botón para volver a la pantalla anterior.
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new,
                            color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),

                      // Indicador de saldo actual del jugador.
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.amber.withOpacity(0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.monetization_on,
                                color: Colors.amber, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              "$monedasActuales",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Espacio para que los ítems no queden tapados por la imagen.
                const SizedBox(height: 220),

                // Lista de ítems disponibles en la tienda.
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _itemTienda(
                        context,
                        "Pista Extra",
                        "Revela una letra",
                        500,
                        Icons.help,
                      ),
                      _itemTienda(
                        context,
                        "Escudo",
                        "Evita perder el dinero",
                        1000,
                        Icons.shield,
                      ),
                      _itemTienda(
                        context,
                        "Anti-Quiebra",
                        "Te salvas de PERDER TODO",
                        1500,
                        Icons.shield,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Construye la tarjeta visual de un ítem de la tienda.
  ///
  /// Si el jugador no tiene suficiente saldo, el ítem aparece en gris
  /// y no se puede pulsar.
  ///
  /// [titulo] es el nombre del ítem.
  /// [desc] es la descripción breve de su efecto.
  /// [precio] es el coste en monedas.
  /// [icono] es el icono representativo del ítem.
  Widget _itemTienda(
      BuildContext context,
      String titulo,
      String desc,
      int precio,
      IconData icono) {
    bool tieneSaldo = monedasActuales >= precio;

    return Card(
      color: Colors.black.withOpacity(0.6),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        // Solo habilita el tap si el jugador tiene saldo suficiente.
        onTap: tieneSaldo
            ? () => _mostrarConfirmacion(context, titulo, precio)
            : null,
        child: ListTile(
          leading: Icon(
            icono,
            color: tieneSaldo ? Colors.amberAccent : Colors.grey,
          ),
          title: Text(
            titulo,
            style: TextStyle(
              color: tieneSaldo ? Colors.white : Colors.white54,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            desc,
            style: const TextStyle(color: Colors.white60),
          ),
          trailing: Text(
            "$precio",
            style: TextStyle(
              color: tieneSaldo ? Colors.amber : Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  /// Muestra un diálogo de confirmación antes de ejecutar la compra.
  ///
  /// Si el usuario confirma, guarda el ítem en el inventario de la base de datos,
  /// registra el logro de primera compra e invoca el callback [onComprar].
  void _mostrarConfirmacion(
      BuildContext context, String item, int precio) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text(
          "Comprar $item",
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          "¿Quieres gastar $precio monedas en $item?",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          // Botón para cancelar la compra.
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancelar",
              style: TextStyle(color: Colors.white70),
            ),
          ),

          // Botón para confirmar la compra.
          ElevatedButton(
            onPressed: monedasActuales >= precio
                ? () async {
                    try {
                      ConexionDB db = ConexionDB();
                      // Guardar el ítem comprado en el inventario del usuario.
                      await db.agregarAlInventario(idUsuario, item, 1);
                      // Registrar el logro de primera compra si no existe aún.
                      await db.registrarLogro(
                        idUsuario,
                        'comprador',
                        'Realizaste tu primera compra en la tienda',
                      );
                    } catch (e) {
                      print("Error al guardar inventario: $e");
                    }

                    // Notificar a la pantalla principal para actualizar estado.
                    onComprar(precio, item);
                    Navigator.pop(context);
                    Navigator.pop(context);
                  }
                : null,
            child: Text(
              monedasActuales >= precio
                  ? "Comprar"
                  : "Saldo Insuficiente",
            ),
          ),
        ],
      ),
    );
  }
}
