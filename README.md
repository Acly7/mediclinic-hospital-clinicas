# MediClinic v3 - Hospital de Clínicas

Sistema web académico para la evaluación grupal final Hito 3 + Hito 4. Está orientado al Hospital de Clínicas y cubre gestión de pacientes, médicos, citas, expedientes clínicos, farmacia, notificaciones automáticas simuladas, dashboard por rol, reportes y logs de auditoría.

## Tecnologías usadas

- Frontend: React + Vite, compilado en `frontend/dist`.
- Backend principal: Python + FastAPI.
- Base de datos: PostgreSQL.
- Administrador recomendado: pgAdmin.
- Middleware académico: cola de mensajes para recordatorios de citas.
- Storage académico: subida de archivos a carpeta local `uploads`, simulando almacenamiento clínico/cloud.

## Módulos principales

1. Login por roles: Administrador, Recepción, Médico, Farmacia y Paciente.
2. Dashboard con tarjetas clicables, gráficos y datos por rol.
3. Usuarios: CRUD, roles, activar/desactivar y foto desde archivo.
4. Pacientes: CRUD, validaciones, tipo de sangre en lista y expediente automático.
5. Médicos: CRUD, especialidades y estados.
6. Citas: agenda con filtros, edición, validación de fecha, horarios disponibles y bloqueo de cruces por médico.
7. Expedientes: búsqueda por texto, detalle clínico, consultas, recetas, exámenes y archivos.
8. Farmacia: inventario, filtros, ventas, registro de ventas y solicitudes de revisión al administrador.
9. Notificaciones: campanita con contador, leídas/no leídas, detalle y cola de mensajes.
10. Reportes: citas por rango, médico y estado; resumen visual; CSV e impresión.
11. Logs: auditoría filtrable por rol, módulo y búsqueda.

## Usuarios demo

| Rol | Correo | Contraseña |
|---|---|---|
| Administrador | admin@mediclinic.bo | admin123 |
| Recepción | recepcion@mediclinic.bo | recepcion123 |
| Médico | doctor@mediclinic.bo | doctor123 |
| Farmacia | farmacia@mediclinic.bo | farmacia123 |
| Paciente | juan.perez@paciente.bo | paciente123 |
| Paciente | lucia.fernandez@paciente.bo | paciente123 |

## Cómo ejecutar la base de datos en pgAdmin

1. Abrir pgAdmin.
2. Crear una base de datos llamada `mediclinic_db`.
3. Abrir Query Tool sobre esa base.
4. Copiar y ejecutar todo el archivo:

```text
database/mediclinic_postgresql.sql
```

Ese archivo crea tablas, relaciones, índices y datos de prueba.

## Cómo ejecutar el sistema

La forma más sencilla es hacer doble clic en:

```text
INICIAR_MEDICLINIC_PYTHON.bat
```

Ese archivo instala las dependencias de Python e inicia el sistema en:

```text
http://127.0.0.1:4000
```

La API se puede probar en:

```text
http://127.0.0.1:4000/api/health
```

## Configuración de conexión

El backend usa el archivo:

```text
backend_python/.env
```

Si no existe, el `.bat` lo crea desde `.env.example`. Revisa tu contraseña de PostgreSQL:

```env
DB_HOST=127.0.0.1
DB_PORT=5432
DB_NAME=mediclinic_db
DB_USER=postgres
DB_PASSWORD=123456
```

Cambia `DB_PASSWORD` si tu contraseña no es `123456`.

## Nota para la entrega

Para el PDF se puede documentar una arquitectura monolítica modular. La cola de mensajes se evidencia en el módulo Notificaciones. El almacenamiento de archivos se evidencia al subir foto de perfil o archivos clínicos desde Expedientes.
