LIGALAB WEB V6.2 — GITHUB PAGES + SUPABASE
==========================================

OBJETIVO
- Una única web pública.
- Tus amigos entran sin cuenta: pueden VER todo, buscar H2H, leer tablas, resultados, relatos e historial.
- Tú pulsas “Acceso administrador”, ingresas email + contraseña y recuperas todos los controles.
- Cada cambio de administrador se guarda en Supabase y aparece automáticamente en las pestañas públicas abiertas.

PASO 1 — CREAR SUPABASE
1. Entra a https://supabase.com y crea un proyecto.
2. Abre SQL Editor.
3. Copia y ejecuta TODO el archivo setup_supabase.sql.
4. Ve a Authentication > Users y crea tu único usuario administrador con email y contraseña.
5. Copia el UUID de ese usuario.
6. Vuelve a SQL Editor y ejecuta:
   insert into public.ligalab_admins(user_id) values ('TU_UUID') on conflict do nothing;

PASO 2 — CONFIGURAR LA WEB
1. En Supabase abre Project Settings / API (o Connect) y copia:
   - Project URL
   - Publishable key / anon public key
2. Abre cloud-config.js con Bloc de notas.
3. Reemplaza los dos textos PEGA_AQUI_...
4. Guarda el archivo.

IMPORTANTE: la publishable/anon key es la clave pública del navegador. NO uses jamás service_role.
La seguridad de escritura la hacen las políticas RLS del archivo setup_supabase.sql.

PASO 3 — CARGAR TU PARTIDA V6.1
1. Antes de migrar, abre V6.1 y usa “Exportar JSON”.
2. Publica V6.2 y abre la web.
3. Pulsa “Acceso administrador”.
4. Inicia sesión con tu usuario de Supabase.
5. En Inicio, usa “Importar JSON” y carga el backup de V6.1.
6. En pocos segundos el estado queda publicado en la nube.

PASO 4 — SUBIR A GITHUB A MANO
Sube a la raíz del repositorio estos archivos:
- index.html
- cloud-config.js
- .nojekyll
Opcional, pero recomendable guardar también:
- README_PUBLICACION.txt
- setup_supabase.sql

Luego: Settings > Pages > Deploy from a branch > main > /(root) > Save.

SEGURIDAD
- No hay contraseña escrita en index.html ni en GitHub.
- Los visitantes anónimos tienen permiso SELECT solamente.
- Un usuario autenticado tampoco puede escribir salvo que su UUID esté en ligalab_admins.
- Aunque alguien manipule el JavaScript del navegador para mostrar botones, Supabase rechazará cualquier escritura sin autorización RLS.

ACTUALIZACIÓN EN TIEMPO REAL
El administrador guarda el estado oficial en ligalab_state. Después se actualiza ligalab_signal.
Los navegadores públicos escuchan esa señal mediante Supabase Realtime y vuelven a cargar el estado oficial automáticamente.

ARCHIVOS QUE NUNCA DEBES PUBLICAR
- service_role key
- contraseñas
- códigos privados o tokens personales
