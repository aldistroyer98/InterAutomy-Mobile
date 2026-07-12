# Preparación para Play Store

La app es autónoma: no necesita un servidor propio, PC, FastAPI, Selenium ni
ChromeDriver. Automy se visualiza en Android WebView dentro de la aplicación.

Antes de publicar:

1. Configurar firma release y versión final.
2. Declarar la política de privacidad y la finalidad del acceso a Internet.
3. Verificar que no se solicitan permisos de almacenamiento amplio; el adjunto
   usa Storage Access Framework.
4. Probar SSO, selector de archivos y errores de red en Android físico.
5. Mantener `allowAutomaticSubmission = false` hasta una evaluación de riesgo y
   pruebas completas contra Automy.
6. Documentar hosts de producción, soporte y el proceso para cerrar sesión.

No incluir URL privada, credenciales, cookies, tokens, capturas de formularios
ni HTML del portal en la ficha, APK o repositorio.
