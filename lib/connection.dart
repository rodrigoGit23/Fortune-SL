import 'package:mysql1/mysql1.dart';
import 'models.dart';

/// Clase que centraliza todas las operaciones de acceso a la base de datos MySQL.
///
/// Cada método público abre una conexión, ejecuta la consulta y cierra
/// la conexión en el bloque [finally], garantizando que no queden
/// conexiones abiertas aunque se produzca un error.
class ConexionDB {
  // ================================================================
  // CONEXIÓN
  // ================================================================

  /// Abre y devuelve una nueva conexión a la base de datos.
  ///
  /// La dirección 10.0.2.2 corresponde al host local del emulador Android.
  Future<MySqlConnection> _abrir() async {
    return await MySqlConnection.connect(ConnectionSettings(
      host: '10.0.2.2',
      port: 3306,
      user: 'flutter',
      password: 'flutter123',
      db: 'juego_ruleta',
      timeout: Duration(seconds: 15),
    ));
  }

  // ================================================================
  // USUARIOS
  // ================================================================

  /// Verifica las credenciales del usuario y devuelve su objeto si son correctas.
  ///
  /// Devuelve [null] si el usuario no existe o la contraseña no coincide.
  Future<Usuario?> login(String username, String password) async {
    final db = await _abrir();
    try {
      var r = await db.query(
          'SELECT id_usuario, username, password, email, monedas_globales '
          'FROM usuarios WHERE username = ? AND password = ?',
          [username, password]);

      if (r.isEmpty) return null;

      var t = r.first;
      return Usuario(
        id: t['id_usuario'],
        username: t['username'],
        password: t['password'],
        email: t['email'] ?? '',
        monedasGlobales: t['monedas_globales'] ?? 0,
      );
    } catch (e) {
      print('ERROR login: $e');
      return null;
    } finally {
      await db.close();
    }
  }

  /// Inserta un nuevo usuario en la base de datos.
  ///
  /// Devuelve [true] si el registro se completó con éxito, [false] en caso contrario.
  Future<bool> registro(Usuario u) async {
    final db = await _abrir();
    try {
      await db.query(
          'INSERT INTO usuarios (username, password, email, monedas_globales) '
          'VALUES (?, ?, ?, ?)',
          [u.username, u.password, u.email, u.monedasGlobales]);
      return true;
    } catch (e) {
      print('ERROR registro: $e');
      return false;
    } finally {
      await db.close();
    }
  }

  /// Comprueba si ya existe un usuario con el [username] indicado.
  ///
  /// Devuelve [true] si el nombre de usuario está ocupado.
  Future<bool> existeUsuario(String username) async {
    final db = await _abrir();
    try {
      var r = await db.query(
          'SELECT 1 FROM usuarios WHERE username = ?', [username]);
      return r.isNotEmpty;
    } catch (e) {
      print('ERROR existeUsuario: $e');
      return false;
    } finally {
      await db.close();
    }
  }

  /// Suma [cantidad] monedas al saldo global del usuario identificado por [idUsuario].
  Future<void> sumarMonedas(int idUsuario, int cantidad) async {
    final db = await _abrir();
    try {
      await db.query(
          'UPDATE usuarios '
          'SET monedas_globales = monedas_globales + ? '
          'WHERE id_usuario = ?',
          [cantidad, idUsuario]);
    } catch (e) {
      print('ERROR sumarMonedas: $e');
    } finally {
      await db.close();
    }
  }

  /// Devuelve la lista de los 10 usuarios con más monedas, ordenados de mayor a menor.
  Future<List<Usuario>> obtenerRanking() async {
    final db = await _abrir();
    try {
      var r = await db.query(
          'SELECT username, monedas_globales FROM usuarios '
          'ORDER BY monedas_globales DESC LIMIT 10');

      return r.map((t) => Usuario(
            id: 0,
            username: t['username'],
            password: '',
            email: '',
            monedasGlobales: t['monedas_globales'] ?? 0,
          )).toList();
    } catch (e) {
      print('ERROR obtenerRanking: $e');
      return [];
    } finally {
      await db.close();
    }
  }

  // ================================================================
  // PARTIDAS
  // ================================================================

  /// Crea un nuevo registro de partida para [idUsuario] con puntuación inicial 0.
  ///
  /// Devuelve el identificador de la partida recién creada, o [null] si falló.
  Future<int?> iniciarPartida(int idUsuario) async {
    final db = await _abrir();
    try {
      var r = await db.query(
          'INSERT INTO partidas (id_usuario, puntos_totales) VALUES (?, 0)',
          [idUsuario]);
      return r.insertId;
    } catch (e) {
      print('ERROR iniciarPartida: $e');
      return null;
    } finally {
      await db.close();
    }
  }

  /// Actualiza la puntuación final de la partida identificada por [idPartida].
  Future<void> finalizarPartida(int idPartida, int puntosFinales) async {
    final db = await _abrir();
    try {
      await db.query(
          'UPDATE partidas SET puntos_totales = ? WHERE id_partida = ?',
          [puntosFinales, idPartida]);
    } catch (e) {
      print('ERROR finalizarPartida: $e');
    } finally {
      await db.close();
    }
  }

  // ================================================================
  // MOVIMIENTOS
  // ================================================================

  /// Registra un movimiento dentro de una partida en curso.
  ///
  /// [idPartida] identifica la partida activa.
  /// [accion] describe el tipo de movimiento (ej.: 'giro_ruleta', 'letra_correcta').
  /// [valorObtenido] es el valor numérico asociado al movimiento.
  Future<void> registrarMovimiento(
      int idPartida, String accion, int valorObtenido) async {
    final db = await _abrir();
    try {
      await db.query(
          'INSERT INTO movimientos (id_partida, accion, valor_obtenido) '
          'VALUES (?, ?, ?)',
          [idPartida, accion, valorObtenido]);
    } catch (e) {
      print('ERROR registrarMovimiento: $e');
    } finally {
      await db.close();
    }
  }

  // ================================================================
  // INVENTARIO
  // ================================================================

  /// Añade un ítem al inventario del usuario, sumando la cantidad si ya existe.
  ///
  /// Si el ítem [nombreItem] ya está en el inventario de [idUsuario],
  /// incrementa su cantidad; de lo contrario, crea un nuevo registro.
  Future<void> agregarAlInventario(
      int idUsuario, String nombreItem, int cantidad) async {
    final db = await _abrir();
    try {
      var existe = await db.query(
          'SELECT id_inv FROM inventario '
          'WHERE id_usuario = ? AND nombre_item = ?',
          [idUsuario, nombreItem]);

      if (existe.isNotEmpty) {
        await db.query(
            'UPDATE inventario SET cantidad = cantidad + ? WHERE id_inv = ?',
            [cantidad, existe.first['id_inv']]);
      } else {
        await db.query(
            'INSERT INTO inventario (id_usuario, nombre_item, cantidad) '
            'VALUES (?, ?, ?)',
            [idUsuario, nombreItem, cantidad]);
      }
    } catch (e) {
      print('ERROR agregarAlInventario: $e');
    } finally {
      await db.close();
    }
  }

  /// Devuelve todos los ítems del inventario de [idUsuario], ordenados por nombre.
  ///
  /// Cada elemento de la lista contiene las claves [nombre_item] y [cantidad].
  Future<List<Map<String, dynamic>>> obtenerInventario(int idUsuario) async {
    final db = await _abrir();
    try {
      var r = await db.query(
          'SELECT nombre_item, cantidad FROM inventario '
          'WHERE id_usuario = ? ORDER BY nombre_item',
          [idUsuario]);

      return r.map((t) => {
            'nombre_item': t['nombre_item'],
            'cantidad':    t['cantidad'],
          }).toList();
    } catch (e) {
      print('ERROR obtenerInventario: $e');
      return [];
    } finally {
      await db.close();
    }
  }

  // ================================================================
  // LOGROS
  // ================================================================

  /// Registra un logro para el usuario si aún no lo ha obtenido.
  ///
  /// Evita duplicados comprobando si ya existe un registro con el mismo
  /// [tipoLogro] para ese [idUsuario] antes de insertarlo.
  Future<void> registrarLogro(
      int idUsuario, String tipoLogro, String descripcion) async {
    final db = await _abrir();
    try {
      var existe = await db.query(
        'SELECT 1 FROM logros WHERE id_usuario = ? AND tipo_logro = ?',
        [idUsuario, tipoLogro],
      );

      if (existe.isEmpty) {
        await db.query(
          'INSERT INTO logros (id_usuario, tipo_logro, descripcion) '
          'VALUES (?, ?, ?)',
          [idUsuario, tipoLogro, descripcion],
        );
      }
    } catch (e) {
      print('ERROR registrarLogro: $e');
    } finally {
      await db.close();
    }
  }

  /// Devuelve todos los logros desbloqueados por [idUsuario], del más reciente al más antiguo.
  ///
  /// Cada elemento contiene las claves [tipo_logro], [descripcion] y [fecha].
  Future<List<Map<String, dynamic>>> obtenerLogros(int idUsuario) async {
    final db = await _abrir();
    try {
      var r = await db.query(
        'SELECT tipo_logro, descripcion, fecha FROM logros '
        'WHERE id_usuario = ? ORDER BY fecha DESC',
        [idUsuario],
      );

      return r.map((t) => {
            'tipo_logro':  t['tipo_logro'],
            'descripcion': t['descripcion'],
            'fecha':       t['fecha'].toString(),
          }).toList();
    } catch (e) {
      print('ERROR obtenerLogros: $e');
      return [];
    } finally {
      await db.close();
    }
  }
}
