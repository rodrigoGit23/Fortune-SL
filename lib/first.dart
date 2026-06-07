import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:suerte/connection.dart';
import 'package:suerte/models.dart';
import 'dart:async';
import 'dart:math';
import 'package:suerte/tienda_page.dart';

/// Pantalla principal del juego: contiene la ruleta y el teclado de letras.
///
/// Gestiona la lógica completa de una partida: girar la ruleta, adivinar letras,
/// controlar el marcador, usar ítems y avanzar de nivel.
class Principal extends StatefulWidget {
  /// Usuario autenticado que está jugando la partida.
  final Usuario usuario;

  const Principal({super.key, required this.usuario});

  @override
  // ignore: library_private_types_in_public_api
  _PrincipalState createState() => _PrincipalState();
}

/// Estado asociado a [Principal].
class _PrincipalState extends State<Principal> {
  /// Stream que controla qué sector selecciona la ruleta.
  StreamController<int> selected = StreamController<int>.broadcast();

  /// Monedas acumuladas durante la partida actual.
  int marcador = 0;

  /// Valor monetario obtenido en el último giro de la ruleta.
  int valorGiroActual = 0;

  /// Índice de la palabra/frase actual dentro de [palabras].
  int nivelActual = 0;

  /// Indica si se debe mostrar el teclado de letras en lugar de la ruleta.
  bool mostrarTeclado = false;

  /// Letras que el jugador ya ha pulsado en este nivel.
  List<String> letrasAdivinadas = [];

  /// Índice del sector ganador de la última tirada de la ruleta.
  int indiceGanador = 0;

  /// Indica si el jugador tiene activo el ítem Escudo.
  bool tieneEscudo = false;

  /// Número de pistas disponibles compradas en la tienda.
  int pistasDisponibles = 0;

  /// Cantidad apostada cuando la ruleta cae en la casilla APUESTA.
  int apuestaPendiente = 0;

  /// Indica que el siguiente intento de letra resuelve una apuesta activa.
  bool esperandoLetraApuesta = false;

  /// Indica si el jugador tiene activo el ítem Anti-Quiebra.
  bool tieneAntiQuiebra = false;

  /// Valor actual del slider en el diálogo de apuesta.
  double apuestaSlider = 0;

  /// Identificador de la partida activa en la base de datos.
  int? _idPartidaActual;

  // ================================================================
  // INICIALIZACIÓN Y LIMPIEZA
  // ================================================================

  @override
  void initState() {
    super.initState();
    _iniciarPartidaBD();
  }

  /// Crea un registro de partida en la base de datos y registra el logro
  /// de primera partida si es la primera vez que el usuario juega.
  Future<void> _iniciarPartidaBD() async {
    try {
      ConexionDB db = ConexionDB();
      int? id = await db.iniciarPartida(widget.usuario.id);
      if (id != null) {
        _idPartidaActual = id;
        await db.registrarLogro(
          widget.usuario.id,
          'primera_partida',
          '¡Jugaste tu primera partida!',
        );
      }
    } catch (e) {
      print("Error al iniciar partida en BD: $e");
    }
  }

  /// Registra un movimiento de la partida activa en la base de datos.
  ///
  /// No hace nada si la partida aún no tiene ID asignado.
  Future<void> _guardarMovimiento(String accion, int valor) async {
    if (_idPartidaActual == null) return;
    try {
      ConexionDB db = ConexionDB();
      await db.registrarMovimiento(_idPartidaActual!, accion, valor);
    } catch (e) {
      print("Error al guardar movimiento: $e");
    }
  }

  @override
  void dispose() {
    selected.close();
    super.dispose();
  }

  // ================================================================
  // LÓGICA DE LA RULETA
  // ================================================================

  /// Procesa el resultado textual devuelto por la ruleta y actualiza el estado.
  ///
  /// Las casillas especiales ('PIERDES TODO', 'AZAR', 'APUESTA') activan su
  /// lógica correspondiente. El resto de casillas son valores monetarios que
  /// habilitan el teclado para adivinar una letra.
  void _procesarResultadoRuleta(String resultado) {
    String resLimpio = resultado.trim().toUpperCase();

    setState(() {
      switch (resLimpio) {
        case 'PIERDES TODO':
          // Anti-Quiebra absorbe el golpe sin consecuencias.
          if (tieneAntiQuiebra) {
            tieneAntiQuiebra = false;
            _guardarMovimiento('anti_quiebra_activado', 0);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("¡Anti-Quiebra activado!"),
              backgroundColor: Colors.green,
            ));
          // El Escudo bloquea la pérdida y se consume.
          } else if (tieneEscudo) {
            tieneEscudo = false;
            _guardarMovimiento('escudo_activado', 0);
            ConexionDB().registrarLogro(
              widget.usuario.id,
              'superviviente',
              'El escudo te salvó de perderlo todo',
            );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("¡El escudo te protegió!")),
            );
          } else {
            if (marcador <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text("Ya tienes 0€"),
                backgroundColor: Colors.green,
              ));
            } else {
              _guardarMovimiento('pierdes_todo', marcador);
              marcador = 0;
              _mostrarAvisoPerdidaTotal();
            }
          }
          break;

        case 'AZAR':
          // Se requiere al menos 100 € para activar la casilla AZAR.
          if (marcador < 100) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("Necesitas al menos 100€ para esta opción"),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ));
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                indiceGanador = Random().nextInt(premios.length);
                selected.add(indiceGanador);
              }
            });
          } else {
            // Calcular una cantidad aleatoria entre el 50% y el 150% del marcador.
            int oferta =
                (marcador * (0.5 + Random().nextDouble())).toInt();
            _mostrarDialogoAzar(oferta);
          }
          break;

        case 'APUESTA':
          _iniciarApuesta();
          break;

        default:
          // Casilla con valor monetario: habilitar el teclado.
          try {
            valorGiroActual =
                int.parse(resLimpio.replaceAll('€', ''));
            mostrarTeclado = true;
            _guardarMovimiento('giro_ruleta', valorGiroActual);
          } catch (e) {
            print("Error al procesar resultado: $e");
          }
          break;
      }
    });
  }

  // ================================================================
  // DIÁLOGOS DE CASILLAS ESPECIALES
  // ================================================================

  /// Muestra el diálogo de la casilla AZAR con el resultado aleatorio.
  ///
  /// [nuevaCantidad] es el nuevo marcador que tendrá el jugador si acepta.
  void _mostrarDialogoAzar(int nuevaCantidad) {
    int diferencia = nuevaCantidad - marcador;
    bool esVictoria = diferencia >= 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: esVictoria
                  ? [Colors.green.shade700, Colors.green.shade400]
                  : [Colors.red.shade900, Colors.red.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                esVictoria ? Icons.star : Icons.bolt,
                color: Colors.white,
                size: 50,
              ),
              const SizedBox(height: 15),
              Text(
                esVictoria
                    ? "¡EL DESTINO TE SONRÍE!"
                    : "¡GOLPE DURO DEL DESTINO!",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                esVictoria
                    ? "¡Qué suerte! El destino te ha regalado ${diferencia}€"
                    : "¡Qué mala suerte! El destino te ha quitado ${diferencia.abs()}€",
                textAlign: TextAlign.center,
                style:
                    const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white),
                onPressed: () {
                  setState(() {
                    marcador = nuevaCantidad;
                  });
                  _guardarMovimiento('azar', diferencia);
                  Navigator.pop(context);
                },
                child: Text(
                  "Aceptar",
                  style: TextStyle(
                    color: esVictoria ? Colors.orange : Colors.indigo,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Muestra el diálogo de apuesta con un slider para elegir la cantidad.
  ///
  /// El jugador elige cuánto apostar dentro del rango permitido. Si acierta
  /// la siguiente letra, gana el triple de lo apostado; si falla, lo pierde.
  void _iniciarApuesta() {
    if (marcador <= 0) {
      _mostrarNotificacionEstiloAzar(
        titulo: "SIN FONDOS",
        mensaje: "No tienes monedas para apostar.\n",
        esVictoria: false,
      );
      return;
    }

    final random = Random();
    // Apuesta sugerida: entre el 10% y el 50% del marcador.
    double fraccion = 0.10 + random.nextDouble() * 0.40;
    double sugerida = (marcador * fraccion).roundToDouble();

    // La apuesta mínima obligatoria es el 20% del marcador.
    double minApuesta = (marcador * 0.20).roundToDouble();
    if (minApuesta < 1) minApuesta = 1;
    if (sugerida < minApuesta) sugerida = minApuesta;

    apuestaSlider = sugerida;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.3),
                  blurRadius: 20,
                )
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🎰', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 8),
                const Text(
                  '¡MOMENTO DE APOSTAR!',
                  style: TextStyle(
                    color: Colors.amber,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // Resumen visual de la apuesta actual.
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text('Tu apuesta:',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 13)),
                      Text(
                        '${apuestaSlider.toStringAsFixed(0)}€',
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '✅ Si aciertas una letra en el primer intento: '
                        '+${(apuestaSlider * 2).toStringAsFixed(0)}€',
                        style: const TextStyle(
                            color: Colors.greenAccent, fontSize: 12),
                      ),
                      Text(
                        '❌ Si fallas: -${apuestaSlider.toStringAsFixed(0)}€'
                        '  (mín. ${minApuesta.toStringAsFixed(0)}€)',
                        style: const TextStyle(
                            color: Colors.redAccent, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Ajusta tu apuesta:',
                    style:
                        TextStyle(color: Colors.white70, fontSize: 13)),
                Slider(
                  value: apuestaSlider,
                  min: minApuesta,
                  max: marcador.toDouble(),
                  divisions: (marcador - minApuesta.toInt()).clamp(1, 200),
                  activeColor: Colors.amber,
                  inactiveColor: Colors.white24,
                  label: '${apuestaSlider.toStringAsFixed(0)}€',
                  onChanged: (val) {
                    setDialogState(
                        () => apuestaSlider = val.roundToDouble());
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Botón para cancelar sin apostar.
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: TextButton.styleFrom(
                          side: const BorderSide(color: Colors.white30),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Cancelar',
                            style: TextStyle(color: Colors.white54)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Botón para confirmar la apuesta y abrir el teclado.
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          setState(() {
                            apuestaPendiente = apuestaSlider.toInt();
                            esperandoLetraApuesta = true;
                            mostrarTeclado = true;
                          });
                          _guardarMovimiento(
                              'apuesta_iniciada', apuestaPendiente);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          '¡APOSTAR!',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================================================================
  // LÓGICA DEL TECLADO
  // ================================================================

  /// Procesa la letra pulsada por el jugador.
  ///
  /// Si hay una apuesta activa, resuelve la apuesta según si la letra
  /// está o no en la frase. En caso contrario, suma monedas por cada
  /// aparición de la letra o aplica la penalización por fallo.
  void comprobarLetra(String letraOriginal) {
    String letra = letraOriginal.toUpperCase();
    String frase = palabras[nivelActual]['frase']!.toUpperCase();

    setState(() {
      letrasAdivinadas.add(letra);

      if (esperandoLetraApuesta) {
        // Resolución de apuesta activa.
        if (frase.contains(letra)) {
          marcador += (apuestaPendiente * 3);
          _guardarMovimiento('apuesta_ganada', apuestaPendiente * 3);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("¡Ganaste la apuesta!"),
            backgroundColor: Colors.green,
          ));
        } else {
          int perdido = apuestaPendiente;
          marcador = (marcador - apuestaPendiente < 0)
              ? 0
              : (marcador - apuestaPendiente);
          _guardarMovimiento('apuesta_perdida', perdido);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Perdiste la apuesta"),
            backgroundColor: Colors.red,
          ));
        }
        esperandoLetraApuesta = false;
        apuestaPendiente = 0;
        mostrarTeclado = false;
      } else {
        // Resolución de turno normal.
        if (frase.contains(letra)) {
          int apariciones = letra.allMatches(frase).length;
          int ganado = valorGiroActual * apariciones;
          marcador += ganado;
          _guardarMovimiento('letra_correcta', ganado);

          // Comprobar si todas las letras de la frase ya han sido adivinadas.
          bool fraseCompleta = frase
              .replaceAll(' ', '')
              .split('')
              .every((l) => letrasAdivinadas.contains(l));
          if (fraseCompleta) {
            _mostrarAvisoVictoria(frase);
          }
        } else {
          // Letra incorrecta: el Escudo absorbe la penalización si está activo.
          if (tieneEscudo) {
            tieneEscudo = false;
            _guardarMovimiento('escudo_activado', 0);
            ConexionDB().registrarLogro(
              widget.usuario.id,
              'superviviente',
              'El escudo te salvó de una penalización',
            );
          } else {
            // Sin escudo: se pierde la mitad del marcador actual.
            int penalizacion = marcador ~/ 2;
            marcador = (marcador - penalizacion < 0)
                ? 0
                : (marcador - penalizacion);
            _guardarMovimiento('letra_incorrecta', penalizacion);
            mostrarTeclado = false;
            valorGiroActual = 0;
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("Fallaste!"),
              backgroundColor: Colors.red,
            ));
          }
        }
      }
    });
  }

  // ================================================================
  // DIÁLOGOS DE RESULTADO
  // ================================================================

  /// Muestra una notificación visual de estilo similar al diálogo de AZAR.
  ///
  /// Se usa para informar al jugador de situaciones sin fondos o mensajes
  /// que requieren una presentación destacada.
  void _mostrarNotificacionEstiloAzar({
    required String titulo,
    required String mensaje,
    required bool esVictoria,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: esVictoria
                  ? [Colors.green.shade700, Colors.green.shade400]
                  : [Colors.red.shade900, Colors.red.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                esVictoria ? Icons.casino : Icons.money_off,
                color: Colors.white,
                size: 50,
              ),
              const SizedBox(height: 15),
              Text(
                titulo,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              Text(
                mensaje,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white),
                onPressed: () {
                  Navigator.pop(ctx);
                  if (!esVictoria) return;
                  setState(() {
                    mostrarTeclado = true;
                  });
                },
                child: Text(
                  "Aceptar",
                  style: TextStyle(
                    color: esVictoria ? Colors.orange : Colors.indigo,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Muestra el diálogo informando de que el marcador ha llegado a cero.
  void _mostrarAvisoPerdidaTotal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.red, width: 3),
        ),
        title: const Text(
          "¡TRAGEDIA!",
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Colors.red,
              fontSize: 30,
              fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Has caído en la casilla 'PIERDES TODO'.\n\nTu marcador ha vuelto a cero.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context),
              child: const Text("Aceptar",
                  style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  /// Muestra el diálogo de victoria al completar la frase de un nivel.
  ///
  /// Registra el logro de frase resuelta e invoca [_proximoNivel].
  void _mostrarAvisoVictoria(String frase) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF1A1A2E),
                Color(0xFF16213E),
                Color(0xFF0F3460),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
                color: Colors.amber.withOpacity(0.6), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withOpacity(0.3),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Estrellas decorativas.
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.star, color: Colors.amber, size: 20),
                  SizedBox(width: 6),
                  Icon(Icons.star, color: Colors.amber, size: 28),
                  SizedBox(width: 6),
                  Icon(Icons.star, color: Colors.amber, size: 20),
                ],
              ),
              const SizedBox(height: 12),

              // Icono de trofeo con degradado radial.
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.amber.shade300,
                      Colors.orange.shade700,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.6),
                      blurRadius: 20,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: const Icon(Icons.emoji_events,
                    color: Colors.white, size: 55),
              ),
              const SizedBox(height: 16),

              // Título con degradado de colores.
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Colors.amber, Colors.yellow, Colors.orange],
                ).createShader(bounds),
                child: const Text(
                  "¡ENHORABUENA!",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "¡Frase resuelta!",
                style: TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                    letterSpacing: 1.5),
              ),
              const SizedBox(height: 14),

              // Cuadro con la frase que el jugador acaba de completar.
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.amber.withOpacity(0.3)),
                ),
                child: Text(
                  '"$frase"',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Indicador de puntuación acumulada.
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.amber.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.monetization_on,
                        color: Colors.amber, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      "$marcador €",
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // Botón para pasar al siguiente nivel.
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    shadowColor: Colors.amber,
                    elevation: 8,
                  ),
                  onPressed: () {
                    Navigator.pop(c);
                    ConexionDB().registrarLogro(
                      widget.usuario.id,
                      'frase_resuelta',
                      'Resolviste la frase: $frase',
                    );
                    _proximoNivel();
                  },
                  child: const Text(
                    "SIGUIENTE NIVEL  →",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 1.5,
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

  // ================================================================
  // LÓGICA DE NIVELES
  // ================================================================

  /// Avanza al siguiente nivel o finaliza la partida si ya se completaron todos.
  ///
  /// Al finalizar guarda las monedas en el perfil del usuario, comprueba
  /// el logro de millonario y muestra el diálogo de partida completada.
  void _proximoNivel() async {
    if (nivelActual < palabras.length - 1) {
      // Hay más niveles: avanzar y reiniciar el estado del nivel.
      setState(() {
        nivelActual++;
        letrasAdivinadas.clear();
        mostrarTeclado = false;
        valorGiroActual = 0;
      });
    } else {
      // Último nivel completado: guardar resultados en la base de datos.
      try {
        ConexionDB db = ConexionDB();
        if (_idPartidaActual != null) {
          await db.finalizarPartida(_idPartidaActual!, marcador);
        }
        await db.sumarMonedas(widget.usuario.id, marcador);

        // Comprobar el logro de millonario.
        int totalMonedas = widget.usuario.monedasGlobales + marcador;
        if (totalMonedas >= 1000) {
          await db.registrarLogro(
            widget.usuario.id,
            'millonario',
            '¡Superaste las 1000 monedas globales!',
          );
        }
      } catch (e) {
        print("Error al finalizar partida: $e");
      }

      if (!mounted) return;

      // Mostrar diálogo de partida completada con acceso directo al ranking.
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF1A1A2E),
                  Color(0xFF16213E),
                  Color(0xFF0F3460),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                  color: Colors.amber.withOpacity(0.6), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.star, color: Colors.amber, size: 20),
                    SizedBox(width: 6),
                    Icon(Icons.star, color: Colors.amber, size: 28),
                    SizedBox(width: 6),
                    Icon(Icons.star, color: Colors.amber, size: 20),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.amber.shade300,
                        Colors.orange.shade700,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.6),
                        blurRadius: 20,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.emoji_events,
                      color: Colors.white, size: 55),
                ),
                const SizedBox(height: 16),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Colors.amber, Colors.yellow, Colors.orange],
                  ).createShader(bounds),
                  child: const Text(
                    "¡PARTIDA COMPLETADA!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Monedas totales obtenidas en la partida.
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.amber.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.monetization_on,
                          color: Colors.amber, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        "$marcador monedas",
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Botón para navegar al ranking.
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.leaderboard,
                        color: Colors.black),
                    label: const Text(
                      "VER RANKING",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 1.5,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      shadowColor: Colors.amber,
                      elevation: 8,
                    ),
                    onPressed: () {
                      Navigator.pop(c);
                      Navigator.pushReplacementNamed(context, '/ranking');
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  // ================================================================
  // HELPERS DE ESTADO
  // ================================================================

  /// Devuelve cuántas letras únicas de la frase actual ya han sido acertadas.
  int _obtenerLetrasAcertadasContador() {
    String frase = palabras[nivelActual]['frase']!
        .toUpperCase()
        .replaceAll(' ', '');
    return frase
        .split('')
        .where((l) => letrasAdivinadas.contains(l))
        .length;
  }

  /// Devuelve el total de letras únicas (sin espacios) de la frase actual.
  int _obtenerLetrasTotalesContador() {
    return palabras[nivelActual]['frase']!.replaceAll(' ', '').length;
  }

  /// Devuelve la ruta de la imagen de silueta según la categoría del nivel actual.
  String _obtenerSiluetaCategoria() {
    String pista = palabras[nivelActual]['pista']!.toUpperCase();
    if (pista.contains('PELÍCULA')) return 'images/silueta_pelicula.png';
    if (pista.contains('COMIDA'))   return 'images/silueta_comida.png';
    if (pista.contains('CIUDAD'))   return 'images/silueta_ciudad.png';
    if (pista.contains('DEPORTE'))  return 'images/deporte.png';
    if (pista.contains('ANIMAL'))   return 'images/animal.png';
    return 'images/silueta_generica.png';
  }

  // ================================================================
  // DATOS DEL JUEGO
  // ================================================================

  /// Colores asignados a los sectores de la ruleta, en orden de aparición.
  final List<Color> coloresRuleta = [
    Colors.redAccent,
    Colors.purpleAccent,
    Colors.blueAccent,
    Colors.greenAccent,
    Colors.orangeAccent,
    Colors.pinkAccent,
    Colors.tealAccent,
    Colors.amberAccent,
  ];

  /// Lista de niveles del juego. Cada elemento contiene la pista (categoría)
  /// y la frase que el jugador debe adivinar letra a letra.
  final List<Map<String, String>> palabras = [
    {'pista': 'CIUDAD',   'frase': 'PARIS'},
    {'pista': 'PELÍCULA', 'frase': 'TITANIC'},
    {'pista': 'ANIMAL',   'frase': 'ELEFANTE'},
    {'pista': 'COMIDA',   'frase': 'PIZZA'},
    {'pista': 'DEPORTE',  'frase': 'FUTBOL'},
  ];

  /// Premios disponibles en la ruleta. Pueden ser cantidades monetarias
  /// o casillas especiales ('PIERDES TODO', 'AZAR', 'APUESTA').
  final List<String> premios = [
    '300€', '400€', '500€', 'PIERDES TODO',
    '600€', 'APUESTA', 'AZAR', '200€',
  ];

  // ================================================================
  // BUILD PRINCIPAL
  // ================================================================

  /// Construye la pantalla principal, alternando entre la vista de ruleta
  /// y la vista de teclado según el estado de [mostrarTeclado].
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("images/fondo_juego.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: mostrarTeclado
            ? _buildPantallaTeclado()
            : _buildPantallaRuleta(),
      ),
    );
  }

  // ================================================================
  // PANTALLA 1 — RULETA
  // ================================================================

  /// Construye la pantalla con la ruleta, la pista, el nivel y el marcador.
  Widget _buildPantallaRuleta() {
    return Column(
      children: [
        // Barra superior con navegación y marcador.
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    // Botón para salir al login.
                    IconButton(
                      onPressed: () => Navigator.of(context)
                          .pushNamedAndRemoveUntil(
                              '/login', (route) => false),
                      icon: const Icon(Icons.arrow_back,
                          color: Colors.white, size: 28),
                    ),
                    // Botón de ayuda con las instrucciones del juego.
                    IconButton(
                      onPressed: () => mostrarInfoJuego(context),
                      icon: const Icon(Icons.info_outline_rounded,
                          color: Colors.white),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.monetization_on_outlined,
                        color: Colors.amberAccent, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      '$marcador€',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    // Acceso a la tienda de ítems.
                    IconButton(
                      onPressed: _abrirTienda,
                      icon: const Icon(Icons.shopping_bag_outlined,
                          color: Colors.amberAccent, size: 28),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Panel de pista, nivel, badges de ítems activos y casillas de la frase.
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 4),
          child: Column(
            children: [
              // Contenedor con la pista y el indicador de nivel actual.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.amberAccent.withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline,
                        color: Colors.amberAccent, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      "Pista: ${palabras[nivelActual]['pista']!}",
                      style: const TextStyle(
                        color: Colors.amberAccent,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const Spacer(),
                    // Indicador de nivel.
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amberAccent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "Nivel ${nivelActual + 1}/${palabras.length}",
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),

              // Badges de ítems activos; mensaje de "sin ítems" si no hay ninguno.
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (tieneEscudo)
                    _buildBadge(
                        Icons.shield, "Escudo", Colors.blueAccent),
                  if (tieneEscudo) const SizedBox(width: 8),
                  if (tieneAntiQuiebra)
                    _buildBadge(Icons.security, "Anti-Quiebra",
                        Colors.purpleAccent),
                  if (tieneAntiQuiebra) const SizedBox(width: 8),
                  if (pistasDisponibles > 0)
                    _buildBadge(Icons.lightbulb,
                        "Pistas x$pistasDisponibles", Colors.orange),
                  if (!tieneEscudo &&
                      !tieneAntiQuiebra &&
                      pistasDisponibles == 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.white38, size: 14),
                          SizedBox(width: 6),
                          Text(
                            "Sin ítems activos — visita la tienda",
                            style: TextStyle(
                                color: Colors.white38, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),

              // Casillas de la frase mostrando '?' por cada letra oculta.
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 5,
                runSpacing: 6,
                children: palabras[nivelActual]['frase']!
                    .split('')
                    .map((l) {
                  if (l == ' ') return const SizedBox(width: 10);
                  return Container(
                    width: 22,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: Colors.amberAccent.withOpacity(0.4),
                        width: 1.5,
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        "?",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        // Ruleta de la fortuna, centrada y ocupando el espacio restante.
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 8),
              child: _dibujarRuleta(),
            ),
          ),
        ),
      ],
    );
  }

  // ================================================================
  // PANTALLA 2 — TECLADO
  // ================================================================

  /// Construye la pantalla con el teclado de letras, la silueta y el marcador.
  Widget _buildPantallaTeclado() {
    return Column(
      children: [
        // Barra superior con navegación y marcador (idéntica a la pantalla de ruleta).
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context)
                          .pushNamedAndRemoveUntil(
                              '/login', (route) => false),
                      icon: const Icon(Icons.arrow_back,
                          color: Colors.white, size: 28),
                    ),
                    IconButton(
                      onPressed: () => mostrarInfoJuego(context),
                      icon: const Icon(Icons.info_outline_rounded,
                          color: Colors.white),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.monetization_on_outlined,
                        color: Colors.amberAccent, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      '$marcador€',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    IconButton(
                      onPressed: _abrirTienda,
                      icon: const Icon(Icons.shopping_bag_outlined,
                          color: Colors.amberAccent, size: 28),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Casillas de letras con las ya adivinadas reveladas.
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 4),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 5,
            runSpacing: 8,
            children: palabras[nivelActual]['frase']!.split('').map((l) {
              if (l == ' ') return const SizedBox(width: 12);
              bool acertada = letrasAdivinadas.contains(l.toUpperCase());
              return Container(
                width: 32,
                height: 42,
                decoration: BoxDecoration(
                  color: acertada
                      ? Colors.white
                      : Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: Colors.amber.shade700, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 4,
                      offset: Offset(2, 2),
                    )
                  ],
                ),
                child: Center(
                  child: Text(
                    // Mostrar la letra si fue adivinada; ocultar si no.
                    acertada ? l : "",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // Badge que indica el valor del giro actual o el importe de la apuesta.
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: esperandoLetraApuesta
                  ? Colors.purple.withOpacity(0.25)
                  : Colors.amber.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: esperandoLetraApuesta
                    ? Colors.purpleAccent
                    : Colors.amberAccent,
              ),
            ),
            child: Text(
              esperandoLetraApuesta
                  ? "🎰 Apuesta: $apuestaPendiente€"
                  : "Jugando por: $valorGiroActual€ por letra",
              style: TextStyle(
                color: esperandoLetraApuesta
                    ? Colors.white
                    : Colors.amberAccent,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),

        // Silueta visual de la categoría del nivel actual.
        Image.asset(
          _obtenerSiluetaCategoria(),
          width: MediaQuery.of(context).size.width * 0.40,
          height: MediaQuery.of(context).size.width * 0.40,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 6),

        // Contador de letras acertadas sobre el total.
        Container(
          width: MediaQuery.of(context).size.width * 0.65,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black45,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
                color: Colors.amber.withOpacity(0.3), width: 1.5),
          ),
          child: Text(
            "${_obtenerLetrasAcertadasContador()} de "
            "${_obtenerLetrasTotalesContador()} acertadas",
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Botón de pista, visible solo si el jugador tiene pistas disponibles.
        if (pistasDisponibles > 0)
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 6),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
              ),
              icon: const Icon(Icons.lightbulb),
              label: Text("Usar Pista ($pistasDisponibles)"),
              onPressed: () {
                setState(() {
                  String frase =
                      palabras[nivelActual]['frase']!.toUpperCase();
                  // Obtener las letras de la frase que aún no han sido adivinadas.
                  List<String> faltantes = frase
                      .split('')
                      .where((l) =>
                          !letrasAdivinadas.contains(l) && l != ' ')
                      .toList();
                  if (faltantes.isNotEmpty) {
                    pistasDisponibles--;
                    String letraPista = (faltantes..shuffle()).first;
                    comprobarLetra(letraPista);
                  }
                });
              },
            ),
          ),

        const SizedBox(height: 6),

        // Teclado de letras alineado en la parte superior de su zona.
        Flexible(
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.92,
              child: _dibujarTeclado(),
            ),
          ),
        ),

        const SizedBox(height: 8),
      ],
    );
  }

  // ================================================================
  // HELPERS DE WIDGETS
  // ================================================================

  /// Abre la pantalla de la tienda y gestiona el callback de compra.
  ///
  /// Actualiza el marcador y activa el efecto del ítem correspondiente
  /// una vez confirmada la compra.
  void _abrirTienda() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TiendaPage(
          monedasActuales: marcador,
          idUsuario: widget.usuario.id,
          onComprar: (coste, item) {
            setState(() {
              marcador -= coste;
              switch (item) {
                case "Escudo":
                  tieneEscudo = true;
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(const SnackBar(
                      content: Text("¡Escudo comprado y activo!"),
                      backgroundColor: Colors.blueAccent,
                      duration: Duration(seconds: 3),
                      behavior: SnackBarBehavior.floating,
                    ));
                  break;

                case "Pista Extra":
                  pistasDisponibles += 1;
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(const SnackBar(
                      content: Text("¡Pista comprada!"),
                      backgroundColor: Colors.blueAccent,
                      duration: Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ));
                  break;

                case "Anti-Quiebra":
                  tieneAntiQuiebra = true;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("¡Anti-Quiebra comprada y activa!"),
                    backgroundColor: Colors.blueAccent,
                  ));
                  break;

                default:
                  print("Error: ítem $item no existe");
              }
            });
          },
        ),
      ),
    );
  }

  /// Construye un badge (indicador visual) para un ítem activo.
  ///
  /// [icon] es el icono del ítem, [label] su nombre y [color] el color del badge.
  Widget _buildBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: color.withOpacity(0.6), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // RULETA Y TECLADO
  // ================================================================

  /// Construye la ruleta de la fortuna adaptada al espacio disponible.
  ///
  /// Usa [LayoutBuilder] para obtener el máximo cuadrado posible y así
  /// mantener la ruleta siempre circular y centrada.
  Widget _dibujarRuleta() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // El lado del cuadrado es el menor de ancho y alto disponibles.
        final side = constraints.maxWidth < constraints.maxHeight
            ? constraints.maxWidth
            : constraints.maxHeight;

        return SizedBox(
          width: side,
          height: side,
          child: FortuneWheel(
            selected: selected.stream,
            animateFirst: false,
            onFling: () {
              // Al arrastrar la ruleta, reiniciar el teclado y elegir un sector al azar.
              setState(() {
                mostrarTeclado = false;
              });
              indiceGanador = Random().nextInt(premios.length);
              selected.add(indiceGanador);
            },
            onAnimationEnd: () {
              // Cuando la ruleta se detiene, procesar el premio del sector ganador.
              String res = premios[indiceGanador];
              setState(() {
                String resLimpio = res.trim().toUpperCase();
                if (resLimpio.contains('PIERDES TODO') ||
                    resLimpio.contains('AZAR') ||
                    resLimpio.contains('APUESTA')) {
                  _procesarResultadoRuleta(resLimpio);
                } else {
                  try {
                    valorGiroActual = int.parse(
                        resLimpio.replaceAll('€', '').trim());
                    mostrarTeclado = true;
                    _guardarMovimiento('giro_ruleta', valorGiroActual);
                  } catch (e) {
                    print("Error al procesar dinero: $e");
                  }
                }
              });
            },
            items: [
              for (int i = 0; i < premios.length; i++)
                FortuneItem(
                  child: Text(
                    premios[i],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  style: FortuneItemStyle(
                    color: coloresRuleta[i % coloresRuleta.length],
                    borderColor: Colors.white,
                    borderWidth: 2,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Construye el teclado virtual con las letras del abecedario español.
  ///
  /// Las letras ya pulsadas aparecen en gris con una cruz y no son interactivas.
  /// El tamaño de las teclas se adapta según la altura de pantalla disponible.
  Widget _dibujarTeclado() {
    const abecedario = "ABCDEFGHIJKLMNÑOPQRSTUVWXYZ";

    // Tamaños adaptativos para pantallas pequeñas (< 700 px de alto).
    final screenH = MediaQuery.of(context).size.height;
    final keyW = screenH < 700 ? 30.0 : 35.0;
    final keyH = screenH < 700 ? 36.0 : 42.0;
    final fontSize = screenH < 700 ? 13.0 : 16.0;
    final vPad = screenH < 700 ? 6.0 : 14.0;

    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: vPad),
        decoration: BoxDecoration(
          color: Colors.black38,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white12, width: 1.5),
        ),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 5,
          runSpacing: 8,
          children: abecedario.split('').map((l) {
            bool usada = letrasAdivinadas.contains(l);
            return InkWell(
              onTap: usada ? null : () => comprobarLetra(l),
              child: SizedBox(
                width: keyW,
                height: keyH,
                child: Stack(
                  children: [
                    // Fondo de la tecla: blanco si disponible, rojo tenue si usada.
                    Container(
                      decoration: BoxDecoration(
                        color: usada
                            ? Colors.red.withOpacity(0.15)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: usada
                            ? Border.all(
                                color:
                                    Colors.redAccent.withOpacity(0.3),
                                width: 1)
                            : Border.all(
                                color: Colors.amber.shade600,
                                width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          l,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: fontSize,
                            color: usada
                                ? Colors.white24
                                : Colors.black,
                          ),
                        ),
                      ),
                    ),
                    // Cruz superpuesta para indicar que la letra ya fue usada.
                    if (usada)
                      Center(
                        child: Icon(
                          Icons.clear,
                          color: Colors.redAccent.withOpacity(0.7),
                          size: 20,
                        ),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ================================================================
// FUNCIÓN GLOBAL — INSTRUCCIONES DEL JUEGO
// ================================================================

/// Muestra un diálogo con las instrucciones completas del juego.
///
/// Cubre el objetivo, el flujo de juego, las casillas especiales
/// de la ruleta y los ítems disponibles en la tienda.
void mostrarInfoJuego(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Colors.grey[900],
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Cómo Jugar 🎡',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 500,
          child: SingleChildScrollView(
            child: Text(
              "🎡 OBJETIVO\n"
              "Adivina la frase oculta letra a letra. Hay varios niveles, cada uno con una frase distinta. "
              "Al completarlos todos, las monedas acumuladas se guardan en un ranking global.\n\n"
              "🔄 CÓMO SE JUEGA\n"
              "1. Desliza la ruleta para girarla. El sector donde se detenga marca el valor de las letras en ese turno.\n\n"
              "2. Fíjate en la PISTA (categoría) que aparece arriba y en la SILUETA del centro para intuir la frase.\n\n"
              "3. Pulsa una letra del teclado:\n"
              "   ✅ Letra correcta → aparece en su posición dentro de la frase y sumas (valor del giro × veces que aparece esa letra).\n"
              "   ❌ Letra incorrecta → pierdes la mitad de tus monedas actuales y vuelves a la ruleta para girar de nuevo.\n\n"
              "4. Las letras ya usadas quedan descartadas en el teclado con una cruz (✗)\n\n"
              "5. Cuando todas las letras de la frase estén completadas, ¡pasas al siguiente nivel!\n\n"
              "🎰 CASILLAS ESPECIALES DE LA RULETA\n"
              "• PIERDES TODO → tu marcador cae a 0€ de golpe.\n"
              "• AZAR → el destino actúa solo: puede darte monedas extra o quitártelas, de forma completamente aleatoria.\n"
              "• APUESTA → antes de elegir letra, decides cuánto apostar (tú ajustas la cantidad con un slider):\n"
              "     - Si la primera letra que selecciones está en la frase → ganas el doble de lo apostado.\n"
              "     - Si no está → pierdes lo apostado.\n\n"
              "🛡️ ÍTEMS Y MEJORAS (Tienda)\n"
              "Puedes comprar ítems con tus monedas para protegerte o conseguir ventajas:\n\n"
              "• Escudo 🛡 → te protege UNA vez: si fallas una letra, no sufres ninguna penalización. Se activa automáticamente al comprarse.\n\n"
              "• Pista Extra 💡 → revela automáticamente una letra oculta de la frase actual. Puedes acumular varias. "
              "Aparece un botón en la pantalla del teclado para usarla cuando quieras.\n\n"
              "• Anti-Quiebra 🔒 → te salva UNA vez de la casilla PIERDES TODO. "
              "Si ya tienes 0€ cuando caes en esa casilla, no pasa nada porque no te puedes quedar en negativo.\n\n",
              style: const TextStyle(
                  fontSize: 13, height: 1.6, color: Colors.white70),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cerrar',
              style: TextStyle(
                  color: Colors.amber, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      );
    },
  );
}
