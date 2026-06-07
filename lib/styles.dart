import 'package:flutter/material.dart';

/// Devuelve el estilo visual unificado para los campos de texto del formulario.
///
/// Aplica bordes redondeados, fondo semitransparente oscuro y colores
/// corporativos (marrón para el borde inactivo, ámbar para el borde activo).
///
/// [nombreEtiqueta] es el texto que se muestra como etiqueta flotante.
InputDecoration estiloCuadroFormulario(String nombreEtiqueta) {
  return InputDecoration(
    labelText: nombreEtiqueta,
    labelStyle: TextStyle(color: Colors.amber[200]),
    filled: true,
    fillColor: Colors.black.withValues(alpha: 0.6),

    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(25),
    ),

    // Borde cuando el campo no está enfocado.
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(25),
      borderSide: BorderSide(color: Colors.brown, width: 2),
    ),

    // Borde cuando el campo está siendo editado.
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(25),
      borderSide: BorderSide(color: Colors.amber, width: 1),
    ),

    contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 25),
  );
}

/// Devuelve un botón de formulario con el estilo corporativo de la aplicación.
///
/// Utiliza un [OutlinedButton] de ancho fijo (115 px) con fondo oscuro,
/// texto en color ámbar y borde en color marrón.
///
/// [textoBoton] es la etiqueta visible del botón.
/// [tamanoLetra] controla el tamaño de la fuente.
/// [accionDeOnPressed] es el callback que se ejecuta al pulsar el botón.
Widget estiloBotonFormulario(
    String textoBoton, double tamanoLetra, VoidCallback accionDeOnPressed) {
  return SizedBox(
    width: 115,
    child: OutlinedButton(
      onPressed: accionDeOnPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.black.withValues(alpha: 0.6),
        foregroundColor: Colors.amber[200],
        side: BorderSide(color: Colors.brown, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        padding: EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(
        textoBoton,
        style: TextStyle(
          fontFamily: 'Fell',
          fontSize: tamanoLetra,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    ),
  );
}
