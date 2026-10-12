# Voxelcost3D — Flutter

Conversión integral del proyecto Android nativo Kotlin/Jetpack Compose a Flutter/Dart, conservando el flujo, estructura funcional, textos, paleta visual y persistencia local del sistema original.

## Funcionalidad migrada

- Inicio de sesión de operador.
- Pantalla principal / centro de control.
- Gestión de impresiones.
- Alta y edición de registros de impresión.
- Múltiples materiales por impresión, color, gramos y opción “Combinar”.
- Historial técnico y eliminación de registros.
- Analítica mensual de consumo y producción.
- Inventario de materiales y colores.
- Catálogos base y elementos personalizados.
- Altas de producto, stock inicial/actual y ajuste ±50 g.
- Filtros, búsqueda y alerta de bajo stock.
- Pantalla de exportación con selección de registros/inventario.
- Persistencia SQLite equivalente a Room mediante `sqflite`.

## Credenciales conservadas

- Usuario: `admin` o `admin@voxel.com`
- Contraseña: `admin123`

## Estructura

- `lib/main.dart` — arranque y sesión.
- `lib/screens.dart` — pantallas y navegación.
- `lib/models.dart` — modelos de dominio.
- `lib/database.dart` — SQLite.
- `lib/controllers.dart` — lógica equivalente a ViewModels.
- `lib/theme.dart` — tema visual Voxelcost3D.

## Ejecutar

Se requiere Flutter SDK 3.3 o posterior. En la carpeta del proyecto:

```bash
flutter create .
flutter pub get
flutter run
```

`flutter create .` genera únicamente los runners de plataforma que no forman parte de la lógica migrada (`android/`, `ios/`, `windows/`, etc.). Los archivos de `lib/` y `pubspec.yaml` incluidos son la aplicación convertida.

Para Android específicamente:

```bash
flutter create --platforms=android .
flutter pub get
flutter run
```

### Ejecutar en macOS

La carpeta `macos/` contiene el runner de escritorio de Flutter (requiere macOS 12 o posterior). Para compilar y ejecutar, abre el proyecto en una Mac con Flutter y Xcode instalados:

```bash
flutter doctor
flutter pub get
flutter run -d macos
```

La compilación macOS no se puede realizar desde Windows; debe hacerse en macOS con Xcode. Antes de distribuir la app, cambia `PRODUCT_BUNDLE_IDENTIFIER` en `macos/Runner/Configs/AppInfo.xcconfig` por un identificador propio de tu organización.

### Escoger emulador desde VS Code

En la configuración de ejecución selecciona `Voxelcost3D_Flutter: escoger dispositivo` y pulsa `F5`. VS Code mostrará los dispositivos disponibles para elegir Windows, Chrome, Edge o un emulador Android conectado.

En Android, la aplicación puede ejecutarse tanto en tablets como en teléfonos y emuladores. Si la interfaz necesita más espacio, gira el dispositivo o usa un emulador con una resolución mayor.

Para ver y arrancar los emuladores Android desde la terminal:

```bash
flutter emulators
flutter emulators --launch <id-del-emulador>
flutter devices
```

Después de iniciar uno, vuelve a ejecutar la configuración `Voxelcost3D_Flutter: escoger dispositivo`.

## Base de datos

Nombre: `voxelcost3d_db.db`, versión 6.

Tablas equivalentes al proyecto Room original:

- `print_records`
- `inventory_items`
- `material_catalog`
- `color_catalog`

## Nota de fidelidad

La conversión mantiene la identidad visual del proyecto Kotlin: fondo `#0A0E14`, cian tecnológico `#22D3EE`, tarjetas claras, tipografía de alto contraste y los mismos flujos funcionales. La pantalla de exportación conserva el comportamiento del original: muestra el proceso de generación, ya que el código Kotlin recibido tampoco implementaba la escritura efectiva de PDF/XLSX.
