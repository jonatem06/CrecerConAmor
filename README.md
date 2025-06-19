# Control Escolar App

## Descripción Breve

Control Escolar App es una aplicación móvil desarrollada con Flutter y Firebase, diseñada para facilitar la gestión administrativa y académica de una institución educativa. Permite manejar información del personal, padres de familia, alumnos, finanzas y reportes, con diferentes niveles de acceso y funcionalidades según el rol del usuario.

## Características Principales

*   **Autenticación:**
    *   Inicio de sesión con roles (Administrador con credenciales fijas, lógica pendiente para otros roles con Firebase Auth).
*   **Gestión de Personal:**
    *   Dar de alta nuevo personal (Maestros, Directores, etc.).
    *   Ver lista de personal.
    *   Editar información del personal (funcionalidad en desarrollo).
    *   Cambiar status (Activo/Desactivado) del personal.
*   **Gestión de Papás y Alumnos (Familias):**
    *   Dar de alta familias (información del padre, madre).
    *   Gestión dinámica de múltiples hijos por familia, cada uno con un ID único (`id_hijo_unico`).
    *   Gestión dinámica de personas permitidas para recoger a los hijos.
    *   Ver lista de familias.
    *   Editar información de la familia (funcionalidad en desarrollo).
    *   Cambiar status de la familia.
*   **Gestión de Finanzas:**
    *   Registrar gastos (costo, fecha, tipo de gasto).
    *   Control y visualización de gastos con filtros por rango de fechas (último mes por defecto).
*   **Gestión de Reportes:**
    *   Crear reportes asociados a un niño específico (ID Niño, Fecha, Título, Descripción, Tipo).
    *   Los reportes son creados por el usuario logueado (Maestro/Director).
    *   **Vista de Director:** Visualiza todos los reportes con filtros por maestro y por niño.
    *   **Vista de Maestro:** Visualiza solo los reportes creados por él/ella, con filtro por niño.
    *   **Vista de Papá:** Visualiza los reportes de sus hijos (seleccionando un hijo a la vez).
    *   Resolución de IDs de niño y creador a nombres legibles en la vista de reportes.
*   **Navegación:**
    *   Menú lateral (Drawer) para acceder a los diferentes módulos.

## Tecnologías Utilizadas

*   **Flutter:** (Versión 3.19.6 utilizada durante el desarrollo inicial)
*   **Dart:** (Versión 3.3.4 utilizada durante el desarrollo inicial)
*   **Firebase:**
    *   **Firebase Authentication:** Para el manejo de usuarios (parcialmente implementado).
    *   **Cloud Firestore:** Como base de datos NoSQL para almacenar toda la información.
*   **Paquetes Adicionales de Flutter:**
    *   `intl`: Para formateo de fechas y números (moneda).
    *   `uuid`: Para la generación de identificadores únicos.

## Configuración del Entorno de Desarrollo

### Requisitos Previos

*   **Flutter SDK:** Asegúrate de tener Flutter instalado. Puedes seguir la [guía oficial de Flutter](https://flutter.dev/docs/get-started/install).
*   **IDE:** Android Studio o Visual Studio Code (con las extensiones de Flutter y Dart).
*   **Un emulador o dispositivo físico** para ejecutar la aplicación.

### Clonar el Repositorio

```bash
git clone <URL_DEL_REPOSITORIO>
cd control_escolar_app
```

### Configuración de Firebase

1.  **Crear Proyecto en Firebase:**
    *   Ve a la [Consola de Firebase](https://console.firebase.google.com/).
    *   Crea un nuevo proyecto o selecciona uno existente.

2.  **Configurar para Android:**
    *   En tu proyecto de Firebase, añade una aplicación Android.
    *   Sigue los pasos indicados, y descarga el archivo `google-services.json`.
    *   Coloca este archivo en la ruta: `control_escolar_app/android/app/google-services.json`.

3.  **Configurar para iOS (Opcional, si se planea soportar):**
    *   En tu proyecto de Firebase, añade una aplicación iOS.
    *   Sigue los pasos indicados y descarga el archivo `GoogleService-Info.plist`.
    *   Coloca este archivo en la ruta: `control_escolar_app/ios/Runner/GoogleService-Info.plist`.
    *   Abre el proyecto iOS en Xcode y añade el archivo al target "Runner".

4.  **Habilitar Servicios de Firebase:**
    *   En la Consola de Firebase, ve a la sección "Authentication" y habilita el proveedor "Email/Password". Puedes añadir otros si lo deseas.
    *   Ve a la sección "Firestore Database" y crea una base de datos. Puedes empezar en modo de prueba o modo producción con reglas de seguridad.

5.  **Reglas de Seguridad de Firestore:**
    *   Para desarrollo inicial, puedes usar reglas permisivas. **Es crucial ajustar estas reglas para producción.**
    *   Ejemplo de reglas de desarrollo (permitir lectura y escritura si el usuario está autenticado):
        ```json
        rules_version = '2';
        service cloud.firestore {
          match /databases/{database}/documents {
            match /{document=**} {
              allow read, write: if request.auth != null;
            }
          }
        }
        ```

## Cómo Ejecutar la Aplicación

1.  **Obtener Dependencias:**
    Abre una terminal en la raíz del directorio `control_escolar_app` y ejecuta:
    ```bash
    flutter pub get
    ```

2.  **Ejecutar la Aplicación:**
    Asegúrate de tener un emulador corriendo o un dispositivo conectado, y luego ejecuta:
    ```bash
    flutter run
    ```

## Estructura del Proyecto (lib/)

La estructura principal dentro de la carpeta `lib/` se organiza de la siguiente manera:

*   `main.dart`: Punto de entrada principal de la aplicación, inicialización de Firebase.
*   `views/`: Contiene las diferentes pantallas (UI) de la aplicación.
    *   `login_screen.dart`: Pantalla de inicio de sesión.
    *   `home_screen.dart`: Pantalla principal con el Drawer de navegación.
    *   `personal/`: Pantallas relacionadas con la gestión de personal (`alta_personal_screen.dart`, `ver_personal_screen.dart`, `asignar_maestros_screen.dart`).
    *   `papas/`: Pantallas relacionadas con la gestión de papás/familias (`alta_papas_screen.dart`, `ver_papas_screen.dart`).
    *   `finanzas/`: Pantallas relacionadas con la gestión financiera (`alta_gastos_screen.dart`, `control_gastos_screen.dart`).
    *   `reportes/`: Pantallas relacionadas con la gestión de reportes (`alta_reporte_screen.dart`, `ver_reportes_screen.dart`).
*   `models/` (Actualmente Vacía): Destinada para los modelos de datos (clases Dart que representan la estructura de los datos).
*   `widgets/` (Actualmente Vacía): Destinada para widgets reutilizables a través de la aplicación.
*   `services/` (No Creada): Podría usarse para lógica de negocio, servicios de API, etc.

## Consideraciones Adicionales / TODOs Críticos

*   **`auth_uid` en `personal`:** Es fundamental asegurar que el UID de Firebase Authentication se guarde de manera consistente en un campo (`auth_uid` o similar) dentro de cada documento de la colección `personal`. La lógica actual para la determinación de roles en `VerReportesScreen` asume que el ID del documento de `personal` *es* el UID de Firebase Auth, lo cual podría no ser robusto si no se garantiza esta correspondencia al crear el personal.
*   **`auth_uid` en `familias`:** Similar al punto anterior, si se implementa la autenticación para padres, el `auth_uid` de Firebase debe guardarse dentro de los objetos `padre` y `madre` en la colección `familias` para que la detección del rol "Papa" funcione correctamente en `VerReportesScreen`. La pantalla `AltaPapasScreen` necesita ser actualizada para manejar esto si se permite a los padres crear cuentas de usuario.
*   **Reglas de Seguridad de Firestore:** Las reglas de seguridad actuales (si se usaron las de desarrollo) son demasiado permisivas para un entorno de producción. Deben ser revisadas y ajustadas detalladamente para asegurar que los usuarios solo puedan acceder y modificar los datos que les corresponden.
*   **`id_hijo_unico` en `familias`:** Aunque `AltaPapasScreen` ya genera un `id_hijo_unico` para los nuevos hijos, los datos de familias/hijos que existieran en Firestore *antes* de este refactor no tendrán este campo. Esto podría causar que dichos niños no aparezcan en selectores (como en `AltaReporteScreen`) o que se generen IDs temporales para ellos. Se recomienda una migración de datos o actualización manual para los registros antiguos.
*   **Manejo de Contraseñas:** Las contraseñas actualmente se manejan en texto plano en los formularios y (si se guardan) en Firestore. Esto no es seguro. Se debe implementar un sistema de hashing para las contraseñas o, preferiblemente, delegar completamente el manejo de contraseñas a Firebase Authentication si los padres/personal van a tener cuentas individuales.
*   **Validación de Unicidad de Usuario:** Los campos de "Usuario" en las pantallas de alta de personal y papás no tienen validación de unicidad. Esto debería implementarse para evitar conflictos si estos campos se usan para login.
