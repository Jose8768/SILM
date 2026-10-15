# SILM — Voxelcost3D

Aplicación Flutter para administrar impresiones 3D, inventario de materiales,
catálogos técnicos, historial y reportes de un laboratorio de manufactura.

## Requisitos

- Flutter SDK 3.3 o posterior.
- Visual Studio 2022 con la carga de trabajo **Desarrollo para el escritorio con C++** para compilar en Windows.

## Ejecutar en Windows

Abre esta carpeta (`Voxelcost3D_Flutter`) en VS Code y ejecuta:

```powershell
flutter pub get
flutter run -d windows
```

También puedes seleccionar **Voxelcost3D: Windows** en Run and Debug y pulsar
F5. La tarea de preparación asigna temporalmente `V:` a la carpeta contenedora
y compila desde `V:\Voxelcost3D_Flutter` para mantener corta la ruta y evitar
un error de CMake al compilar desde la raíz de una unidad. Si `V:` apunta a
una ruta antigua que ya no existe, o al directorio anterior del proyecto, el
script la reasigna; si apunta a otra ubicación existente, detiene la ejecución
para no modificar una unidad válida.

## Comprobaciones

```powershell
flutter analyze
flutter test
```

## Funciones

- Inicio de sesión de operador.
- Gestión e historial de impresiones y consumo de materiales.
- Inventario por material y color, con alertas de bajo stock.
- Catálogos técnicos y analítica de producción.
- Persistencia local y exportación de reportes.

Credenciales de demostración: `admin` / `admin123`.
