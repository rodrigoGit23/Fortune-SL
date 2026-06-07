import 'package:flutter/material.dart';
import 'package:suerte/first.dart';
import '../connection.dart';
import '../models.dart';

/// Pantalla de inicio de sesión.
///
/// Recoge el nombre de usuario y la contraseña, valida el formulario
/// y comprueba las credenciales contra la base de datos.
// ignore: use_key_in_widget_constructors
class LoginStateful extends StatefulWidget {
  @override
  LoginEstado createState() => LoginEstado();
}

/// Estado asociado a [LoginStateful].
class LoginEstado extends State<LoginStateful> {
  /// Ruta de la imagen de fondo de la pantalla de login.
  String imgFondo = 'images/fondo_login.png';

  /// Nombre de usuario introducido en el formulario.
  String nombre = '';

  /// Contraseña introducida en el formulario.
  String password = '';

  /// Clave global para controlar y validar el formulario de login.
  var keyFormLogin = GlobalKey<FormState>();

  /// Valida el formulario, consulta la base de datos y navega a la pantalla
  /// principal si las credenciales son correctas.
  ///
  /// Muestra un [CircularProgressIndicator] mientras se realiza la consulta.
  /// Si el login falla, presenta un diálogo con las opciones de reintentar
  /// o ir al registro.
  recogerDatosLogin(BuildContext context) async {
    if (keyFormLogin.currentState!.validate()) {
      keyFormLogin.currentState!.save();

      // Mostrar indicador de carga mientras se consulta la base de datos.
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(color: Colors.amber),
        ),
      );

      ConexionDB db = ConexionDB();
      Usuario? usuarioLogin = await db.login(nombre, password);

      if (usuarioLogin != null && usuarioLogin.id != 0) {
        // Credenciales correctas: navegar a la pantalla principal del juego.
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => Principal(usuario: usuarioLogin),
          ),
        );
      } else {
        // Login fallido: mostrar diálogo de error con animación en los botones.
        bool animarReintentar = false;
        bool animarRegistrarme = false;

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return StatefulBuilder(
              builder: (context, setStateDialog) {
                return AlertDialog(
                  backgroundColor: Colors.grey[900],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  title: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.amber, size: 28),
                      SizedBox(width: 10),
                      Text(
                        "Error de acceso",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  content: Text(
                    'No se ha podido iniciar sesión.\n\n'
                    'Nombre de usuario y/o contraseña incorrectos '
                    'o registro no completado.',
                    style: TextStyle(
                        color: Colors.white70, fontSize: 14, height: 1.4),
                  ),
                  actionsPadding:
                      EdgeInsets.only(bottom: 25, left: 15, right: 15),
                  actions: [
                    Row(
                      children: [
                        // Botón "Reintentar": cierra el diálogo y permite
                        // volver a introducir las credenciales.
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: MouseRegion(
                              opaque: true,
                              onEnter: (_) => setStateDialog(
                                  () => animarReintentar = true),
                              onExit: (_) => setStateDialog(
                                  () => animarReintentar = false),
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: AnimatedContainer(
                                  duration: Duration(milliseconds: 150),
                                  curve: Curves.easeInOut,
                                  // Efecto hover: escala ligera y desplazamiento hacia arriba.
                                  transform: animarReintentar
                                      ? (Matrix4.identity()
                                        ..translate(0.0, -2.0)
                                        ..scale(1.05))
                                      : Matrix4.identity(),
                                  padding:
                                      EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: animarReintentar
                                        ? Colors.amber[500]
                                        : Colors.amber[700],
                                    borderRadius: BorderRadius.circular(15),
                                    boxShadow: animarReintentar
                                        ? [
                                            BoxShadow(
                                              color: Colors.amber
                                                  .withOpacity(0.5),
                                              blurRadius: 10,
                                              offset: Offset(0, 4),
                                            )
                                          ]
                                        : [],
                                  ),
                                  child: Center(
                                    child: Text(
                                      "REINTENTAR",
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Botón "Registrarme": cierra el diálogo y navega
                        // a la pantalla de registro.
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: MouseRegion(
                              opaque: true,
                              onEnter: (_) => setStateDialog(
                                  () => animarRegistrarme = true),
                              onExit: (_) => setStateDialog(
                                  () => animarRegistrarme = false),
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.pushNamed(
                                      context, '/registro');
                                },
                                child: AnimatedContainer(
                                  duration: Duration(milliseconds: 150),
                                  curve: Curves.easeInOut,
                                  transform: animarRegistrarme
                                      ? (Matrix4.identity()
                                        ..translate(0.0, -2.0)
                                        ..scale(1.05))
                                      : Matrix4.identity(),
                                  padding:
                                      EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: animarRegistrarme
                                        ? Colors.amber[500]
                                        : Colors.amber[700],
                                    borderRadius: BorderRadius.circular(15),
                                    boxShadow: animarRegistrarme
                                        ? [
                                            BoxShadow(
                                              color: Colors.amber
                                                  .withOpacity(0.5),
                                              blurRadius: 10,
                                              offset: Offset(0, 4),
                                            )
                                          ]
                                        : [],
                                  ),
                                  child: Center(
                                    child: Text(
                                      "REGISTRARME",
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            );
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Impide salir de la pantalla de login con el botón físico de retroceso.
      canPop: false,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            // Imagen de fondo que ocupa toda la pantalla.
            Positioned.fill(
              child: Image.asset(
                imgFondo,
                fit: BoxFit.cover,
              ),
            ),

            // Capa semitransparente sobre la imagen de fondo.
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.1),
              ),
            ),

            // Formulario centrado verticalmente en la pantalla.
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 30),
              child: Form(
                key: keyFormLogin,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 30),
                    _crearInput(
                      label: "Nombre de Usuario",
                      icon: Icons.person,
                      onSave: (val) => nombre = val!,
                    ),
                    _crearInput(
                      label: "Contraseña",
                      icon: Icons.lock,
                      isPassword: true,
                      onSave: (val) => password = val!,
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber[700],
                        foregroundColor: Colors.black,
                        minimumSize: Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: () => recogerDatosLogin(context),
                      child: Text(
                        "JUGAR",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye un campo de texto estilizado para el formulario de login.
  ///
  /// [label] es la etiqueta visible del campo.
  /// [icon] es el icono que aparece a la izquierda del campo.
  /// [onSave] callback que guarda el valor introducido.
  /// [isPassword] indica si el texto debe ocultarse (por defecto [false]).
  Widget _crearInput({
    required String label,
    required IconData icon,
    required Function(String?) onSave,
    bool isPassword = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20),
      child: TextFormField(
        obscureText: isPassword,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.amber),
          labelText: label,
          labelStyle: TextStyle(color: Colors.amber[200]),
          filled: true,
          fillColor: Colors.black45,
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.amber.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(15),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.amber, width: 2),
            borderRadius: BorderRadius.circular(15),
          ),
          // Bordes de error en color ámbar para mantener la coherencia visual.
          errorBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.amberAccent, width: 1.5),
            borderRadius: BorderRadius.circular(15),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.amberAccent, width: 2),
            borderRadius: BorderRadius.circular(15),
          ),
          errorStyle: TextStyle(
              color: Colors.amberAccent, fontWeight: FontWeight.bold),
        ),
        onSaved: onSave,
        validator: (val) =>
            (val == null || val.isEmpty) ? "Campo obligatorio" : null,
      ),
    );
  }
}
