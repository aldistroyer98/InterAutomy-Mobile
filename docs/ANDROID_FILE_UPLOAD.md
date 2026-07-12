# Archivos en Android

`webview_flutter_android` delega `input type=file` a
`AndroidWebViewController.setOnShowFileSelector`. `MainActivity.kt` abre
`ACTION_OPEN_DOCUMENT` con `CATEGORY_OPENABLE`, MIME types solicitados por el
portal y selección múltiple cuando corresponde.

El selector usa Storage Access Framework, por lo que no pide permisos amplios
de almacenamiento ni copia documentos sensibles. Devuelve URIs `content://` a
WebView. Algunos proveedores no permiten persistir URI; la carga actual sigue
funcionando y no se conserva una copia.

La carga automática de OC, Excel de productos, MIME/tamaño/progreso y éxito
portal aún requieren pruebas contra Automy. Este soporte es el coordinador de
selección manual viable, no una afirmación de importación completa.
