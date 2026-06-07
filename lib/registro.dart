import 'package:flutter/material.dart';
import 'package:suerte/connection.dart';
import 'package:suerte/dialogs.dart';
import 'package:suerte/models.dart';

/// Pantalla de registro de nuevos usuarios.
///
/// Recoge nombre, apellidos, teléfono, correo, nombre de usuario
/// y contraseña, valida cada campo y crea el registro en la base de datos.
// ignore: use_key_in_widget_constructors
class Registro extends StatefulWidget {
  @override
  // ignore: library_private_types_in_public_api
  _RegistroState createState() => _RegistroState();
}

/// Estado asociado a [Registro].
class _RegistroState extends State<Registro> {
  /// Clave global para controlar y validar el formulario.
  final keyForm = GlobalKey<FormState>();

  /// Datos recogidos del formulario.
  String nombre = '', apellidos = '', correo = '', nombreUsuario = '',
      contrasenha = '';
  String telefono = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Imagen de fondo de la pantalla de registro.
          Positioned.fill(
            child: Image.asset('images/register.png', fit: BoxFit.cover),
          ),

          // Degradado radial oscuro para mejorar la legibilidad del formulario.
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Colors.black.withOpacity(0.5),
                    Colors.transparent,
                  ],
                  radius: 1.0,
                ),
              ),
            ),
          ),

          // Formulario de registro con scroll para pantallas pequeñas.
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(25, 140, 25, 20),
              child: Form(
                key: keyForm,
                child: Column(
                  children: [
                    _crearInput(
                      label: "Nombre",
                      onSave: (val) => nombre = val!,
                      icon: Icons.person,
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Escribe tu nombre'
                          : null,
                    ),
                    _crearInput(
                      label: "Apellidos",
                      onSave: (val) => apellidos = val!,
                      icon: Icons.people,
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Escribe tus apellidos'
                          : null,
                    ),
                    _crearInput(
                      label: "Teléfono",
                      onSave: (val) => telefono = val!,
                      icon: Icons.phone,
                      keyboard: TextInputType.phone,
                      validator: (value) => (value?.length != 9)
                          ? 'El número de teléfono debe tener 9 números'
                          : null,
                    ),
                    _crearInput(
                      label: "Correo",
                      onSave: (val) => correo = val!,
                      icon: Icons.email,
                      keyboard: TextInputType.emailAddress,
                      validator: (value) {
                        final emailRegex =
                            RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                        if (value == null || !emailRegex.hasMatch(value)) {
                          return 'Email no válido, recuerda poner " @ "';
                        }
                        return null;
                      },
                    ),
                    _crearInput(
                      label: "Nombre de usuario",
                      onSave: (val) => nombreUsuario = val!,
                      icon: Icons.account_circle,
                      validator: (value) => (value!.length < 8)
                          ? 'El nombre de usuario debe tener mínimo 8 caracteres'
                          : null,
                    ),
                    _crearInput(
                      label: "Contraseña",
                      onSave: (val) => contrasenha = val!,
                      icon: Icons.lock,
                      isPassword: true,
                      validator: (value) => (value!.length < 6)
                          ? 'La contraseña debe tener mínimo 6 caracteres'
                          : null,
                    ),

                    SizedBox(height: 10),

                    // Botón de envío del formulario.
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber[700],
                        foregroundColor: Colors.black,
                        minimumSize: Size(double.infinity, 45),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 5,
                      ),
                      onPressed: () async {
                        if (!keyForm.currentState!.validate()) return;
                        keyForm.currentState!.save();

                        // Mostrar indicador de carga durante la operación.
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => const Center(
                            child: CircularProgressIndicator(
                                color: Colors.amberAccent),
                          ),
                        );

                        try {
                          ConexionDB conexion = ConexionDB();

                          // Comprobar si el nombre de usuario ya existe.
                          bool yaExiste =
                              await conexion.existeUsuario(nombreUsuario);

                          if (mounted) Navigator.pop(context);

                          if (yaExiste) {
                            await dialogAviso(
                              context,
                              'El usuario "$nombreUsuario" ya está registrado. '
                              'Elige otro.',
                              'VOLVER',
                              '.',
                            );
                            return;
                          }

                          // Mostrar indicador de carga durante la inserción.
                          if (mounted) {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (_) => const Center(
                                child: CircularProgressIndicator(
                                    color: Colors.amberAccent),
                              ),
                            );
                          }

                          // Crear el objeto usuario con las monedas iniciales a 0.
                          Usuario usuarioParaRegistrar = Usuario(
                            id: 0,
                            username: nombreUsuario,
                            password: contrasenha,
                            email: correo,
                            monedasGlobales: 0,
                          );

                          bool registroOk =
                              await conexion.registro(usuarioParaRegistrar);

                          if (mounted) Navigator.pop(context);

                          if (registroOk) {
                            await dialogAviso(
                                context, 'Registro completado', 'OK',
                                'Ya puedes iniciar sesión');
                            if (mounted) {
                              Navigator.pushReplacementNamed(
                                  context, '/login');
                            }
                          } else {
                            await dialogAviso(
                              context,
                              'No se pudo completar el registro',
                              'VOLVER',
                              'Inténtalo de nuevo',
                            );
                          }
                        } catch (e) {
                          // Cerrar el spinner si quedó abierto por una excepción.
                          if (mounted) Navigator.pop(context);

                          // Traducir el error técnico a un mensaje comprensible.
                          String mensajeError;
                          if (e.toString().contains('timed out') ||
                              e.toString().contains('SocketException')) {
                            mensajeError =
                                'No se pudo conectar con el servidor.\n\n'
                                'Comprueba que XAMPP está activo y MySQL corriendo.';
                          } else if (e.toString().contains('Access denied')) {
                            mensajeError =
                                'Acceso denegado a la base de datos.\n'
                                'Revisa los permisos de MySQL.';
                          } else {
                            mensajeError =
                                'Error inesperado:\n${e.toString()}';
                          }

                          await dialogAviso(
                              context, mensajeError, 'VOLVER', '');
                        }
                      },
                      child: Text(
                        "ENVIAR",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),

                    SizedBox(height: 10),

                    // Enlace hacia la pantalla de login para usuarios ya registrados.
                    Container(
                      padding:
                          EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.amber.withOpacity(0.25),
                          width: 1,
                        ),
                      ),
                      child: TextButton(
                        onPressed: () =>
                            Navigator.pushReplacementNamed(context, '/login'),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                              vertical: 4, horizontal: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: "¿Ya tienes cuenta? ",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 13),
                              ),
                              TextSpan(
                                text: "Inicia sesión",
                                style: TextStyle(
                                  color: Colors.amber[700],
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Construye un campo de texto estilizado para el formulario de registro.
  ///
  /// [label] es la etiqueta visible del campo.
  /// [onSave] callback que guarda el valor cuando se llama a [FormState.save].
  /// [validator] función de validación que devuelve un mensaje de error o null.
  /// [isPassword] oculta el texto si es [true] (por defecto [false]).
  /// [keyboard] tipo de teclado que se muestra (por defecto texto normal).
  /// [icon] icono prefijo del campo.
  Widget _crearInput({
    required String label,
    required Function(String?) onSave,
    required FormFieldValidator<String> validator,
    bool isPassword = false,
    TextInputType keyboard = TextInputType.text,
    IconData? icon,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 15),
      child: TextFormField(
        obscureText: isPassword,
        keyboardType: keyboard,
        style: TextStyle(color: Colors.white),
        validator: validator,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.amber),
          labelText: label,
          labelStyle: TextStyle(color: Colors.amber[200]),
          // Estilo del mensaje de error en color ámbar con sombra para legibilidad.
          errorStyle: TextStyle(
            color: Colors.amberAccent,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(color: Colors.black, blurRadius: 2)],
          ),
          errorBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.amberAccent, width: 1.5),
            borderRadius: BorderRadius.circular(15),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.amber, width: 2.5),
            borderRadius: BorderRadius.circular(15),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide:
                BorderSide(color: Colors.amber.withOpacity(0.4)),
            borderRadius: BorderRadius.circular(15),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.amber, width: 2),
            borderRadius: BorderRadius.circular(15),
          ),
          filled: true,
          fillColor: Colors.black45,
        ),
        onSaved: onSave,
      ),
    );
  }
}
