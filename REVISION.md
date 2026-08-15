# Revisión técnica — RaffleFlutter

Fecha: 2026-08-08 · Rama: `BsgaFix` · Versión: `1.0.5+7`

> **Estado tras la implementación (solo app Flutter; el landing no se tocó)**
>
> Aplicado: A, B, C, D (parcial), E, F, G, H, J, K, L, más la limpieza completa
> de la sección 2. `flutter analyze` pasó de **217 a 7 issues**, 0 errores, y
> `flutter test` corre 2 pruebas en verde.
>
> Corrección al informe: el punto C afectaba solo a `ticket_grid.dart`.
> `raffle_list_page.dart:150` ya tenía la guarda `totalPages <= 1`.
>
> Pendiente a propósito: el punto I (`WinnerSelected`) y las subidas de major
> de la sección 4. Los 6 issues restantes son deprecaciones de
> `Radio`/`RadioGroup` (Flutter 3.32+) y `showLabel` de `qr_flutter`, que
> piden refactor de API.

> **Segunda fase: rediseño de la base de datos**
>
> Con la app aún sin publicar se rehízo el esquema desde cero en vez de
> migrarlo. Ver la sección 6.

---

## 6. Esquema nuevo (segunda fase)

Una sola base `raffle_app.db` en `lib/core/db/app_database.dart`, versión 1,
que borra los tres archivos antiguos en el primer arranque.

**Integridad**

- Cuatro tablas en un archivo, una conexión, `PRAGMA foreign_keys = ON`.
  `participants` cuelga de `giveaways` y `tickets` de `raffles`, ambas con
  `ON DELETE CASCADE`: la cascada la hace la base, ya no Dart.
- `snake_case` en todas las columnas (antes rifas y sorteos usaban
  convenciones distintas).
- `CHECK` en los enums: `raffles.status IN ('active','inactive','expired')`,
  `game_type IN ('app','lottery')`, `tickets.status IN
  ('available','reserved','sold')`, `giveaways.status IN
  ('pending','completed','cancelled')`, booleanos restringidos a 0/1.
- `UNIQUE (raffle_id, number)`: no puede haber dos boletos con el mismo número
  en una rifa.
- Fechas en **UTC** (`DateTime.toDbString()` / `parseDbDate`). Antes se
  guardaba hora local sin zona y ordenar por `created_at` fallaba al cambiar
  el huso.

**Dinero**

`price REAL` pasó a `price_minor INTEGER`. Toda la aritmética es entera y la
conversión a decimal ocurre solo al formatear, en `lib/core/money/money.dart`.
De paso se unificó el formato: `raffle_share_page` usaba locale `es_MX` y el
resto `es`.

**Escalabilidad**

El listado ya no hidrata boletos. `getRaffleSummaries()` devuelve una fila por
rifa con los contadores resueltos por SQLite:

```sql
SELECT r.*,
       COALESCE(SUM(CASE WHEN t.status = 'sold' THEN 1 ELSE 0 END), 0) AS sold_count,
       ...
FROM raffles r LEFT JOIN tickets t ON t.raffle_id = r.id
WHERE r.deleted_at IS NULL
GROUP BY r.id
```

Diez rifas de lotería de cuatro dígitos pasaron de cien mil objetos `Ticket`
en memoria a diez filas. El índice `idx_tickets_raffle_status` resuelve la
agregación sin recorrer la tabla.

**Papelera**

`deleted_at` en `raffles` y `giveaways`. La pestaña Papelera dejó de tener un
único botón que borraba la base entera: ahora lista lo eliminado y permite
restaurar, eliminar definitivamente o vaciar, con confirmación. Vive en su
propio `TrashBloc` porque las dos pestañas coexisten en el `IndexedStack` y
compartir bloc haría que una pisara el estado de la otra.

---

## 7. Tercera fase: todo lo pendiente

`flutter analyze` → **No issues found**. `flutter test` → **37 pruebas en verde**.

### Tests reales de la base

`sqflite_common_ffi` como dependencia de test y el esquema extraído a
`AppSchema`, separado de dónde vive el archivo. Los datasources reciben un
`DatabaseProvider` inyectable, así que los tests abren la base **en memoria con
el mismo esquema que producción**. 24 pruebas cubren cascada de claves
foráneas, rechazo de estados y precios inválidos, `UNIQUE(raffle_id, number)`,
agregados, fechas en UTC, búsqueda con comodines escapados, paginación,
papelera, purga y sorteo aleatorio.

Esto cierra el hueco que quedaba: el esquema ya no es teoría, se ejecuta.

### Paginación de verdad

- **Grid de boletos**: `LIMIT/OFFSET` desde el bloc. El detalle carga 100
  boletos, no 10 000. `RaffleDetailsLoaded` lleva `Paged<Ticket>` más los
  contadores.
- **Listado**: búsqueda, filtro de estado y paginación en SQL, con *debounce*
  de 300 ms (`stream_transform` + `bloc_concurrency`) para no lanzar una
  consulta por tecla y descartar las obsoletas.
- **Comodines escapados**: buscar `%` ya no devuelve la base entera.
- Compradores y exportación piden solo lo suyo (`getTicketsWithBuyers`,
  `getAllTickets`), en vez de recibir la lista completa desde la pantalla.

Un fallo que salió al paginar: `_selectRandomTicket` sorteaba entre
`widget.tickets`, que con paginación habría sido **solo la página visible**.
Ahora lo sortea SQLite con `ORDER BY RANDOM() LIMIT 1` sobre todos los
disponibles, y hay un test que lo comprueba con el boleto ganador fuera de la
primera página.

### Resto

- `deleted_at` con purga automática a los 30 días, disparada al arrancar
  (`PurgeExpiredTrash`). Si falla, no rompe la pantalla.
- `WinnerSelected` estaba declarado en el archivo de *eventos* y se emitía
  seguido de una recarga que lo reemplazaba. Ahora extiende `ParticipantLoaded`
  y trae la lista ya actualizada: un solo estado, sin parpadeo.
  (Matiz sobre el punto I: la pantalla usaba `BlocListener`, así que el diálogo
  del ganador **sí** se veía. El problema era de diseño, no visible.)
- `Radio.groupValue/onChanged` → `RadioGroup`; `showLabel` eliminado.
- `TicketDao` desaparece: el repositorio habla directo con el datasource.

---

## 8. Cuarta fase: build de Android y cierre

`flutter analyze` → **No issues found**. `flutter test` → **47 pruebas**.
`flutter build apk --debug` → **APK generado**.

### El build de Android estaba roto

Al intentar correr la app: `Your project's Gradle version (8.3.0) is lower than
Flutter's minimum supported version of 8.7.0`. La cadena Android se había
quedado muy por detrás de Flutter 3.44.4:

| | Antes | Ahora |
|---|---|---|
| Gradle | 8.3 | 8.14.3 |
| Android Gradle Plugin | 8.1.0 | 8.11.1 |
| Kotlin | 1.8.22 | 2.2.20 |
| Java (source/target) | 8 | 11 |
| compileSdk | 35 | 36 |

Se hizo en dos tandas: la primera dejó el build pasando pero Flutter seguía
avisando de que esas versiones "se dejarán de soportar pronto" (pedía Gradle
≥ 8.14, AGP ≥ 8.11.1, Kotlin ≥ 2.2.20) y de que `share_plus` compila contra
SDK 36. La segunda subió todo eso. **Cero avisos de Flutter en el build.**

`compileSdk` sube a 36 porque lo exige `share_plus`; `targetSdk` se queda en 35
a propósito: subirlo activa los cambios de comportamiento de Android 16, que
hay que probar en pantalla y no solo compilar.

### Built-in Kotlin: probado y revertido

Flutter avisa de que aplicar el Kotlin Gradle Plugin a mano "*causará fallos de
build en versiones futuras*" y recomienda migrar a `android.builtInKotlin`. Se
hizo la migración y **hoy rompe el build**: el Kotlin que Flutter trae integrado
es más antiguo que el que exige `share_plus`, y `:share_plus:compileDebugKotlin`
falla con "*Your project requires a newer version of the Kotlin Gradle plugin*".

Se revirtió y se mantiene el KGP explícito en 2.2.20, con la razón anotada en
`gradle.properties`. Hay que rehacerlo cuando la versión integrada alcance a los
plugins.

Además, en `app/build.gradle`:

- `minSdk` y `targetSdk` pasan a ser explícitos (24 / 35) en vez de heredarse
  de Flutter. Play exige un `targetSdk` concreto y así el build no cambia solo
  al actualizar el SDK.
- La firma de release solo se declara si existe `key.properties`; antes Gradle
  fallaba con un `storeFile` nulo en cualquier máquina sin credenciales.

Y en el manifiesto: `WRITE/READ_EXTERNAL_STORAGE` acotados con `maxSdkVersion`
(29 y 32), y `android:label` de `raffle` a `Raffle`, alineado con iOS.

### Dependencias al día

`flutter_bloc` 8→9, `bloc_concurrency` 0.2→0.3, `share_plus` 7→13,
`flutter_lints` 4→6, `equatable` 2.0→2.1, `permission_handler` a 12.0.3. Se
quitó el pin manual de `permission_handler_android`, que solo servía para
desincronizarse de su paquete padre.

**`permission_handler` se queda en la 12 a propósito.** Se probó la 13 y el
build falló con `Failed to find Platform SDK with path: platforms;android-37`:
esa versión compila contra el Android SDK platform 37, lo que obligaría a subir
`compileSdk` y AGP a cambio de ninguna funcionalidad nueva. Queda anotado como
deuda para cuando toque subir `compileSdk`.

`share_plus` 13 deja obsoleta la clase `Share`: las cinco llamadas pasan a
`SharePlus.instance.share(ShareParams(...))`.

### Tests de blocs

10 pruebas nuevas de `RaffleBloc` y `TrashBloc`, contra el repositorio real
sobre SQLite en memoria en vez de con dobles: así se comprueba también que la
consulta hace lo que se espera. Cubren creación, búsqueda, filtro por estado,
paginación, papelera y purga. Una verifica que el *debounce* descarta los
términos intermedios y solo consulta el final.

### Mutación durante el build, resuelta

`_buildPagination` recibe la página por parámetro y el listado ya no copia
`_pageData` ni `_isFiltered` en campos durante el `build`. Solo queda
`_statusFilter`, que el chip necesita para saber cuál está marcado antes de
que llegue la respuesta.

---

## 9. Prueba en dispositivo (SM M315F)

### Regresión encontrada y corregida: heroTag duplicado

Al ejecutar en el dispositivo, la app se detenía por excepción al pulsar Crear
y al abrir una rifa:

```
There are multiple heroes that share the same tag within a subtree.
In this case, multiple heroes had the following tag: <default FloatingActionButton tag>
  at HeroController._startHeroTransition
```

**La introduje yo** al pasar `main_layout` a `IndexedStack`: las pestañas Rifas
y Sorteos pasan a construirse a la vez, así que hay dos `FloatingActionButton`
montados y ambos usaban el `heroTag` por defecto. La assertion se lanza al
animar una transición de ruta, es decir justo al navegar.

El síntoma de "Creando…" que se quedaba colgado era **la misma causa**: la
excepción rompía la animación de `Navigator.pop` y la pantalla de creación no
se cerraba. Corregido con `heroTag: 'raffles-fab'` y `'giveaways-fab'`.

### La capa de datos salió limpia

Se extrajo la base del dispositivo para comprobarlo: 3 rifas y 10 200 boletos,
con la numeración correcta (0-99, 0-99 y **0-9999** en la de cuatro dígitos).
Cero errores de SQLite en todo el log. La escritura nunca falló; lo único roto
era la navegación.

Tras el arreglo: **0 excepciones** abriendo rifas y entrando a crear, y el
listado pinta bien los contadores agregados (2.0 % vendido sobre 100 boletos).

## 10. Compartir la boleta tras cambiar su estado

Al marcar un boleto como vendido o reservado, el modal se cerraba. Ahora se
queda abierto y salta a la pestaña **Vista Previa** con el estado ya
actualizado, para poder mandarle la boleta al comprador sin volver a buscarla.

Para eso `TicketInfoModal` guarda el ticket modificado en `_ticket` y la vista
previa lee de ahí en vez de `widget.ticket`, que conserva el valor con el que
se abrió el modal.

### Lo que sigue pendiente

- **Nadie ha usado la app todavía.** Compila y los tests pasan, pero los flujos
  reales (crear una rifa, compartir, exportar a PDF/Excel, permisos de galería)
  no se han ejercitado en un dispositivo.
- Sin tests de widgets más allá de `FinancialSummary` y `TicketCounts`; las
  pantallas grandes (`raffle_list_page`, `raffle_details_page`,
  `raffle_share_page`) no tienen cobertura.
- `raffle_share_page.dart` (848 líneas) y `ticket_modal.dart` (1099) siguen
  siendo demasiado grandes, con colores en crudo en vez de `AppColors`.
- La feature de sorteos (`giveaways`) no recibió el mismo repaso que rifas: no
  tiene paginación ni tests propios.

## 0. Qué hay en el repo

| Parte | Estado |
|---|---|
| **App Flutter** (`lib/`, 81 archivos Dart) | Clean Architecture parcial, Bloc, SQLite. 2 features: `raffles` y `giveaways`. |
| **Landing Next.js** (`landing/`) | Next 14 + Tailwind + framer-motion. Trabajo más reciente (Dockerfile, PhoneMockup3D, Footer). |
| **Tests** | 1 solo archivo: `test/widget_test.dart`, es la plantilla por defecto de Flutter y **no compila** (referencia un contador que no existe). Cobertura real: 0%. |
| **Analyzer** | 0 errores de compilación, **217 issues** (144 deprecaciones, 46 const, 7 async-context). |

Nota de entorno: el proyecto venía sin `.dart_tool/` resuelto (había un `.dart_tool.zip` de 29 MB versionado). Ejecuté `flutter pub get` para poder analizar; eso actualizó 9 dependencias transitivas en `pubspec.lock`.

---

## 1. Errores lógicos (por severidad)

### 🔴 A. Los tickets quedan huérfanos al borrar una rifa

`raffle_local_datasource.dart:227` borra solo la fila de `raffles`. El esquema declara
`FOREIGN KEY (raffle_id) REFERENCES raffles(id) ON DELETE CASCADE`, **pero sqflite no activa
`PRAGMA foreign_keys = ON` por defecto**, así que el CASCADE nunca se ejecuta.

Peor: `TicketDao.deleteTicketsByRaffle()` (`ticket_dao.dart:30`) **no borra nada** — recorre los
tickets y los marca como `available`. El nombre miente sobre lo que hace, y además ni siquiera se
llama desde `deleteRaffleAndTickets()`.

**Consecuencia:** cada rifa borrada deja sus N tickets (hasta 10.000 en lotería de 4 dígitos) en la
tabla para siempre. La BD crece sin límite.

**Fix:** añadir `onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON')` en `openDatabase`, y
borrar rifa + tickets dentro de una transacción.

---

### 🔴 B. `FinancialSummary` revienta con `totalTickets = 0`

`financial_summary.dart:39-42` divide entre `raffle.totalTickets` sin guarda:

```dart
final totalTickets = raffle.totalTickets.toDouble();
final percentSold = sold / totalTickets;   // 0/0 = NaN
```

Luego `_progressSegment` hace `Expanded(flex: (percent * 1000).round())` → `NaN.round()` lanza
`UnsupportedError` y la pantalla queda en rojo.

Se puede llegar a `totalTickets = 0` porque el validador de `raffle_create_page.dart:277` solo
comprueba `int.tryParse(value) == null` — acepta `0` y también negativos.

Con negativos el crash es antes: `raffle_bloc.dart:41` hace `List.generate(event.totalTickets, ...)`
→ `RangeError`.

Ojo: `raffle_list_page.dart:346` **sí** tiene la guarda `totalTickets == 0 ? 0 : ...`. Es el mismo
cálculo resuelto de dos formas distintas en dos archivos.

**Fix:** validar `> 0` (y un máximo razonable) en el formulario, y añadir la guarda en
`FinancialSummary`.

---

### 🔴 C. `DropdownButton` con lista vacía → assertion

En `ticket_grid.dart:254` y `raffle_list_page.dart:202`:

```dart
DropdownButton<int>(
  value: _currentPage,                         // 0
  items: List.generate(totalPages, ...),       // totalPages == 0 → lista vacía
)
```

Cuando no hay tickets (o el filtro de búsqueda no devuelve resultados), `totalPages` es `0`, la lista
de items queda vacía y `value: 0` no existe en ella → Flutter dispara la assertion
`items.where((item) => item.value == value).length == 1`.

Además el texto muestra `"Página 1 de 0"`.

**Fix:** no renderizar la paginación si `totalPages <= 1`.

---

### 🟠 D. Tres bases de datos separadas, una con el nombre mal escrito

| Datasource | Archivo `.db` |
|---|---|
| `RaffleLocalDatasource` | `raffle.db` |
| `GiveawayLocalDatasource` | `giveaway.db` |
| `ParticipantLocalDatasource` | **`gateway.db`** ← typo de `giveaway` |

Los participantes viven en un archivo distinto al de los sorteos a los que pertenecen, así que la
integridad referencial entre `giveaways` y `participants` es imposible por diseño. Borrar un sorteo
(`giveaway_local_datasource.dart:78`) deja todos sus participantes vivos en la otra BD.

**Fix:** unificar en una sola BD con `PRAGMA foreign_keys = ON`. Requiere migración — ver punto E.

---

### 🟠 E. Las tres BD están en `version: 1` sin `onUpgrade`

Ningún `openDatabase` define `onUpgrade`. En cuanto haya que añadir una columna a una app ya
instalada, no hay camino: o se pierde la data del usuario o hay que hacer una migración manual de
emergencia. El comentario `award TEXT, -- NUEVO` en `participant_local_datasource.dart:37` sugiere
que ya se añadió una columna al `onCreate` — los usuarios que instalaron antes de ese cambio no la
tienen y sus queries fallan.

---

### 🟠 F. El formato del número de lotería se pierde al guardar

`raffle_bloc.dart:44-50`:

```dart
number = i.toString().padLeft(event.digitCount, '0');  // "007"
...
number: int.parse(number),                             // → 7
```

Se rellena con ceros y acto seguido se parsea a `int`, descartando el relleno. La columna es
`INTEGER`, así que el padding nunca llega a la BD. Funciona solo porque `ticket_grid.dart:49`
vuelve a hacer `padLeft` al pintar — pero cualquier consumidor que no repita ese paso (export a
PDF/Excel, share) mostrará `7` en vez de `007`.

Incoherencia adicional: los tickets de lotería empiezan en `0` y los de app en `1`.

---

### 🟠 G. Insertar 10.000 tickets uno por uno

`ticket_dao.dart:44` hace un `db.insert` por ticket dentro de un `for`. Una lotería de 4 dígitos son
**10.000 transacciones individuales** — varios segundos de bloqueo, sin indicador de progreso.

**Fix:** `db.batch()` dentro de una transacción.

---

### 🟠 H. Crear rifa es "fire and forget"

`raffle_create_page.dart:322-335` despacha `CreateRaffle` y llama a `Navigator.pop(context)` en la
línea siguiente, sin esperar. Si la creación falla, el Bloc emite `RaffleError` pero la página ya no
existe: **el usuario nunca ve el error** y cree que la rifa se creó.

---

### 🟡 I. `WinnerSelected` se pisa a sí mismo

`participant_bloc.dart:110-117`: emite `WinnerSelected(winner)` e inmediatamente despacha
`LoadParticipants`, que emite `ParticipantLoading` → `ParticipantLoaded`. Cualquier `BlocBuilder`
que dibuje el ganador lo pierde en el mismo frame. Solo sobrevive si se lee con `BlocListener`.

---

### 🟡 J. La preselección no se respeta al agotarse

`participant_local_datasource.dart:121-138`: si ya no quedan preseleccionados sin ganar, `drawWinner`
cae al pool de **todos** los participantes. Un participante nunca preseleccionado puede ganar. Si es
intencional, hay que documentarlo; si no, es un fallo de reglas de negocio.

Relacionado: `preselectParticipants` resetea `isPreselected` pero no `isWinner`.

---

### 🟡 K. `TicketModel.toMap()` usa claves que la BD no conoce

`ticket_model.dart:33` escribe `buyerName`, `buyerContact`, `raffleId` (camelCase), mientras
`fromMap` lee `buyer_name`, `buyer_contact`, `raffle_id` (snake_case) y esas son las columnas reales.
Hoy no explota porque nadie usa `toMap()` para escribir en SQLite, pero es una mina: el primer
`db.insert('tickets', ticket.toMap())` lanzará `no column named buyerName`.

---

### 🟡 L. 7 usos de `BuildContext` a través de un `await`

`raffle_details_page.dart:360`, `raffle_list_page.dart:36/499/619`,
`raffle_export_button.dart:20/46/50`. Si el widget se desmonta durante el `await`, se accede a un
contexto muerto. Falta el guard `if (!mounted) return;`.

---

## 2. Código muerto / desorden

Archivos **nunca importados** (13):

```
lib/features/raffles/data/datasources/raffle_dao.dart
lib/features/raffles/presentation/pages/raffle_page.dart
lib/features/raffles/presentation/pages/giveaway_page.dart
lib/features/raffles/presentation/widgets/financial_summary copy.dart   ← con espacio en el nombre
lib/features/raffles/presentation/widgets/delete_confirmation_modal.dart
lib/features/raffles/presentation/widgets/raffle_export_button.dart
lib/features/raffles/presentation/widgets/ticket_card_image.dart
lib/features/raffles/presentation/widgets/ticket_edit_modal.dart
lib/features/giveaways/presentation/pages/giveaway_page.dart
lib/features/giveaways/presentation/widgets/giveaway_stats.dart         ← duplicado de *_widget
lib/features/giveaways/presentation/widgets/participant_list.dart       ← duplicado de *_widget
lib/features/giveaways/presentation/widgets/add_participant_button.dart
lib/features/giveaways/presentation/widgets/update_giveaway_status_button.dart
```

Otros:

- **`.dart_tool.zip` (29 MB) versionado** desde 2025-05-10. Es caché de build; `.gitignore` ya
  excluye `.dart_tool/` pero no el `.zip`. Hay que sacarlo del historial.
- `main_layout.dart:19-25` registra 5 páginas y 5 títulos, pero el `BottomNavigationBar` solo expone
  3 items (History y Settings comentados). **`HistoryPage` y `SettingsPage` son inalcanzables.**
- 5 `print()` de depuración en producción (`raffle_details_bloc.dart:36,37,84,85,95` — incluido un
  `print("hola 3")`).
- `test/widget_test.dart` es la plantilla sin tocar y no compila.

---

## 3. Desviaciones de `arquitectura-hexagonal.md`

El propio documento del proyecto define reglas que el código no cumple:

| Regla | Realidad |
|---|---|
| "Manejo de estado exclusivamente con Bloc" | `RaffleDetailsBloc:11` instancia `RaffleLocalDatasource.instance` directamente — la capa de presentación toca la de datos, saltándose el repositorio. |
| Estructura simétrica entre features | `giveaways` tiene `domain/use_cases/`; `raffles` no. Los Bloc de rifas hablan directo al repositorio. |
| "No usar colores hardcodeados" | `financial_summary.dart` está lleno de `Color(0xFF2C2C2E)`, `Colors.white70`, `Colors.black`… sin un solo `AppColors`. |
| "No repetir estilos inline" | `raffle_create_page.dart:344` reimplementa `ElevatedButton.styleFrom` en lugar de usar `ButtonStyles`. |
| Inyección de dependencias | Todo son singletons `static instance` + construcción manual en `main()`. No hay contenedor DI (get_it / injectable). |

---

## 4. Actualizaciones pendientes

**Dependencias con major desactualizado** (69 paquetes tienen versiones más nuevas bloqueadas por
constraints):

| Paquete | Actual | Disponible |
|---|---|---|
| `flutter_bloc` | ^8.1.3 | 9.x |
| `share_plus` | ^7.2.2 | 12.x ← muy atrasado |
| `screenshot` | ^3.0.0 | 4.x |
| `flutter_lints` | ^4.0.0 | 6.x |
| `excel` | ^4.0.2 | 5.x |
| `win32` (transitiva) | 5.10.1 | 6.4.0 |

**APIs deprecadas** (144 avisos): 125 × `withOpacity` (→ `.withValues(alpha:)`), 7 ×
`surfaceVariant` (→ `surfaceContainerHighest`), `MaterialState` (→ `WidgetState`),
`Table.fromTextArray` del paquete `pdf`, y `Radio.groupValue/onChanged` (→ `RadioGroup`).

**Configuración de plataforma:**

- `android/app/build.gradle:33-34` usa `flutter.minSdkVersion` / `flutter.targetSdkVersion` en vez de
  fijarlos. Para publicar en Play hace falta `targetSdk 35` explícito.
- El manifest pide `WRITE_EXTERNAL_STORAGE` y `READ_EXTERNAL_STORAGE` **sin `android:maxSdkVersion="32"`**.
  En Android 13+ no hacen nada y Play las cuestiona en la revisión.
- Nombre de la app inconsistente: `android:label="raffle"` (minúscula) vs `CFBundleDisplayName = "Raffle"`
  en iOS vs `"Raffle Rifas y Sorteos"` en el landing.
- `pubspec.yaml:2` sigue con `description: "A new Flutter project."`.

**Landing:** Next 14 (ya hay 15/16), React 18 (ya hay 19). El `example.env` apunta `LINK_IOS` y
`LINK_ANDROID` a `google.com` — placeholders sin reemplazar.

---

## 5. Qué haría primero

**Bloqueantes de producción** (crashes reales):

1. Guarda de división por cero en `FinancialSummary` + validar `totalTickets > 0` en el formulario.
2. Ocultar la paginación cuando `totalPages <= 1` (dos sitios).
3. `PRAGMA foreign_keys = ON` + borrado transaccional de rifa+tickets.

**Integridad de datos:**

4. Unificar las tres BD en una, corrigiendo el typo `gateway.db`, con `onUpgrade` y migración.
5. `db.batch()` para la inserción masiva de tickets.
6. Alinear `TicketModel.toMap()` con los nombres de columna reales.

**Limpieza (bajo riesgo, alto retorno):**

7. Borrar los 13 archivos muertos y sacar `.dart_tool.zip` del historial de git.
8. Quitar los 5 `print()`; reemplazar por logging condicionado a `kDebugMode`.
9. `dart fix --apply` resuelve automáticamente buena parte de los 217 issues (const, imports sin usar).
10. Decidir sobre History/Settings: exponerlos en el nav o eliminarlos.

**Deuda a planificar:**

11. `flutter_bloc` 9 + `share_plus` 12 + `flutter_lints` 6, y migrar `withOpacity` → `withValues`.
12. Extraer `use_cases` en `raffles` y quitar el acceso directo al datasource desde `RaffleDetailsBloc`.
13. Tests: hoy son 0. Empezar por los datasources y la lógica financiera, que es donde están los bugs.

---

## 7. Revisión "Sortear ganador" (rifas + sorteos)

> **Estado: todo lo de esta sección está aplicado.**
> `flutter analyze` → *No issues found*; `flutter test` → **70 en verde**
> (antes 51). Suites nuevas: `test/db/participant_local_datasource_test.dart`
> y `test/widget/ticket_grid_draw_test.dart`.
>
> Dos matices sobre el diagnóstico original:
>
> - **Preseleccionados.** Apagar `is_preselected` al ganar rompía el sorteo:
>   esa marca es lo que le dice a la ronda siguiente que hubo preselección, y
>   sin ella repescaba a quien nunca entró (lo cazó un test). La base conserva
>   la marca y el contador pasa a mostrar los *pendientes*, vía
>   `Participant.isPendingPreselection`.
> - **Defecto extra encontrado al escribir el test de widget.**
>   `RaffleDetails.props` solo llevaba `raffle.id` y `raffle.updatedAt`, así
>   que el repintado dependía de que la marca de tiempo cambiase. Ahora
>   enumera también `status`, `winningNumber`, `name` e `imagePath`.
>
> Pendiente de decidir por producto: nada. El conjunto del sorteo de rifas
> pasó a "vendidos primero, y si no hay ventas, todos".

`flutter analyze` → **No issues found**. Todo lo de abajo era comportamiento, no
compilación. Aplica igual en Android e iOS salvo donde se indique.

### 🔴 Causa raíz de "no pasa nada visualmente"

`ticket_grid.dart:141` y `:189` despachan el evento con
`context.read<RaffleDetailsBloc>()` usando el **context del diálogo**.
`showDialog` monta con `useRootNavigator: true`, así que ese context cuelga del
Navigator raíz → `MaterialApp` → el `MultiBlocProvider` de `main.dart`, **no**
del provider con ámbito de ruta de `raffle_list_page.dart:255`
(`InheritedTheme.capture` no propaga `BlocProvider`).

El evento llega al `RaffleDetailsBloc` **global** de `main.dart:42`, con
`_raffleId == null` y estado `RaffleDetailsInitial`. En
`raffle_details_bloc.dart:125`:

```dart
if (current is! RaffleDetailsLoaded || raffleId == null) return;  // salida silenciosa
```

Sin escritura en BD, sin error, sin estado nuevo. Coincide con el síntoma: el
diálogo sí muestra el número (`pickRandomAvailableTicket` se llama desde
`ticket_grid.dart:98`, con el context correcto), pero "Confirmar" no hace nada.
Igual para "Reiniciar Sorteo".

**Arreglo:** usar la variable `bloc` ya capturada antes de `showDialog` dentro
del builder (y capturarla también en `_showWinningNumberDialog`); borrar el
`RaffleDetailsBloc` duplicado de `main.dart:42` para que un fallo así lance
`ProviderNotFoundException` en vez de fallar callado; que `_mutate` no salga con
`return` mudo.

### 🟠 "Reiniciar Sorteo" sigue roto aun con lo anterior arreglado

`raffle_local_datasource.dart:332` + `ticket_grid.dart:185`

- `setWinningNumberAndFinishRaffle(id, '')` limpia el número pero **deja
  `status = 'expired'`**. La rifa queda bloqueada: `showRandomButton` exige
  `status == 'active'` (`raffle_details_page.dart:265`).
- El botón solo se pinta `if (widget.raffle.status != 'expired')` — y tras un
  sorteo `app` el estado **es** `expired`: inalcanzable justo cuando hace falta.
- Guarda `''` en vez de `NULL`.

**Arreglo:** `resetDraw(raffleId)` que ponga `winning_number = NULL` y
`status = 'active'` en la misma transacción.

### 🟠 Bloqueo de venta/reserva — parcial

`ticket_info_modal.dart:223`

- Se bloquea por `status == 'expired'`, no por "hay ganador": una rifa
  `lottery` con ganador fijado sigue vendiendo.
- El estado `inactiva` no bloquea nada pese a lo que promete
  `status_modal.dart:333`.
- **Bug aparte, alto:** `status_modal.dart:59` escribe `'inactiva'`, pero el
  `CHECK` es `IN ('active','inactive','expired')` (`app_database.dart:41`).
  Elegir "Inactiva" lanza `DatabaseException`.

**Arreglo:** `bool get isLocked => status != 'active' || winningNumber != null;`
en `Raffle`; corregir `'inactiva'` → `'inactive'`.

### 🟡 El sorteo excluye boletos vendidos

`raffle_local_datasource.dart:213` sortea solo entre `status = 'available'`. En
una rifa real el ganador debería salir de los vendidos, o de todos los números.
Decisión de producto: confirmar antes de tocar.

### Sorteos (giveaways)

- 🔴 **Preseleccionados congelados.** `participant_local_datasource.dart:142`
  marca `is_winner`/`award`/`updated_at` pero **nunca pone `is_preselected = 0`**.
  `GiveawayStatsWidget` cuenta `p.isPreselected` → contador clavado (captura:
  5 / 2 / 4). Arreglo: añadir `'is_preselected': 0` a ese `UPDATE`.
- 🟠 **El estado nunca pasa a "Completado".** `drawWinner` no toca
  `giveaways.status`; hoy solo se cambia a mano por el menú ⋮.
- 🟠 **No existe "reiniciar sorteo"** para giveaways (las rifas sí lo tienen).
- 🟠 **Efecto secundario en `build()`.** `giveaway_details_page.dart:20` despacha
  `LoadParticipants` dentro de `build`: se redispara en cada rebuild → recargas
  en bucle y parpadeo. Debe ser `StatefulWidget` + `initState`.
- 🟠 **Blocs globales sin ámbito.** `ParticipantBloc`/`GiveawayBloc` son
  singletons en `main.dart`; abrir el sorteo B muestra los datos de A hasta que
  responde la consulta. Replicar el patrón por ruta de `raffle_list_page.dart:255`.
- 🔴 **Issue #5 "Editar sorteos": no implementado.** No hay
  `giveaway_edit_page.dart` ni `UpdateGiveawayEvent`; `GiveawayUseCases` solo
  expone crear, cambiar estado, listar, obtener y borrar. Referencia:
  `raffle_edit_page.dart`.

### Menor

- `ticket_modal.dart` nunca se instancia: código muerto.
- `ticket_grid.dart:369` compara con `_formatNumber`, que lee `widget.raffle`
  (posiblemente desactualizado) mientras el resto usa `currentRaffle` del estado.
- El ganador solo se resalta si cae en la página visible; no hay "ir al ganador".
- `giveaway_list_widget.dart:28`: textos en inglés en una app forzada a `es`.
