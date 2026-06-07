/// Modelo de datos que representa a un usuario registrado en la aplicación.
class Usuario {
  /// Identificador único del usuario en la base de datos.
  int id;

  /// Nombre de usuario visible en el ranking y en el juego.
  String username;

  /// Contraseña del usuario (se almacena tal cual desde el formulario).
  String password;

  /// Dirección de correo electrónico del usuario.
  String email;

  /// Monedas acumuladas a lo largo de todas las partidas jugadas.
  int monedasGlobales;

  /// Crea una instancia de [Usuario] con todos los campos obligatorios.
  Usuario({
    required this.id,
    required this.username,
    required this.password,
    required this.email,
    required this.monedasGlobales,
  });
}
