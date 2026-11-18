# GDD — Tenis arcade de rivales únicos (nombre de trabajo)

Fuente de verdad del diseño de este juego. Marcas:
- [DECIDIDO] lo decidió el humano.
- [PROPUESTA] lo sugirió Claude y no está confirmado.
- [ABIERTO] sin decidir. Se pregunta; Claude no decide.

Todos los números son sugerencias y viven como `@export` o en un Resource, para ajustarlos desde el inspector.

---

## 1. Concepto y pilares

- [DECIDIDO] Arcade de tenis en vista vertical (rival arriba, jugador abajo), rápido y difícil, pensado como juego reto que la gente streamea y se intenta ventilar en directo.
- [DECIDIDO] Estructura tipo *Punch-Out!!*: cada rival es un jefe con carisma, truco propio y comportamiento que cambia durante el partido. Sin roguelike.
- [DECIDIDO] Un solo personaje jugable (personalizable en lo básico).
- [DECIDIDO] Precio objetivo: 2,99 € en itch.io, 4,99 € en Steam. Juego corto: 2 torneos en la versión completa.
- [DECIDIDO] Lo más importante es que la jugabilidad sea buena. Si pegar a la bola no es adictivo, el resto da igual.
- [DECIDIDO] Rivales difíciles, cada uno más que el anterior, carismáticos y odiosos.

Pilares de diseño:
1. **Pegar tiene que sentirse de lujo** (potencia visible, hitstop, sacudida, sonido).
2. **Difícil pero justo.** Todo truco del rival tiene un aviso legible. Lo que mata al jugador es no leer, no una trampa.
3. **Riesgo/recompensa en la posición.** Adelantarse da poder (parry) pero castiga (knockup). Quedarse atrás es seguro pero débil.
4. **Cada rival se explica en una frase** y cambia de comportamiento según el marcador.

## 2. Alcance de la prueba

- [DECIDIDO] 1 torneo (**Copa Pueblo**), 3 rivales, partidos a 11 puntos.
- [DECIDIDO] Objetivo: comprobar si el juego mola. No es el juego completo.
- [PROPUESTA] Criterios de éxito de la prueba:
  - Un jugador que no conoce el juego quiere "un punto más" tras 10 minutos.
  - Un partido contra el primo se entiende sin explicaciones y los fallos se sienten míos, no del juego.
  - Un streamer espectador sigue la acción sin confundirse sobre qué bola es la real.
  - Los rivales se sienten distintos entre sí a los 2 minutos de partido.
- [PROPUESTA] **Fuera de la prueba:** 2º torneo, personalización más allá de cosmética, árbitro con diseño final y voz, sala de entrenamiento con máquina de bolas (muy recomendada, ver §16), replay, multijugador.

## 3. Cámara, pista y presentación

- [DECIDIDO] Vista vertical: rival arriba, jugador abajo. Referencia de flow: Mario Tennis, Wii Sports Tennis.
- [DECIDIDO] Público a los lados y detrás del rival (según la pista). Árbitro en la red que hace de comentarista, siempre el mismo y con carisma.
- [DECIDIDO] Se quiere un juego 2D pero **no plano**: con otro ángulo (2.5D), y una **zona jugable más grande**.
- [ABIERTO] **Cámara: plana (A) o 2.5D en perspectiva (B).** Ambas están implementadas para compararlas (ramas `fase-0-bola` y `fase-0-bola-25d`). La lógica es la misma: solo cambia cómo se proyecta a pantalla (`Pista.proyectar`). Con B, el rival (lejos) se ve pequeño y estrecho y el jugador (cerca) grande. La perspectiva sale de 4 marcadores en pantalla, para alinearlos con una pista dibujada a mano.
- [PROPUESTA] Cámara fija, sin zoom dinámico salvo efectos puntuales (especial, punto decisivo).
- [PROPUESTA] La pista, las gradas y el árbitro van como **escenas `.tscn` editables** (piezas sueltas: Polygon2D / Sprite2D), para que tú las muevas y dibujes sin tocar código.
- [ABIERTO] Estilo gráfico. Se dijo "tipo Game Boy modernizado", pero **no es eso**: no se busca pixel art de 4 tonos. Pendiente de definir (2D dibujado a mano con ángulo 2.5D).
- [PROPUESTA] Resolución base **640×360** con escalado suave (`canvas_items`), no entero: ya no se busca pixel art estricto. Es el punto medio entre detalle y trabajo de dibujo (personajes de ~55-65 px). 960×540 da más detalle, pero cada sprite cuesta mucho más de dibujar.
- [PROPUESTA] En 2.5D los sprites se **escalan con la profundidad** (más pequeños lejos). Con arte dibujado en alta resolución se ve bien. Con pixel art estricto el escalado no entero queda mal: habría que dibujar tamaños fijos o quitar la perspectiva.
- [ABIERTO] Resolución definitiva, depende de cuánto arte quieras dibujar y del estilo final.

### Información de la bola

- [DECIDIDO] Se muestra visualmente dónde va a caer la bola o su trayectoria. Hay que elegir una de las dos.
- [PROPUESTA] **Marcador de caída** (círculo en el suelo donde botará), más la sombra de la bola para leer altura. La trayectoria completa queda como opción de accesibilidad.
  - El marcador aparece con un pequeño retraso tras el golpe rival (~0,1-0,15 s) para que haya que leer algo.
  - **Regla de oro: "la sombra no miente".** Solo la bola real proyecta sombra y marcador. Los señuelos (espejismo del rival) no los tienen, y eso es lo que permite jugar contra ellos de forma justa.
- [ABIERTO] ¿Marcador siempre activo o desactivable para el modo difícil?

## 4. Modelo físico (lógica separada de lo visual)

- [PROPUESTA] La bola se simula en coordenadas lógicas (x, y, z). La vista las proyecta a 2D con `posición_vista = (x, y − z·k)` y dibuja la sombra en (x, y).
- [PROPUESTA] Trayectoria **analítica** (parábola + rebote con coeficientes `@export`), no física de motor. Así el marcador de caída es exacto y la IA puede predecir.
- [PROPUESTA] Paso de tiempo fijo, para que el feel sea reproducible y las ventanas de golpe sean justas.
- [PROPUESTA] Cada bola lleva una **potencia 0–1** además de su velocidad. La potencia gobierna color, sacudida, empuje y knockup (ver §12).

## 5. Controles

- [DECIDIDO] El input son órdenes del Input Map, nunca teclas concretas.
- [PROPUESTA] Acciones: `mover` (stick/WASD), `golpear`, `globo`, `dash`, `plancha`, `especial`. Teclado y mando desde el día 1.
- [PROPUESTA] La **dirección** del golpe sale del stick en el momento del contacto: izquierda/derecha para colocar; delante para profundo y potente, atrás para dejada (bola corta).
- [DECIDIDO] **Globo con botón propio** (`globo`). Sirve contra rivales pegados a la red (la madre buscando parry, el ninja de la vieja gloria), que de otro modo solo se pasan por los lados.
- [PROPUESTA] El globo es un golpe alto y lento (tiempo de vuelo largo, potencia baja). Da tiempo al rival para recolocarse, así que no es gratis. La dirección sale del stick como en el golpe normal.
- [PROPUESTA] Sobre el golpe de la bola: tipo de golpe (normal, globo, dejada...) es un dato de la bola (`TipoGolpe`) y no código aparte, para que la física y la IA los traten igual.

## 6. Movimientos del jugador

### 6.1 Movimiento normal
- [DECIDIDO] Movimiento por la pista, normal.
- [PROPUESTA] Aceleración corta y casi inmediata (arcade), con frenada limpia.

### 6.2 Golpe
- [PROPUESTA] El golpe tiene **arranque, fotogramas activos y recuperación**. La bola se golpea si está en el radio de contacto durante los fotogramas activos.
- [PROPUESTA] **Golpe perfecto** = contacto en el punto ideal de la ventana (±60 ms). Da +15 % de velocidad, hitstop, destello y **carga la barra del especial**.
- [PROPUESTA] Golpear pronto o tarde da un golpe débil y poco dirigido.

### 6.3 Dash rodando
- [DECIDIDO] Movimiento corto y rápido, el personaje se levanta al instante. Sirve para reposicionarse, llegar antes a una bola o cuando vas despostado.
- [PROPUESTA] ~0,18 s de duración, distancia de ~2,5 veces el ancho del jugador, cooldown ~1,0 s. No se puede golpear durante el rodar; sí al terminar.

### 6.4 Salto arriesgado (plancha)
- [DECIDIDO] Lanzamiento en plancha para llegar a una bola lejana. Salto largo. Si no llega, el personaje queda tirado 0,5–0,75 s; si da a la bola, ese tiempo se reduce a la mitad.
- [PROPUESTA] Distancia ~2× la del dash. La dirección se fija al pulsar. Contacto automático si la bola pasa por el radio de la plancha durante el vuelo.
- [PROPUESTA] La devolución en plancha es **de emergencia**: alta, lenta, centrada. Da tiempo para recuperarse, pero no gana puntos por sí sola ni carga el especial.

### 6.5 Parry
- [DECIDIDO] Si alcanzas la bola antes de cierto umbral de su trayecto, la devuelves muy rápido, multiplicando su velocidad (sugerido ×1,5).
- [PROPUESTA] Definición espacial: existe una **línea de parry** (sugerido: cerca de la red, a ~35 % de tu mitad). Golpear la bola mientras aún está por delante de esa línea y antes de su rebote = parry.
- [PROPUESTA] El parry no tiene botón propio: sale del golpe normal. Se combina con el golpe perfecto para el máximo premio.
- [PROPUESTA] El parry **también lo hace el rival**, y es lo que hace "duro" a un rival agresivo.
- Efecto buscado: el parry te empuja a adelantarte para ganar puntos rápido. El knockup (§6.7) te castiga por estar delante.

### 6.6 Golpe especial
- [DECIDIDO] Barra de carga que sube con golpes perfectos, atrapadas difíciles y cosas así. Premia jugar perfecto.
- [ABIERTO] **Qué hace el especial.** Opciones:
  - A. **Bola Súper**: el siguiente golpe sale a potencia máxima (rojo total), con knockup si el rival la recibe delante. Solo se puede neutralizar con un golpe perfecto/parry.
  - B. **Tiempo lento** durante unos segundos. Riesgo: trivializa la dificultad.
  - C. **Remate asegurado** si el rival está fuera de posición. Riesgo: quita tensión al partido.
  - Recomendación: **A**, por encajar con el knockup, la escala de rojos y el espectáculo para el stream.
- [PROPUESTA] Ritmo de carga: una barra completa cada 3-5 puntos de juego bueno. Si se llena demasiado rápido, pierde valor.

### 6.7 Empuje y knockup
- [DECIDIDO] Los remates fuertes recibidos hacen **knockup**. Mecánica reutilizable para golpes potentes y especiales.
- [PROPUESTA] Cuanto más potente la bola, más te **empuja** hacia atrás al recibirla. Por encima de un umbral y si la recibes en la zona delantera, es **knockup**: sales volando hacia atrás y quedas aturdido ~0,8 s.
- [PROPUESTA] Un **parry o golpe perfecto sobre una bola potente anula el empuje** (la recibes sin moverte). Es el contrajuego activo.

## 7. Saque

- [DECIDIDO] El saque es un concepto complicado de llevar y hay que resolverlo.
- [PROPUESTA] **Saque en 2 pasos, sin faltas:**
  1. Pulsar `golpear` lanza la bola al aire (~0,6 s).
  2. Pulsar `golpear` otra vez en el pico: la zona perfecta da saque potente y carga barra; pronto o tarde da saque flojo.
  - La dirección sale del stick (izquierda, centro, derecha).
- [PROPUESTA] Sin segundo saque ni "falta": el saque siempre cae dentro. La variedad está en potencia y colocación, y así no se frena el ritmo.
- [PROPUESTA] El jugador tiene reloj de saque (~5 s) para que no bloquee el partido.
- [PROPUESTA] El receptor puede moverse libremente. Los trucos de saque del rival (rápido, retrasado, con finta) tienen su aviso visual.

## 8. Partido

- [DECIDIDO] Partidos a 11 puntos.
- [PROPUESTA] El saque se alterna cada **2 puntos**.
- [ABIERTO] ¿Qué pasa en 10–10? Opciones: ganar por 2 con tope, o **punto de oro** (el siguiente gana). Recomiendo punto de oro: más drama para stream y no alarga partidos de 30 minutos.
- [ABIERTO] ¿Derrota = reintentar el partido (infinitas veces) o hay vidas? Recomiendo reintento infinito con contador de intentos por rival (cosa que se presume en stream).
- [PROPUESTA] Tras cada punto: reacción del rival y comentario del árbitro (texto corto).

## 9. IA y reglas de justicia

- [DECIDIDO] Se quiere una IA compleja y un juego reto.
- [PROPUESTA] La IA no es "inteligencia", son **parámetros por etapa + decisiones con pesos + habilidades especiales**. Es lo más caro del juego y el 80 % del trabajo.
- [PROPUESTA] Estados: esperar, posicionarse, perseguir, golpear, recuperar. Más las acciones de dash, plancha, parry y especial, con los **mismos cooldowns que el jugador**.
- [PROPUESTA] Parámetros por etapa: tiempo de reacción, error de puntería, velocidad, anticipación (cuánto antes lee la trayectoria), agresividad (ir a red, parry), variedad de tiro, potencia máxima, frecuencia de dash/plancha, comportamiento de saque.
- [PROPUESTA] Elección de tiro: zonas con pesos (hueco libre, línea, cuerpo, dejada). El error es **sistemático y entendible por etapa**, no ruido aleatorio puro.

Reglas de justicia (innegociables para un juego difícil que se streamea):
1. La IA no lee el input del jugador, solo ve lo que se ve en pantalla.
2. Mismas reglas físicas y cooldowns que el jugador.
3. **Todo truco tiene un aviso (tell) de al menos ~0,2 s**, visual o sonoro. Sin aviso es injusto.
4. La sombra y el marcador no mienten (§3).
5. Toda **zona** tiene contrajuego y una ventana de castigo al terminar.

### Zona
- [DECIDIDO] "La zona" es el nombre de las habilidades/eventos especiales de los rivales en determinado momento.
- [PROPUESTA] Una zona es una secuencia de N golpes con reglas modificadas, con aviso al empezar (tinte de pantalla, sonido, pose del rival) y una **ventana de castigo** al terminar (el rival queda agotado 1 punto, por ejemplo).

## 10. Rivales de la Copa Pueblo

- [DECIDIDO] Dificultad creciente, cada uno más difícil que el anterior, con carisma y siendo odiosos.
- [DECIDIDO] Cada rival cambia de comportamiento según el marcador.
- [PROPUESTA] Los **disparadores** se miden con los puntos del jugador (cuanto más cerca de ganar, más difícil se pone). Los números exactos son datos editables.
- [ABIERTO] **Discrepancia:** has dicho "todos tienen 2 fases y el del final del torneo 3", pero las descripciones de los tres rivales tienen **3 etapas** cada uno (inicio + 2 cambios). Lo he montado como lista libre de etapas por rival (datos). Falta que decidas cuántas tiene cada uno.

### 10.1 Tu primo (tutorial)
- Juega normal. Enseña las bases sin ser fácil.

| Etapa | Cuándo | Comportamiento |
|---|---|---|
| 1 | Inicio | Juego normal. |
| 2 | Al superar 5 puntos (→ 6) | Saques más fuertes, más parries y movimientos de los que ya conoces. |
| 3 | Te quedan 2 puntos (→ 9) | Se mueve más rápido, hace todo más inteligente e impredecible. |

### 10.2 Madre divorciada

| Etapa | Cuándo | Comportamiento |
|---|---|---|
| 1 | Hasta 5 | Juega incluso peor que el primo. De vez en cuando, un golpe más potente y rápido. |
| 2 | Al superar 5 (→ 6) | Se mueve a toda velocidad y busca el parry constantemente. |
| 3 | A los 8 | Saque fortísimo + **la zona**: secuencia de 4-6 golpes en la que llega al 90 % de tus bolas (hay que tirarla "loquísima" para pararla) y lanza bolones que te mandan al fondo de la pista. Si los recibes por delante, **knockup** hacia atrás. |

- [PROPUESTA] Aviso: tinte de pantalla y pose. Contrajuego: golpes extremos a la esquina, dejadas, parry/golpe perfecto que anula el empuje. Ventana de castigo: queda agotada 1 punto al terminar.

### 10.3 Vieja gloria (final del torneo)
- Paisano calvito pillo, "cuerpo de acabado". Se mueve poco pero se coloca y juega genial, muy inteligente. Trucos: saque más rápido de lo esperado, tardar en sacar, fintar el lado y los tiempos. Partido largo y duro.

| Etapa | Cuándo | Comportamiento |
|---|---|---|
| 1 | Hasta 4 | Trucos de saque y finta de lado, colocación perfecta. |
| 2 | A los 5 | +5 % a todas sus stats. Cada 3 bolas que te manda: la **1ª** golpe con **delay**, la **2ª** normal, la **3ª** con **espejismo** hacia el otro lado. |
| 3 | A los 7 | Se le nota enfadado, se mueve más rápido. **Mega secuencia de 4:** 1 delay, 2 finta de ninja hacia delante para golpear antes de lo esperado, 3 espejismo de 2 bolas, 4 espejismo de 3 bolas. |

- [ABIERTO] "Los últimos 3 puntos" (que mencionaste para el final) y "a los 7" no coinciden. Lo dejé en 7. ¿Cuál vale?
- [PROPUESTA] **Delay**: la bola se frena en el aire ~0,3 s y luego sigue. Aviso: parpadeo de la bola.
- [PROPUESTA] **Espejismo**: aparecen 2-3 bolas durante ~0,3 s. Solo la real tiene sombra y marcador; las demás se desvanecen. Se juega con la regla "la sombra no miente".
- [PROPUESTA] **Avance ninja**: el rival da un paso adelante antes del golpe. Aviso: pose y sonido.

## 11. Personalización

- [DECIDIDO] Habrá personalización básica del personaje para que el jugador se sienta involucrado.
- [DECIDIDO] Parte del juego son variables del jugador: cómo decides moverte, jugar, y "tu mente".
- [PROPUESTA] En la prueba, solo **cosmética por capas** (peinado, color de camiseta, raqueta, muñequera) con un Resource de apariencia. El resto, cuando el feel esté validado.
- [PROPUESTA] Después: 3 **estilos de juego** como presets de datos (agresivo, equilibrado, defensivo) y 1 pasiva de "mente" (por ejemplo, ver el marcador antes). Riesgo: cada preset multiplica el equilibrio de los rivales.

## 12. Estilo visual y game feel

- [DECIDIDO] Todo el arte lo dibuja el humano. Mientras tanto, programmer art con formas. (El estilo Game Boy se descartó, ver §3.)
- [DECIDIDO] Se debe notar mucho cuando se da fuerte, se coge una bola difícil, o lo hace el enemigo.
- [DECIDIDO] Graduación de rojos según la potencia de la bola, barras con buen aspecto, game feel potente (sacudidas, colores, efectos de movimiento, polvo, buenas animaciones).
- [PROPUESTA] Paleta base por pista (no estrictamente reducida) y una **rampa de rojos de 5 pasos** reservada para la potencia. La bola siempre con máximo contraste y borde.
- [PROPUESTA] Niveles de potencia: normal, fuerte, muy fuerte, brutal, especial. La rampa es un Resource editable.
- [PROPUESTA] Catálogo de feedback: hitstop (60-90 ms perfecto, ~120 ms especial), sacudida proporcional a la potencia, destello, estela de la bola, polvo al rodar y al frenar, squash & stretch, texto flotante ("PERFECTO", "PARRY", "KNOCKUP"), tinte de pantalla en la zona, cambio de música.
- [PROPUESTA] Retrato de reacción del rival a cada punto (una viñeta grande, arte barato con mucha personalidad).

## 13. Árbitro y audio

- [DECIDIDO] Árbitro en la red, siempre el mismo, comentarista con carisma. Se diseñará más adelante.
- [PROPUESTA] En la prueba, un placeholder con burbujas de texto. Lo sustituye el diseño final.
- [PROPUESTA] Música y sonido propios o con licencia limpia (importante para streamers: nada de copyright).

## 14. Pensado para streamers

- [PROPUESTA] Contador de intentos por rival y tiempo de partido.
- [PROPUESTA] Estadísticas al acabar: golpes perfectos, parries, planchas, bolas leídas.
- [PROPUESTA] Cámara y UI legibles a baja calidad de vídeo (contraste alto, textos grandes).
- [PROPUESTA, tras la prueba] Replay del último punto, modo "Pesadilla" (el rival empieza en su última etapa), sala de entrenamiento.

## 15. Arquitectura técnica (Godot 4.7.2)

- Solo GDScript tipado, escenas `.tscn`, resources `.tres`, renderer Compatibility.
- Carpetas: `scripts/jugador`, `scripts/mundo` (pista, bola, partido), `scripts/enemigos`, `scripts/efectos`, `scripts/datos`, `data/`, `scenes/`.
- [PROPUESTA] Escenas principales editables: `Pista.tscn`, `Jugador.tscn`, `Rival.tscn` (base), `Bola.tscn`, `HUD.tscn`, `Partido.tscn`.
- [PROPUESTA] **Rival como datos:** `Rival.tres` con id, nombre, stats base y una lista de `EtapaRival` (disparador de marcador, sobreescritura de stats, quirks activos).
- [PROPUESTA] **Quirks reutilizables:** habilidades como componentes (`saque_fuerte`, `buscar_parry`, `zona_cobertura`, `bola_delay`, `bola_espejismo`, `avance_ninja`, `saque_retrasado`). Con ~12 quirks combinados salen los 3 rivales de ahora y los siguientes, sin código por rival.
- [PROPUESTA] La lógica emite eventos (golpe perfecto, parry, punto, knockup) y los efectos y el HUD se suscriben. Nunca al revés.
- [PROPUESTA] El jugador es un nodo con lista de jugadores, no un singleton (por si algún día hay versus).

## 16. Hoja de ruta de la prueba

Una rama por fase, un commit por tarea. No se avanza hasta que la fase sea divertida.

0. **Bola y pista:** pista, bola con altura y rebote, sombra, marcador de caída, cámara. Se ve y se entiende.
1. **Golpe:** jugador, movimiento, golpe con ventana, perfecto, dirección/profundidad, hitstop y sacudida. Contra una máquina de bolas. **Criterio: ¿pegar engancha?**
2. **Movilidad:** dash, plancha, parry, empuje/knockup, especial.
3. **Partido:** marcador, saque, IA base (el primo, etapa 1), árbitro placeholder.
4. **Rivales:** etapas, quirks, el primo completo, la madre, la vieja gloria.
5. **Feel y presentación:** rampa de rojos, polvo, retratos, árbitro, audio.
6. **Pulido de la prueba:** equilibrio de dificultad, menús, cosmética, build.

## 17. Riesgos

- **Feel:** todo depende de la fase 1. Si no engancha, no se sigue.
- **IA:** es lo más caro. Una IA "injusta" mata el juego en directo.
- **Legibilidad:** bola pequeña, mucha acción, trucos con señuelos. La regla "la sombra no miente" es lo que lo hace jugable.
- **Botones:** 6 acciones (golpear, globo, dash, plancha, especial y mover) son muchas para enseñar sin tutorial. Hace falta sala de entrenamiento.
- **Arte:** 3 rivales dibujados a mano. Definir de antemano cuántas poses por rival.

## 18. Puntos [ABIERTOS] resumidos

1. Qué hace el golpe especial (A/B/C).
2. (Resuelto: globo con botón propio.)
3. Número real de etapas por rival (2 vs 3).
4. Último tramo de la vieja gloria: "a los 7" o "últimos 3 puntos".
5. 10–10: punto de oro o ganar por 2.
6. Derrota: reintento infinito o vidas.
7. Marcador de caída: siempre o desactivable.
8. Cámara plana (A) o 2.5D (B), estilo gráfico definitivo y resolución (640×360 propuesta).
9. Título del juego.
