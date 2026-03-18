# 🎧 HSound - Plataforma de Streaming de Audio

**HSound** es una aplicación móvil de streaming de música desarrollada en Flutter. Este proyecto implementa una arquitectura robusta basada en la nube, combinando **Firebase** para la gestión de usuarios y base de datos, y almacenamiento de objetos compatible con S3 (Oracle Cloud/MinIO) para la gestión de medios. 

El MVP destaca por su reproductor de audio persistente, manejo de estados globales, soporte para reproducción en segundo plano y manejo elegante de conectividad (Modo Offline).

---

## 🚀 Características Principales (MVP)

* **Reproductor Persistente:** Uso avanzado de `ShellRoute` para mantener el *MiniPlayer* activo durante la navegación.
* **Audio en Segundo Plano:** Integración nativa para controlar la música desde la pantalla de bloqueo usando `just_audio_background`.
* **Gestión de Playlists:** Creación de listas personalizadas con subida de portadas directamente a un Bucket S3/OCI.
* **Búsqueda Dinámica:** Filtrado en tiempo real de catálogo por artista o canción.
* **Escudo Offline:** Interfaz resiliente que atrapa errores de conectividad de Firebase sin crashear la aplicación.

---

## 🛠️ Stack Tecnológico y Arquitectura

El proyecto sigue una organización basada en "Features" con una clara separación de responsabilidades.

* **Frontend:** Flutter SDK (3.11.0+) / Dart (3.11.0+).
* **Gestor de Estado:** `provider` (Implementando el patrón *Single Source of Truth* a través de `MockRepository`).
* **Enrutamiento:** `go_router` con *Guards* de autenticación.
* **Backend y Base de Datos:** Firebase Auth y Cloud Firestore.
* **Almacenamiento Multimedia:** OCI / MinIO Object Storage.
* **Motor de Audio:** `just_audio`.

---

## ⚙️ Configuración del Entorno de Desarrollo

Para ejecutar este proyecto de forma local, asegúrate de cumplir con los siguientes requisitos previos.

### Prerrequisitos
* Flutter SDK (3.11.0 o superior).
* Firebase CLI instalado y configurado.

### Paso 1: Variables de Entorno (.env)
Por seguridad, las credenciales de almacenamiento no están en el control de versiones. Crea un archivo `.env` en la raíz del proyecto con la siguiente estructura:

```ini
OCI_REGION=tu-region
OCI_NAMESPACE=tu-namespace
OCI_BUCKET_NAME=tu-bucket
OCI_ACCESS_KEY=tu-access-key
OCI_SECRET_KEY=tu-secret-key
```

Paso 2: Configuración de Firebase
Genera los archivos de configuración específicos de la plataforma ejecutando el CLI de FlutterFire:

```
dart pub global activate flutterfire_cli
flutterfire configure
```

Esto generará automáticamente el archivo lib/firebase_options.dart requerido para la compilación.

Paso 3: Instalación y Ejecución
Una vez configurado el entorno, descarga las dependencias y ejecuta el proyecto:

```
# Descargar dependencias
flutter pub get
```

# Ejecutar en modo debug en el dispositivo conectado
```
flutter run
```

🔒 Buenas Prácticas y Seguridad
⚠️ IMPORTANTE: Nunca realices commits de los archivos .env, firebase_options.dart, ni los google-services.json. Estos archivos contienen credenciales críticas y ya están protegidos en el .gitignore base.

Para despliegues de producción, se recomienda utilizar el siguiente comando para optimizar el rendimiento y ofuscar el código fuente:

```
flutter build apk --release --obfuscate --split-debug-info=build/symbols
```

Desarrollado por Héctor Martínez Reyes - Ingeniería en Tecnologías de la Información y Negocios Digitales.