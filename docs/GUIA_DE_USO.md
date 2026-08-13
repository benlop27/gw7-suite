# GW-7 Studio — Guía de uso

GW-7 Studio es una aplicación de control para el teclado arreglador **Roland GW-7**.
Te permite seleccionar tonos, controlar efectos, lanzar estilos de acompañamiento y
guardar tu configuración favorita, todo desde una tablet, un teléfono o un navegador.

## Requisitos

- Un **Roland GW-7** encendido.
- Un puente **GW-7 BLE MIDI** conectado al teclado (el puente que convierte MIDI
  inalámbrico en señales que el teclado entiende).
- La aplicación instalada (Android) o abierta en el navegador:

  - **Android:** instala el APK desde la sección *Releases* del repositorio.
  - **Navegador:** abre `https://benlop27.github.io/gw7-suite/`.

## Conectarse al teclado

1. Enciende el puente BLE y el teclado. El puente se anuncia como **"Roland GW7"**.
2. Abre GW-7 Studio. La app busca el puente automáticamente al iniciar.
3. Pulsa el botón **Connect** en la barra superior si no se conectó solo.

Cuando la conexión es correcta, la barra superior muestra el mensaje
**"Connected · Roland GW7 Bluetooth"** y el indicador de estado se enciende en verde.

> Si la app no encuentra el puente, usa el botón **Choose MIDI device** (icono de
> conector) para abrir la lista de dispositivos MIDI disponibles y elige el puente
> manualmente.

![Pantalla Stage conectada](screenshots/01_stage_connected.png)

## La barra superior

En la parte superior de la pantalla siempre ves:

- **Estado de conexión:** un indicador con el mensaje *Connected / Not connected*.
- **Choose MIDI device (icono de conector):** abre la lista de dispositivos MIDI.
- **SYNC:** envía al teclado toda la configuración actual de la app (tono, volumen,
  efectos, etc.) de una sola vez.
- **Connect / Disconnect:** conecta o desconecta el teclado.

En la parte inferior de la pantalla, una línea de texto muestra el último mensaje
MIDI enviado (por ejemplo `TX B0 00 08 · B0 20 02 · C0 00 ch4`). Esto es útil para
confirmar que los comandos llegan al teclado.

## La pestaña Stage

Es tu panel de trabajo principal. Tiene dos secciones:

- **Favourites:** accesos directos a tus tonos favoritos. Aquí aparecen los presets
  que marcaste con ★ en la pestaña Presets. Pulsa uno para seleccionarlo al instante.
- **Master Volume:** control de volumen general del teclado (de 0 a 127).

![Favoritos y volumen](screenshots/05_stage_favorites.png)

## La pestaña Presets

Aquí eliges el tono que toca el teclado.

1. Elige una **categoría** en la barra superior del panel (PIANO, ELECTRIC PIANO,
   ORGAN, BASS, PAD, etc.).
2. Pulsa un **tono** de la cuadrícula para seleccionarlo. Se envía al teclado al momento.
3. Usa la **★** en la esquina de cada tono para añadirlo a *Favourites*.

En la parte superior del panel hay dos pantallas LCD: la primera muestra el banco y
número de tono (por ejemplo `PIANO 001`) y la segunda el canal y el nombre del tono
(por ejemplo `ch4 · St.Piano 1`).

![Selección de tonos](screenshots/02_presets_tone.png)

> Los tonos se envían como banco (CC00/CC32) + cambio de programa (Program Change)
> en el canal configurado por la app (canal 4 por defecto).

## La pestaña Effects

Controladores rápidos de efectos, enviados como mensajes *Control Change* (CC) en el
canal activo:

| Control | Mensaje CC |
| --- | --- |
| ATTACK (ataque) | CC73 |
| RELEASE (caída) | CC72 |
| REVERB (reverberación) | CC91 |
| CHORUS (coro) | CC93 |
| EXPR (expresión) | CC11 |
| PAN (panorama) | CC10 |

Cada control tiene un deslizador de 0 a 127. Mueve el deslizador y el cambio se envía
al teclado de inmediato. La etiqueta **SENT ON CH4** indica el canal de envío.

![Controles de efectos](screenshots/03_effects.png)

## La pestaña Utils

Control del **acompañamiento (backing track)** del GW-7:

1. Elige una **categoría de estilo** (Rock, Dance, Jazz, Latin, 8Beat, etc.).
2. Selecciona un **estilo** de la lista (por ejemplo `001 SteadyRk 73`). El número es
   el estilo y el último número es su tempo.
3. Usa los **botones de transporte** para controlar el acompañamiento:

   - **START:** inicia el acompañamiento.
   - **STOP:** lo detiene.
   - **CONTINUE:** continúa desde donde se detuvo.
   - **INTRO:** lanza el estilo desde la introducción.
   - **FILL:** relleno (fill-in).
   - **ENDING:** final del acompañamiento.

![Acompañamiento y transporte](screenshots/04_utils.png)

## Consejos

- Pulsa **SYNC** después de ajustar varios controles para reenviar todo el estado al
  teclado de una sola vez.
- Al conectar, la app reenvía automáticamente la última configuración guardada, así el
  teclado recupera tu setup de la última vez.
- Si el teclado no responde, revisa la línea inferior de la pantalla: si no aparece
  ningún `TX ...`, la conexión MIDI no está activa; reconecta con **Connect**.
