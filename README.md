# Fortune SL

Juego móvil para Android inspirado en *La Ruleta de la Suerte*, hecho con **Flutter** y **MySQL**.
Proyecto final del ciclo superior de Desarrollo de Aplicaciones Multiplataforma (DAM), curso 2025/2026.

## Capturas

<!-- Sube aquí 3 o 4 capturas: login, ruleta/juego, tienda y ranking.
     En GitHub puedes arrastrarlas al editor y se insertan solas. -->

| Login | Juego | Tienda | Ranking |
|-------|-------|--------|---------|
| (captura) | (captura) | (captura) | (captura) |

## Qué hace la app

- **Registro e inicio de sesión** con validación de formularios (email, contraseña, usuario duplicado).
- **Ruleta animada**: se gira deslizando el dedo y cae en un sector aleatorio.
- **Teclado virtual y panel de letras** para adivinar frases por categorías (Película, Comida, Ciudad, Animal, Deporte), con varios niveles.
- **Eventos especiales**: APUESTA, AZAR y PIERDES TODO.
- **Tienda** donde se gastan las monedas ganadas: Pista Extra, Escudo y Anti-Quiebra.
- **Ranking global** de jugadores ordenado por monedas.
- **Logros** que se guardan en la base de datos.

## Tecnologías

- Flutter y Dart (interfaz y lógica del juego)
- MySQL, conectado directamente desde la app con el paquete `mysql1`
- XAMPP y phpMyAdmin (servidor y administración de la base de datos en local)
- Visual Studio Code y emulador de Android Studio

## Estructura principal

```
lib/
├── main.dart       # Punto de entrada
├── login.dart      # Inicio de sesión
├── registro.dart   # Alta de usuario
├── first.dart      # Pantalla principal del juego (ruleta)
├── tienda.dart     # Tienda de ítems
└── ranking.dart    # Ranking global
```

## Cómo ejecutarlo

1. Instala [Flutter](https://docs.flutter.dev/get-started/install), XAMPP y un emulador de Android.
2. Clona el repositorio:
   ```bash
   git clone https://github.com/rodrigoGit23/Fortune-SL.git
   cd Fortune-SL
   ```
3. Abre XAMPP y arranca **Apache** y **MySQL**.
4. En `http://localhost/phpmyadmin` crea la base de datos e importa el archivo `database.sql` (estructura de las tablas: usuarios, partidas, movimientos, inventario y logros).
5. En la clase `ConexionDB` pon los datos de tu servidor. Desde el emulador de Android, el host es `10.0.2.2`, que apunta al `localhost` de tu ordenador.
6. Instala las dependencias y ejecuta:
   ```bash
   flutter pub get
   flutter run
   ```

## Limitaciones y mejoras previstas

- **Conexión directa a MySQL desde la app.** Lo elegí por rapidez y sencillez en un proyecto académico, pero deja los datos de conexión expuestos en el cliente. En un entorno real habría que añadir una **API REST** intermedia.
- Solo probado en Android.
- Las frases del juego están escritas en el código; la idea es cargarlas desde la base de datos.
- Posibles ampliaciones: multijugador, notificaciones y más categorías.

## Autor

**Rodrigo Pinales Severino** · Técnico Superior en DAM · Cursando DAW
[github.com/rodrigoGit23](https://github.com/rodrigoGit23)
