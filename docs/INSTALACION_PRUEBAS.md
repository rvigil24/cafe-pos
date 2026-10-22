# Cafe POS — instalación para pruebas

Versión: **1.0.0-beta.1**. Requiere Android 7.0 o superior.
Diseñada para una tablet en orientación horizontal.

## Descargar e instalar

1. En el dispositivo Android, abre
   [la versión de prueba](https://github.com/rvigil24/cafe-pos/releases/tag/v1.0.0-beta.1).
2. En **Assets**, descarga **cafe-pos-1.0.0-beta.1.apk**.
3. Abre el archivo. Si Android lo solicita, permite temporalmente **Instalar
   aplicaciones desconocidas** para el navegador o gestor de archivos utilizado.
   El nombre de la opción depende del dispositivo.
4. Confirma la instalación y abre **Cafe POS**. Puedes desactivar ese permiso
   después. No necesitas activar las opciones de desarrollador.
5. Configura el nombre del negocio, las mesas, las categorías y los productos.
   La aplicación comienza sin datos de ejemplo.

El único APK incluye ARM de 32 bits, ARM de 64 bits y x86 de 64 bits.
El archivo `SHA256SUMS` permite comprobar su integridad.

## Uso y respaldos

Funciona sin internet. Cada dispositivo guarda sus propios datos; los negocios
y dispositivos no comparten catálogo ni ventas. No hay cuentas, sincronización
ni respaldo automático.

Entra en **Configuración → Negocio y respaldos → Exportar respaldo**. Guarda
el archivo `.db` fuera de la aplicación y conserva otra copia fuera del
dispositivo. Hazlo periódicamente y antes de actualizar.

Los pagos con transferencia o tarjeta se registran después de tu confirmación;
la aplicación no procesa tarjetas ni verifica bancos.

## Actualizar

1. Exporta y conserva un respaldo.
2. Descarga el nuevo APK desde GitHub Releases.
3. Instálalo sobre la versión existente y abre la aplicación.
4. Comprueba tus productos, órdenes y ventas.

**No desinstales la aplicación ni borres su almacenamiento para actualizar:**
eso elimina los datos locales. Si Android informa que la firma es incompatible,
detente y consulta al responsable. Las instalaciones antiguas de desarrollo
requieren una transición especial con respaldo y restauración.

## Reportar un problema

Comunica al responsable la versión instalada, el modelo y versión de Android,
los pasos que seguiste y el resultado esperado. Adjunta el error o una captura
cuando ayude. Evita publicar datos del negocio o respaldos de ventas en el
repositorio público.
