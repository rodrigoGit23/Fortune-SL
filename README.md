# Fortune SL

Juego móvil para Android inspirado en *La Ruleta de la Suerte*, hecho con **Flutter** y **MySQL**.
Proyecto final del ciclo superior de Desarrollo de Aplicaciones Multiplataforma (DAM), curso 2025/2026.

## Capturas

| Login |
|-------|
| <img width="417" height="865" alt="registroUsuario" src="https://github.com/user-attachments/assets/b5c7ca5b-d188-4d17-99e8-812f873dd90e" />
| <img width="424" height="860" alt="inicio" src="https://github.com/user-attachments/assets/0dee856b-646c-44b8-8c48-2718163cb661" />
| Juego |
| <img width="414" height="849" alt="juego" src="https://github.com/user-attachments/assets/4c2a636d-0a75-4f27-a146-aa0c10981133" />
| Tienda | 
| <img width="397" height="834" alt="tienda" src="https://github.com/user-attachments/assets/f5d3d53e-c10e-494d-816f-3fabeb59d021" />
| Ranking |
|<img width="413" height="838" alt="ranking" src="https://github.com/user-attachments/assets/70092991-e290-4b27-8fb0-575f1934cf1d" />



## Qué hace la app

- **Registro e inicio de sesión** con validación de formularios (email, contraseña, usuario duplicado,caracteres incorrectos,cadenas incorrectas..).
- **Ruleta animada**: se gira deslizando el dedo sobre la ruleta(o haciendo el mismo gesto con el cursor) y cae en un sector aleatorio ya sea valor monetario o evento especial.
- **Teclado virtual y panel de letras** para adivinar frases por categorías con varios niveles (Película, Comida, Ciudad, Animal, Deporte) si te toca un valor monetario.
- **Eventos especiales**: APUESTA, AZAR y PIERDES TODO(eventos especiales) , cada uno de ellos tiene una función diferente.
- **Tienda** donde se gastan las monedas ganadas: Pista Extra, Escudo y Anti-Quiebra. Puedes comprar estas ayudas/mejoras para acertar más palabras y obtener el mayor número de monedas.
- **Ranking global** de todos los jugadores ordenado por la cantidad de monedas de mayor a menor cantidad.
- **Logros** que se guardan en la base de datos(primera compra , primer giro....).

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
- Posibles ampliaciones: multijugador, notificaciones y más categorías y niveles.

## Autor

**Rodrigo Pinales Severino** · Técnico Superior en DAM · Cursando DAW
[github.com/rodrigoGit23](https://github.com/rodrigoGit23)
