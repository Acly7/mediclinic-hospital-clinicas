import os
import re
import json
import hashlib
import shutil
from pathlib import Path
from typing import Any, Dict, List, Optional
from datetime import date, datetime, time, timedelta

import psycopg2
import psycopg2.extras
from fastapi import FastAPI, HTTPException, Request, Query, UploadFile, File, Form
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse, FileResponse
from fastapi.staticfiles import StaticFiles
from fastapi.encoders import jsonable_encoder

BASE_DIR = Path(__file__).resolve().parent
PROJECT_DIR = BASE_DIR.parent
FRONTEND_DIST = PROJECT_DIR / "frontend" / "dist"
UPLOAD_DIR = PROJECT_DIR / "uploads"
PROFILE_DIR = UPLOAD_DIR / "perfiles"
CLINICAL_DIR = UPLOAD_DIR / "clinicos"
for folder in (PROFILE_DIR, CLINICAL_DIR):
    folder.mkdir(parents=True, exist_ok=True)


def load_env_file(path: Path) -> None:
    if not path.exists():
        return
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        os.environ.setdefault(key.strip(), value.strip().strip('"').strip("'"))


load_env_file(BASE_DIR / ".env")

DB_CONFIG = {
    "host": os.getenv("DB_HOST", "127.0.0.1"),
    "port": int(os.getenv("DB_PORT", "5432")),
    "dbname": os.getenv("DB_NAME", "mediclinic_db"),
    "user": os.getenv("DB_USER", "postgres"),
    "password": os.getenv("DB_PASSWORD", "postgres"),
}

app = FastAPI(title="MediClinic API", version="3.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.mount("/uploads", StaticFiles(directory=str(UPLOAD_DIR)), name="uploads")


def db_query(sql: str, params: Optional[List[Any]] = None, fetch: str = "all"):
    conn = psycopg2.connect(**DB_CONFIG)
    try:
        with conn:
            with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
                cur.execute(sql, params or [])
                if fetch == "one":
                    return cur.fetchone()
                if fetch == "none":
                    return None
                return cur.fetchall()
    finally:
        conn.close()


def sha256(value: str) -> str:
    return hashlib.sha256(str(value).encode("utf-8")).hexdigest()


def created(content):
    return JSONResponse(status_code=201, content=jsonable_encoder(content))


def full_name(row: Dict[str, Any]) -> str:
    return f"{row.get('nombre', '')} {row.get('apellido', '')}".strip()


def log_activity(usuario_id: Optional[int], modulo: str, accion: str, detalle: str) -> None:
    try:
        db_query(
            "INSERT INTO logs_actividad (usuario_id, modulo, accion, detalle) VALUES (%s,%s,%s,%s)",
            [usuario_id, modulo, accion, detalle],
            fetch="none",
        )
    except Exception:
        pass


def normalize_text(value: str) -> str:
    return re.sub(r"\s+", " ", str(value or "").strip())


def validate_name(value: str, label: str) -> str:
    value = normalize_text(value)
    if not re.fullmatch(r"[A-Za-zÁÉÍÓÚáéíóúÑñ ]{2,80}", value):
        raise HTTPException(status_code=400, detail=f"{label} solo debe contener letras y espacios.")
    return " ".join(part.capitalize() for part in value.split())


def validate_ci(value: str) -> str:
    value = str(value or "").strip()
    if not re.fullmatch(r"\d{5,12}", value):
        raise HTTPException(status_code=400, detail="El CI debe tener entre 5 y 12 dígitos.")
    return value


def parse_date(value: str, label: str = "Fecha") -> date:
    try:
        return date.fromisoformat(str(value)[:10])
    except Exception:
        raise HTTPException(status_code=400, detail=f"{label} no tiene un formato válido.")


def parse_time(value: str) -> time:
    try:
        return time.fromisoformat(str(value)[:5])
    except Exception:
        raise HTTPException(status_code=400, detail="La hora no tiene un formato válido.")


def date_to_weekday_es(d: date) -> str:
    return ["Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"][d.weekday()]


DEFAULT_APPOINTMENT_SCHEDULES = [
    {"hora_inicio": time(8, 0), "hora_fin": time(12, 0), "consultorio": "Consultorio general"},
    {"hora_inicio": time(14, 0), "hora_fin": time(18, 0), "consultorio": "Consultorio general"},
]


def available_slots_for_doctor(medico_id: int, fecha_value: date, exclude_id: Optional[int] = None) -> Dict[str, Any]:
    day = date_to_weekday_es(fecha_value)
    schedules = db_query(
        "SELECT * FROM horarios_medicos WHERE medico_id=%s AND dia_semana=%s ORDER BY hora_inicio",
        [medico_id, day],
    )
    # Si la base no tiene horarios cargados para ese día, dejamos una agenda estándar
    # de lunes a sábado para que el formulario siempre muestre horas seleccionables.
    # La validación de cruces se mantiene igual: las citas ocupadas quedan bloqueadas.
    if not schedules and fecha_value.weekday() < 6:
        schedules = DEFAULT_APPOINTMENT_SCHEDULES
    occupied = db_query(
        """
        SELECT hora::text AS hora, id FROM citas
        WHERE medico_id=%s AND fecha=%s AND estado <> 'Cancelada'
          AND (%s IS NULL OR id <> %s)
        """,
        [medico_id, fecha_value, exclude_id, exclude_id],
    )
    occupied_set = {str(x["hora"])[:5] for x in occupied}
    slots = []
    for schedule in schedules:
        start = datetime.combine(fecha_value, schedule["hora_inicio"])
        end = datetime.combine(fecha_value, schedule["hora_fin"])
        current = start
        while current < end:
            hour = current.time().strftime("%H:%M")
            slots.append({
                "hora": hour,
                "ocupado": hour in occupied_set,
                "consultorio": schedule.get("consultorio"),
            })
            current += timedelta(minutes=30)
    return {"dia": day, "horarios": schedules, "slots": slots}


def ensure_available_appointment(medico_id: int, fecha_value: date, hora_value: time, exclude_id: Optional[int] = None) -> None:
    if fecha_value < date.today():
        raise HTTPException(status_code=400, detail="No se puede agendar una cita en una fecha anterior a hoy.")
    doctor = db_query("SELECT estado FROM medicos WHERE id=%s", [medico_id], fetch="one")
    if not doctor:
        raise HTTPException(status_code=404, detail="El médico seleccionado no existe.")
    if doctor["estado"] != "Disponible":
        raise HTTPException(status_code=400, detail="El médico seleccionado no se encuentra disponible.")
    availability = available_slots_for_doctor(medico_id, fecha_value, exclude_id)
    available = [s["hora"] for s in availability["slots"] if not s["ocupado"]]
    hour = hora_value.strftime("%H:%M")
    if hour not in available:
        if availability["slots"]:
            raise HTTPException(status_code=400, detail=f"Ese horario no está disponible. Horarios libres: {', '.join(available) or 'ninguno'}.")
        raise HTTPException(status_code=400, detail=f"El médico no atiende el día {availability['dia']}.")


@app.exception_handler(Exception)
async def global_exception_handler(_request: Request, exc: Exception):
    if isinstance(exc, HTTPException):
        return JSONResponse(status_code=exc.status_code, content={"detail": exc.detail})
    detail = str(exc)
    status = 500
    message = "Ocurrió un error en el servidor."
    if getattr(exc, "pgcode", None) == "23505":
        status = 409
        message = "Ya existe un registro con esos datos únicos."
    return JSONResponse(status_code=status, content={"message": message, "detail": detail})


@app.get("/api/health")
def health():
    row = db_query("SELECT NOW() AS now", fetch="one")
    return {"ok": True, "service": "MediClinic API Python", "version": "3.0.0", "databaseTime": row["now"]}


@app.post("/api/auth/login")
async def login(request: Request):
    data = await request.json()
    correo = data.get("correo")
    password = data.get("password")
    if not correo or not password:
        raise HTTPException(status_code=400, detail="Correo y contraseña son obligatorios.")

    user = db_query(
        """
        SELECT u.id, u.nombre, u.apellido, u.correo, u.estado, u.password_hash, u.foto_url,
               u.paciente_id, u.medico_id, r.nombre AS rol
        FROM usuarios u
        JOIN roles r ON r.id = u.rol_id
        WHERE LOWER(u.correo) = LOWER(%s)
        """,
        [correo],
        fetch="one",
    )
    if not user or sha256(password) != user["password_hash"]:
        raise HTTPException(status_code=401, detail="Credenciales incorrectas.")
    if user["estado"] != "Activo":
        raise HTTPException(status_code=403, detail="Usuario inactivo.")
    user.pop("password_hash", None)
    user["nombre_completo"] = full_name(user)
    return {"user": user}


@app.get("/api/dashboard")
def dashboard(usuario_id: Optional[str] = None, rol: str = "Administrador", paciente_id: Optional[str] = None, medico_id: Optional[str] = None):
    cards = db_query(
        """
        SELECT
          (SELECT COUNT(*) FROM pacientes WHERE estado = 'Activo') AS pacientes,
          (SELECT COUNT(*) FROM citas WHERE fecha = CURRENT_DATE) AS citas_hoy,
          (SELECT COUNT(*) FROM citas WHERE fecha = CURRENT_DATE AND estado = 'Atendida') AS atendidas_hoy,
          (SELECT COUNT(*) FROM medicamentos WHERE stock <= stock_minimo OR estado IN ('Bajo stock','Agotado')) AS bajo_stock,
          (SELECT COUNT(*) FROM notificaciones WHERE estado = 'Enviada') AS notificaciones_enviadas,
          (SELECT COALESCE(SUM(total),0) FROM ventas_farmacia WHERE fecha::date = CURRENT_DATE) AS ventas_hoy
        """,
        fetch="one",
    )
    attended = db_query(
        """
        SELECT fecha::date, COUNT(*)::int AS total
        FROM citas
        WHERE estado = 'Atendida'
        GROUP BY fecha
        ORDER BY fecha DESC
        LIMIT 7
        """
    )
    top_meds = db_query(
        """
        SELECT m.nombre, COALESCE(SUM(rd.cantidad), 0)::int AS total
        FROM receta_detalle rd
        JOIN medicamentos m ON m.id = rd.medicamento_id
        GROUP BY m.nombre
        ORDER BY total DESC
        LIMIT 6
        """
    )
    by_specialty = db_query(
        """
        SELECT e.nombre, COUNT(*)::int AS total
        FROM citas c
        JOIN especialidades e ON e.id = c.especialidad_id
        GROUP BY e.nombre
        ORDER BY total DESC
        """
    )
    by_status = db_query("SELECT estado, COUNT(*)::int AS total FROM citas GROUP BY estado ORDER BY estado")
    critical = db_query(
        """
        SELECT codigo, nombre, presentacion, stock, stock_minimo, estado
        FROM medicamentos
        WHERE stock <= stock_minimo OR estado IN ('Bajo stock','Agotado')
        ORDER BY stock ASC, nombre ASC
        LIMIT 8
        """
    )
    activity = db_query(
        """
        SELECT l.id, l.modulo, l.accion, l.detalle, l.creado_en, r.nombre AS rol,
               COALESCE(u.nombre || ' ' || u.apellido, 'Sistema') AS usuario
        FROM logs_actividad l
        LEFT JOIN usuarios u ON u.id = l.usuario_id
        LEFT JOIN roles r ON r.id = u.rol_id
        ORDER BY l.creado_en DESC
        LIMIT 8
        """
    )
    today = db_query(
        """
        SELECT c.*, p.nombre AS paciente_nombre, p.apellido AS paciente_apellido, m.nombre AS medico_nombre, m.apellido AS medico_apellido, e.nombre AS especialidad
        FROM citas c JOIN pacientes p ON p.id=c.paciente_id JOIN medicos m ON m.id=c.medico_id JOIN especialidades e ON e.id=c.especialidad_id
        WHERE c.fecha = CURRENT_DATE
        ORDER BY c.hora ASC
        """
    )
    return {
        "cards": cards,
        "pacientesAtendidos": list(reversed(attended)),
        "medicamentosRecetados": top_meds,
        "citasPorEspecialidad": by_specialty,
        "citasPorEstado": by_status,
        "stockCritico": critical,
        "actividad": activity,
        "citasHoy": today,
    }


@app.get("/api/patients")
def patients(search: str = ""):
    term = f"%{search}%"
    return db_query(
        """
        SELECT *, EXTRACT(YEAR FROM AGE(CURRENT_DATE, fecha_nacimiento))::int AS edad
        FROM pacientes
        WHERE nombre ILIKE %s OR apellido ILIKE %s OR ci ILIKE %s
        ORDER BY creado_en DESC, id DESC
        """,
        [term, term, term],
    )


@app.get("/api/patients/{patient_id}")
def patient_detail(patient_id: int):
    patient = db_query(
        "SELECT *, EXTRACT(YEAR FROM AGE(CURRENT_DATE, fecha_nacimiento))::int AS edad FROM pacientes WHERE id=%s",
        [patient_id],
        fetch="one",
    )
    if not patient:
        raise HTTPException(status_code=404, detail="Paciente no encontrado.")
    record = db_query("SELECT * FROM expedientes WHERE paciente_id=%s", [patient_id], fetch="one")
    return {"paciente": patient, "expediente": record}


@app.post("/api/patients")
async def create_patient(request: Request):
    data = await request.json()
    nombre = validate_name(data.get("nombre"), "Nombre")
    apellido = validate_name(data.get("apellido"), "Apellido")
    ci = validate_ci(data.get("ci"))
    birth = parse_date(data.get("fecha_nacimiento"), "Fecha de nacimiento")
    if birth >= date.today():
        raise HTTPException(status_code=400, detail="La fecha de nacimiento debe ser anterior a hoy.")
    patient = db_query(
        """
        INSERT INTO pacientes (nombre, apellido, ci, fecha_nacimiento, celular, direccion, tipo_sangre, alergias, antecedentes, estado)
        VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s) RETURNING *
        """,
        [nombre, apellido, ci, birth, data.get("celular"), data.get("direccion"), data.get("tipo_sangre"), data.get("alergias"), data.get("antecedentes"), data.get("estado", "Activo")],
        fetch="one",
    )
    code = f"EXP-{date.today().year}-{patient['id']:04d}"
    db_query("INSERT INTO expedientes (paciente_id, codigo, observaciones_generales) VALUES (%s,%s,%s)", [patient["id"], code, "Expediente creado automáticamente."], fetch="none")
    log_activity(data.get("usuario_id"), "Pacientes", "Registro", f"Se registró al paciente {nombre} {apellido}.")
    return created(patient)


@app.put("/api/patients/{patient_id}")
async def update_patient(patient_id: int, request: Request):
    data = await request.json()
    nombre = validate_name(data.get("nombre"), "Nombre")
    apellido = validate_name(data.get("apellido"), "Apellido")
    ci = validate_ci(data.get("ci"))
    birth = parse_date(data.get("fecha_nacimiento"), "Fecha de nacimiento")
    if birth >= date.today():
        raise HTTPException(status_code=400, detail="La fecha de nacimiento debe ser anterior a hoy.")
    patient = db_query(
        """
        UPDATE pacientes SET nombre=%s, apellido=%s, ci=%s, fecha_nacimiento=%s, celular=%s, direccion=%s, tipo_sangre=%s, alergias=%s, antecedentes=%s, estado=%s
        WHERE id=%s RETURNING *
        """,
        [nombre, apellido, ci, birth, data.get("celular"), data.get("direccion"), data.get("tipo_sangre"), data.get("alergias"), data.get("antecedentes"), data.get("estado", "Activo"), patient_id],
        fetch="one",
    )
    if not patient:
        raise HTTPException(status_code=404, detail="Paciente no encontrado.")
    log_activity(data.get("usuario_id"), "Pacientes", "Actualización", f"Se actualizó al paciente {nombre} {apellido}.")
    return patient


@app.patch("/api/patients/{patient_id}/status")
async def patient_status(patient_id: int, request: Request):
    data = await request.json()
    patient = db_query("UPDATE pacientes SET estado=%s WHERE id=%s RETURNING *", [data.get("estado"), patient_id], fetch="one")
    if not patient:
        raise HTTPException(status_code=404, detail="Paciente no encontrado.")
    log_activity(data.get("usuario_id"), "Pacientes", "Cambio de estado", f"Paciente {patient['nombre']} {patient['apellido']} ahora está {patient['estado']}.")
    return patient


@app.get("/api/specialties")
def specialties():
    return db_query("SELECT * FROM especialidades WHERE estado='Activo' ORDER BY nombre")


@app.get("/api/doctors")
def doctors(especialidad_id: Optional[str] = None):
    params = []
    where = "WHERE 1=1"
    if especialidad_id:
        where += " AND m.especialidad_id=%s"
        params.append(especialidad_id)
    return db_query(
        f"""
        SELECT m.*, e.nombre AS especialidad
        FROM medicos m JOIN especialidades e ON e.id=m.especialidad_id
        {where}
        ORDER BY m.nombre, m.apellido
        """,
        params,
    )


@app.post("/api/doctors")
async def create_doctor(request: Request):
    data = await request.json()
    nombre = validate_name(data.get("nombre"), "Nombre")
    apellido = validate_name(data.get("apellido"), "Apellido")
    ci = validate_ci(data.get("ci"))
    doctor = db_query(
        """
        INSERT INTO medicos (especialidad_id,nombre,apellido,ci,correo,telefono,nro_matricula,estado)
        VALUES (%s,%s,%s,%s,%s,%s,%s,%s) RETURNING *
        """,
        [data.get("especialidad_id"), nombre, apellido, ci, data.get("correo"), data.get("telefono"), data.get("nro_matricula"), data.get("estado", "Disponible")],
        fetch="one",
    )
    log_activity(data.get("usuario_id"), "Médicos", "Registro", f"Se registró al Dr(a). {nombre} {apellido}.")
    return created(doctor)


@app.put("/api/doctors/{doctor_id}")
async def update_doctor(doctor_id: int, request: Request):
    data = await request.json()
    nombre = validate_name(data.get("nombre"), "Nombre")
    apellido = validate_name(data.get("apellido"), "Apellido")
    ci = validate_ci(data.get("ci"))
    doctor = db_query(
        """
        UPDATE medicos SET especialidad_id=%s,nombre=%s,apellido=%s,ci=%s,correo=%s,telefono=%s,nro_matricula=%s,estado=%s
        WHERE id=%s RETURNING *
        """,
        [data.get("especialidad_id"), nombre, apellido, ci, data.get("correo"), data.get("telefono"), data.get("nro_matricula"), data.get("estado", "Disponible"), doctor_id],
        fetch="one",
    )
    if not doctor:
        raise HTTPException(status_code=404, detail="Médico no encontrado.")
    log_activity(data.get("usuario_id"), "Médicos", "Actualización", f"Se actualizó al Dr(a). {nombre} {apellido}.")
    return doctor


@app.patch("/api/doctors/{doctor_id}/status")
async def doctor_status(doctor_id: int, request: Request):
    data = await request.json()
    doctor = db_query("UPDATE medicos SET estado=%s WHERE id=%s RETURNING *", [data.get("estado"), doctor_id], fetch="one")
    if not doctor:
        raise HTTPException(status_code=404, detail="Médico no encontrado.")
    log_activity(data.get("usuario_id"), "Médicos", "Cambio de estado", f"El médico {doctor['nombre']} {doctor['apellido']} ahora está {doctor['estado']}.")
    return doctor


@app.get("/api/doctors/{doctor_id}/availability")
def doctor_availability(doctor_id: int, fecha: str, exclude_id: Optional[int] = None):
    fecha_value = parse_date(fecha)
    return available_slots_for_doctor(doctor_id, fecha_value, exclude_id)


@app.get("/api/appointments")
def appointments(
    fecha: Optional[str] = None,
    estado: Optional[str] = None,
    medico_id: Optional[str] = None,
    paciente_id: Optional[str] = None,
    especialidad_id: Optional[str] = None,
    search: str = "",
    hora: str = "",
    sort: str = "recientes",
):
    params: List[Any] = []
    where = "WHERE 1=1"
    if fecha:
        where += " AND c.fecha=%s"; params.append(fecha)
    if estado:
        where += " AND c.estado=%s"; params.append(estado)
    if medico_id:
        where += " AND c.medico_id=%s"; params.append(medico_id)
    if paciente_id:
        where += " AND c.paciente_id=%s"; params.append(paciente_id)
    if especialidad_id:
        where += " AND c.especialidad_id=%s"; params.append(especialidad_id)
    if hora:
        where += " AND c.hora=%s"; params.append(hora)
    if search:
        where += " AND (p.nombre ILIKE %s OR p.apellido ILIKE %s OR p.ci ILIKE %s OR m.nombre ILIKE %s OR m.apellido ILIKE %s)"
        term = f"%{search}%"; params += [term, term, term, term, term]
    order = "c.fecha DESC, c.hora DESC, c.creado_en DESC" if sort == "recientes" else "c.fecha ASC, c.hora ASC"
    return db_query(
        f"""
        SELECT c.*, p.nombre AS paciente_nombre, p.apellido AS paciente_apellido, p.ci AS paciente_ci,
               m.nombre AS medico_nombre, m.apellido AS medico_apellido, e.nombre AS especialidad
        FROM citas c
        JOIN pacientes p ON p.id=c.paciente_id
        JOIN medicos m ON m.id=c.medico_id
        JOIN especialidades e ON e.id=c.especialidad_id
        {where}
        ORDER BY {order}
        """,
        params,
    )


@app.post("/api/appointments")
async def create_appointment(request: Request):
    data = await request.json()
    fecha_value = parse_date(data.get("fecha"))
    hora_value = parse_time(data.get("hora"))
    for field in ["paciente_id", "medico_id", "especialidad_id"]:
        if not data.get(field):
            raise HTTPException(status_code=400, detail="Paciente, médico, especialidad, fecha y hora son obligatorios.")
    ensure_available_appointment(int(data["medico_id"]), fecha_value, hora_value)
    cita = db_query(
        """
        INSERT INTO citas (paciente_id, medico_id, especialidad_id, fecha, hora, motivo, estado, creado_por)
        VALUES (%s,%s,%s,%s,%s,%s,%s,%s) RETURNING *
        """,
        [data.get("paciente_id"), data.get("medico_id"), data.get("especialidad_id"), fecha_value, hora_value, data.get("motivo"), data.get("estado", "Pendiente"), data.get("usuario_id")],
        fetch="one",
    )
    patient = db_query("SELECT nombre, apellido, celular FROM pacientes WHERE id=%s", [data.get("paciente_id")], fetch="one")
    spec = db_query("SELECT nombre FROM especialidades WHERE id=%s", [data.get("especialidad_id")], fetch="one")
    msg = f"Estimado paciente, recuerde su cita de {spec['nombre']} el {fecha_value.strftime('%d/%m/%Y')} a horas {hora_value.strftime('%H:%M')}."
    notif = db_query(
        """
        INSERT INTO notificaciones (paciente_id, cita_id, destinatario, asunto, mensaje, canal, estado, tipo, leida)
        VALUES (%s,%s,%s,%s,%s,'Correo simulado','Pendiente','RECORDATORIO_CITA',false) RETURNING *
        """,
        [data.get("paciente_id"), cita["id"], f"{patient['celular']}@correo-simulado.bo", "Recordatorio de cita médica", msg],
        fetch="one",
    )
    db_query("INSERT INTO cola_mensajes (tipo, referencia_id, payload) VALUES (%s,%s,%s)", ["RECORDATORIO_CITA", notif["id"], json.dumps({"cita_id": cita["id"], "paciente": full_name(patient), "fecha": str(fecha_value), "hora": hora_value.strftime("%H:%M")})], fetch="none")
    log_activity(data.get("usuario_id"), "Citas", "Agenda", f"Se agendó cita para {patient['nombre']} {patient['apellido']}.")
    return created(cita)


@app.put("/api/appointments/{appointment_id}")
async def update_appointment(appointment_id: int, request: Request):
    data = await request.json()
    fecha_value = parse_date(data.get("fecha"))
    hora_value = parse_time(data.get("hora"))
    ensure_available_appointment(int(data["medico_id"]), fecha_value, hora_value, exclude_id=appointment_id)
    cita = db_query(
        """
        UPDATE citas SET paciente_id=%s, medico_id=%s, especialidad_id=%s, fecha=%s, hora=%s, motivo=%s, estado=%s
        WHERE id=%s RETURNING *
        """,
        [data.get("paciente_id"), data.get("medico_id"), data.get("especialidad_id"), fecha_value, hora_value, data.get("motivo"), data.get("estado", "Pendiente"), appointment_id],
        fetch="one",
    )
    if not cita:
        raise HTTPException(status_code=404, detail="Cita no encontrada.")
    log_activity(data.get("usuario_id"), "Citas", "Actualización", f"Se actualizó la cita #{appointment_id}.")
    return cita


@app.patch("/api/appointments/{appointment_id}/status")
async def appointment_status(appointment_id: int, request: Request):
    data = await request.json()
    status = data.get("estado")
    if status not in ["Pendiente", "Confirmada", "Atendida", "Cancelada"]:
        raise HTTPException(status_code=400, detail="Estado de cita inválido.")
    cita = db_query("UPDATE citas SET estado=%s WHERE id=%s RETURNING *", [status, appointment_id], fetch="one")
    if not cita:
        raise HTTPException(status_code=404, detail="Cita no encontrada.")
    log_activity(data.get("usuario_id"), "Citas", "Cambio de estado", f"La cita #{appointment_id} cambió a {status}.")
    return cita


@app.get("/api/records")
def records(search: str = ""):
    term = f"%{search}%"
    return db_query(
        """
        SELECT e.id, e.codigo, e.paciente_id, p.nombre, p.apellido, p.ci, p.tipo_sangre, p.estado,
               EXTRACT(YEAR FROM AGE(CURRENT_DATE, p.fecha_nacimiento))::int AS edad
        FROM expedientes e JOIN pacientes p ON p.id=e.paciente_id
        WHERE p.nombre ILIKE %s OR p.apellido ILIKE %s OR p.ci ILIKE %s OR e.codigo ILIKE %s
        ORDER BY p.nombre, p.apellido
        """,
        [term, term, term, term],
    )


@app.get("/api/records/{patient_id}")
def medical_record(patient_id: int):
    patient = db_query(
        "SELECT *, EXTRACT(YEAR FROM AGE(CURRENT_DATE, fecha_nacimiento))::int AS edad FROM pacientes WHERE id=%s",
        [patient_id],
        fetch="one",
    )
    expediente = db_query("SELECT * FROM expedientes WHERE paciente_id=%s", [patient_id], fetch="one")
    if not patient or not expediente:
        raise HTTPException(status_code=404, detail="Expediente no encontrado.")
    consultas = db_query(
        """
        SELECT c.*, m.nombre || ' ' || m.apellido AS medico
        FROM consultas c JOIN medicos m ON m.id=c.medico_id
        WHERE c.expediente_id=%s ORDER BY c.fecha DESC
        """,
        [expediente["id"]],
    )
    recetas = db_query(
        """
        SELECT r.id, r.consulta_id, r.indicaciones, r.fecha, r.pdf_url,
               COALESCE(json_agg(json_build_object('medicamento', m.nombre, 'dosis', rd.dosis, 'frecuencia', rd.frecuencia, 'dias', rd.dias, 'cantidad', rd.cantidad)) FILTER (WHERE rd.id IS NOT NULL), '[]') AS detalle
        FROM recetas r
        LEFT JOIN receta_detalle rd ON rd.receta_id = r.id
        LEFT JOIN medicamentos m ON m.id = rd.medicamento_id
        JOIN consultas c ON c.id = r.consulta_id
        WHERE c.expediente_id=%s
        GROUP BY r.id ORDER BY r.fecha DESC
        """,
        [expediente["id"]],
    )
    examenes = db_query(
        """
        SELECT ex.* FROM examenes ex JOIN consultas c ON c.id=ex.consulta_id
        WHERE c.expediente_id=%s ORDER BY ex.fecha DESC
        """,
        [expediente["id"]],
    )
    archivos = db_query("SELECT * FROM archivos_clinicos WHERE expediente_id=%s ORDER BY creado_en DESC", [expediente["id"]])
    return {"paciente": patient, "expediente": expediente, "consultas": consultas, "recetas": recetas, "examenes": examenes, "archivos": archivos}


@app.post("/api/consultations")
async def create_consultation(request: Request):
    data = await request.json()
    patient_id = data.get("paciente_id")
    medico_id = data.get("medico_id")
    if not patient_id or not medico_id or not data.get("diagnostico"):
        raise HTTPException(status_code=400, detail="Paciente, médico y diagnóstico son obligatorios.")
    expediente = db_query("SELECT * FROM expedientes WHERE paciente_id=%s", [patient_id], fetch="one")
    if not expediente:
        raise HTTPException(status_code=404, detail="El paciente no tiene expediente.")
    consulta = db_query(
        """
        INSERT INTO consultas (expediente_id, cita_id, medico_id, diagnostico, tratamiento, observaciones)
        VALUES (%s,%s,%s,%s,%s,%s) RETURNING *
        """,
        [expediente["id"], data.get("cita_id"), medico_id, data.get("diagnostico"), data.get("tratamiento"), data.get("observaciones")],
        fetch="one",
    )
    meds = data.get("medicamentos") or []
    receta = None
    if meds:
        receta = db_query("INSERT INTO recetas (consulta_id, indicaciones, pdf_url) VALUES (%s,%s,%s) RETURNING *", [consulta["id"], data.get("indicaciones", "Receta generada desde expediente clínico."), f"/uploads/clinicos/receta-{consulta['id']}.txt"], fetch="one")
        for item in meds:
            db_query(
                "INSERT INTO receta_detalle (receta_id, medicamento_id, dosis, frecuencia, dias, cantidad) VALUES (%s,%s,%s,%s,%s,%s)",
                [receta["id"], item.get("medicamento_id"), item.get("dosis"), item.get("frecuencia"), item.get("dias") or 1, item.get("cantidad") or 1],
                fetch="none",
            )
        farmacia = db_query("SELECT id FROM usuarios u JOIN roles r ON r.id=u.rol_id WHERE r.nombre='Farmacia' AND u.estado='Activo' ORDER BY u.id LIMIT 1", fetch="one")
        if farmacia:
            patient = db_query("SELECT nombre, apellido FROM pacientes WHERE id=%s", [patient_id], fetch="one")
            db_query(
                """
                INSERT INTO notificaciones (usuario_destino_id, paciente_id, destinatario, asunto, mensaje, canal, estado, tipo, leida)
                VALUES (%s,%s,%s,%s,%s,'Sistema interno','Enviada','RECETA_FARMACIA',false)
                """,
                [farmacia["id"], patient_id, "Farmacia", "Nueva receta médica", f"El Dr(a). registró una receta para {full_name(patient)}. Revisar medicamentos solicitados."],
                fetch="none",
            )
    log_activity(data.get("usuario_id"), "Expediente clínico", "Consulta", "Se registró diagnóstico, tratamiento y receta clínica.")
    return created({"consulta": consulta, "receta": receta})


@app.get("/api/medicines")
def medicines(search: str = "", presentacion: str = "", estado: str = "", categoria: str = ""):
    params: List[Any] = []
    where = "WHERE 1=1"
    if search:
        term = f"%{search}%"; where += " AND (nombre ILIKE %s OR codigo ILIKE %s OR concentracion ILIKE %s)"; params += [term, term, term]
    if presentacion:
        where += " AND presentacion ILIKE %s"; params.append(f"%{presentacion}%")
    if estado:
        where += " AND estado=%s"; params.append(estado)
    if categoria:
        where += " AND categoria ILIKE %s"; params.append(f"%{categoria}%")
    return db_query(f"SELECT * FROM medicamentos {where} ORDER BY nombre", params)


@app.post("/api/medicines")
async def create_medicine(request: Request):
    data = await request.json()
    if not data.get("codigo") or not data.get("nombre"):
        raise HTTPException(status_code=400, detail="Código y nombre son obligatorios.")
    med = db_query(
        """
        INSERT INTO medicamentos (codigo,nombre,presentacion,concentracion,categoria,precio,stock,stock_minimo,fecha_vencimiento,estado)
        VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s) RETURNING *
        """,
        [data.get("codigo"), data.get("nombre"), data.get("presentacion"), data.get("concentracion"), data.get("categoria"), data.get("precio") or 0, data.get("stock") or 0, data.get("stock_minimo") or 5, data.get("fecha_vencimiento") or None, data.get("estado", "Disponible")],
        fetch="one",
    )
    log_activity(data.get("usuario_id"), "Farmacia", "Registro", f"Se registró medicamento {med['nombre']}.")
    return created(med)


@app.put("/api/medicines/{medicine_id}")
async def update_medicine(medicine_id: int, request: Request):
    data = await request.json()
    med = db_query(
        """
        UPDATE medicamentos SET codigo=%s,nombre=%s,presentacion=%s,concentracion=%s,categoria=%s,precio=%s,stock=%s,stock_minimo=%s,fecha_vencimiento=%s,estado=%s,actualizado_en=NOW()
        WHERE id=%s RETURNING *
        """,
        [data.get("codigo"), data.get("nombre"), data.get("presentacion"), data.get("concentracion"), data.get("categoria"), data.get("precio") or 0, data.get("stock") or 0, data.get("stock_minimo") or 5, data.get("fecha_vencimiento") or None, data.get("estado", "Disponible"), medicine_id],
        fetch="one",
    )
    if not med:
        raise HTTPException(status_code=404, detail="Medicamento no encontrado.")
    log_activity(data.get("usuario_id"), "Farmacia", "Actualización", f"Se actualizó medicamento {med['nombre']}.")
    return med


@app.get("/api/sales")
def sales(from_: str = Query("2026-06-01", alias="from"), to: str = "2026-06-30"):
    return db_query(
        """
        SELECT v.*, u.nombre || ' ' || u.apellido AS usuario,
               COALESCE(p.nombre || ' ' || p.apellido, 'Venta general') AS paciente,
               COALESCE(json_agg(json_build_object('medicamento', m.nombre, 'cantidad', vd.cantidad, 'subtotal', vd.subtotal)) FILTER (WHERE vd.id IS NOT NULL), '[]') AS detalle
        FROM ventas_farmacia v
        LEFT JOIN usuarios u ON u.id=v.usuario_id
        LEFT JOIN pacientes p ON p.id=v.paciente_id
        LEFT JOIN venta_detalle vd ON vd.venta_id=v.id
        LEFT JOIN medicamentos m ON m.id=vd.medicamento_id
        WHERE v.fecha::date BETWEEN %s AND %s
        GROUP BY v.id, u.nombre, u.apellido, p.nombre, p.apellido
        ORDER BY v.fecha DESC
        """,
        [from_, to],
    )


@app.post("/api/sales")
async def create_sale(request: Request):
    data = await request.json()
    items = data.get("items") or []
    if not items:
        raise HTTPException(status_code=400, detail="Agrega al menos un medicamento para registrar la venta.")
    total = 0.0
    checked = []
    for item in items:
        med = db_query("SELECT * FROM medicamentos WHERE id=%s", [item.get("medicamento_id")], fetch="one")
        qty = int(item.get("cantidad") or 0)
        if not med or qty <= 0:
            raise HTTPException(status_code=400, detail="Medicamento o cantidad inválida.")
        if med["stock"] < qty:
            raise HTTPException(status_code=400, detail=f"Stock insuficiente para {med['nombre']}. Disponible: {med['stock']}.")
        subtotal = float(med["precio"] or 0) * qty
        total += subtotal
        checked.append((med, qty, subtotal))
    venta = db_query(
        "INSERT INTO ventas_farmacia (paciente_id, usuario_id, observacion, total) VALUES (%s,%s,%s,%s) RETURNING *",
        [data.get("paciente_id"), data.get("usuario_id"), data.get("observacion"), total],
        fetch="one",
    )
    for med, qty, subtotal in checked:
        db_query("INSERT INTO venta_detalle (venta_id, medicamento_id, cantidad, precio_unitario, subtotal) VALUES (%s,%s,%s,%s,%s)", [venta["id"], med["id"], qty, med["precio"], subtotal], fetch="none")
        new_stock = med["stock"] - qty
        estado = "Agotado" if new_stock == 0 else ("Bajo stock" if new_stock <= med["stock_minimo"] else "Disponible")
        db_query("UPDATE medicamentos SET stock=%s, estado=%s, actualizado_en=NOW() WHERE id=%s", [new_stock, estado, med["id"]], fetch="none")
        db_query("INSERT INTO movimientos_stock (medicamento_id,tipo,cantidad,motivo,usuario_id) VALUES (%s,'Salida',%s,%s,%s)", [med["id"], qty, f"Venta registrada #{venta['id']}", data.get("usuario_id")], fetch="none")
    log_activity(data.get("usuario_id"), "Farmacia", "Venta", f"Se registró venta de farmacia por Bs {total:.2f}.")
    return created(venta)


@app.put("/api/sales/{sale_id}")
async def update_sale(sale_id: int, request: Request):
    data = await request.json()
    sale = db_query(
        "UPDATE ventas_farmacia SET total=%s, observacion=%s WHERE id=%s RETURNING *",
        [data.get("total") or 0, data.get("observacion"), sale_id],
        fetch="one",
    )
    if not sale:
        raise HTTPException(status_code=404, detail="Venta no encontrada.")
    log_activity(data.get("usuario_id"), "Ventas", "Corrección", f"Administración corrigió la venta #{sale_id}.")
    return sale


@app.post("/api/pharmacy/issues")
async def pharmacy_issue(request: Request):
    data = await request.json()
    admins = db_query("SELECT u.id FROM usuarios u JOIN roles r ON r.id=u.rol_id WHERE r.nombre='Administrador' AND u.estado='Activo'")
    for admin in admins:
        db_query(
            """
            INSERT INTO notificaciones (usuario_destino_id, destinatario, asunto, mensaje, canal, estado, tipo, leida)
            VALUES (%s,'Administrador','Revisión solicitada por farmacia',%s,'Sistema interno','Enviada','ERROR_FARMACIA',false)
            """,
            [admin["id"], f"Motivo: {data.get('motivo')}. Detalle: {data.get('detalle')}"],
            fetch="none",
        )
    log_activity(data.get("usuario_id"), "Farmacia", "Solicitud de revisión", f"Farmacia solicitó revisión: {data.get('motivo')}.")
    return {"ok": True}


@app.get("/api/notifications")
def notifications(usuario_id: Optional[str] = None, rol: str = "Administrador", paciente_id: Optional[str] = None, estado: str = "", unread_only: bool = False):
    params: List[Any] = []
    where = "WHERE 1=1"
    if estado:
        where += " AND n.estado=%s"; params.append(estado)
    if unread_only:
        where += " AND n.leida=false"
    if not usuario_id and paciente_id:
        where += " AND n.paciente_id=%s"; params.append(paciente_id)
    elif usuario_id:
        if rol == "Paciente" and paciente_id:
            where += " AND (n.usuario_destino_id=%s OR n.paciente_id=%s)"; params += [usuario_id, paciente_id]
        elif rol == "Administrador":
            where += " AND (n.usuario_destino_id=%s OR n.tipo IN ('ERROR_FARMACIA','SISTEMA'))"; params.append(usuario_id)
        elif rol == "Farmacia":
            where += " AND (n.usuario_destino_id=%s OR n.tipo='RECETA_FARMACIA')"; params.append(usuario_id)
        else:
            where += " AND (n.usuario_destino_id=%s OR n.tipo='RECORDATORIO_CITA')"; params.append(usuario_id)
    return db_query(
        f"""
        SELECT n.*, p.nombre || ' ' || p.apellido AS paciente
        FROM notificaciones n LEFT JOIN pacientes p ON p.id=n.paciente_id
        {where}
        ORDER BY n.leida ASC, n.creado_en DESC
        """,
        params,
    )


@app.get("/api/notifications/count")
def notifications_count(usuario_id: Optional[str] = None, rol: str = "Administrador", paciente_id: Optional[str] = None):
    return {"total": len(notifications(usuario_id, rol, paciente_id, unread_only=True))}


@app.patch("/api/notifications/{notification_id}/read")
def mark_notification_read(notification_id: int):
    row = db_query("UPDATE notificaciones SET leida=true WHERE id=%s RETURNING *", [notification_id], fetch="one")
    if not row:
        raise HTTPException(status_code=404, detail="Notificación no encontrada.")
    return row


@app.patch("/api/notifications/read-all")
async def mark_all_notifications_read(request: Request):
    data = await request.json()
    usuario_id = data.get("usuario_id")
    paciente_id = data.get("paciente_id")
    if paciente_id:
        db_query("UPDATE notificaciones SET leida=true WHERE usuario_destino_id=%s OR paciente_id=%s", [usuario_id, paciente_id], fetch="none")
    else:
        db_query("UPDATE notificaciones SET leida=true WHERE usuario_destino_id=%s", [usuario_id], fetch="none")
    return {"ok": True}


@app.post("/api/notifications/process-queue")
async def process_queue(request: Request):
    data = await request.json()
    items = db_query("SELECT * FROM cola_mensajes WHERE estado='Pendiente' ORDER BY creado_en ASC LIMIT 20")
    processed = 0
    for item in items:
        if item["tipo"] == "RECORDATORIO_CITA" and item["referencia_id"]:
            db_query("UPDATE notificaciones SET estado='Enviada', enviado_en=NOW() WHERE id=%s", [item["referencia_id"]], fetch="none")
        db_query("UPDATE cola_mensajes SET estado='Procesado', intentos=intentos+1, procesado_en=NOW() WHERE id=%s", [item["id"]], fetch="none")
        processed += 1
    log_activity(data.get("usuario_id"), "Notificaciones", "Procesar cola", f"Se procesaron {processed} mensajes de la cola.")
    return {"processed": processed}


@app.get("/api/queue")
def queue_items():
    return db_query("SELECT * FROM cola_mensajes ORDER BY creado_en DESC")


@app.get("/api/reports/appointments")
def report_appointments(from_: str = Query("2026-06-01", alias="from"), to: str = "2026-06-30", estado: str = "", medico_id: Optional[str] = None):
    params: List[Any] = [from_, to]
    where = "WHERE c.fecha BETWEEN %s AND %s"
    if estado:
        where += " AND c.estado=%s"; params.append(estado)
    if medico_id:
        where += " AND c.medico_id=%s"; params.append(medico_id)
    rows = db_query(
        f"""
        SELECT c.fecha, c.hora, c.estado, c.motivo,
               p.nombre || ' ' || p.apellido AS paciente,
               m.nombre || ' ' || m.apellido AS medico,
               e.nombre AS especialidad
        FROM citas c
        JOIN pacientes p ON p.id=c.paciente_id
        JOIN medicos m ON m.id=c.medico_id
        JOIN especialidades e ON e.id=c.especialidad_id
        {where}
        ORDER BY c.fecha DESC, c.hora DESC
        """,
        params,
    )
    summary = db_query(f"SELECT c.estado, COUNT(*)::int AS total FROM citas c {where} GROUP BY c.estado", params)
    by_doctor = db_query(
        f"""
        SELECT m.nombre || ' ' || m.apellido AS medico, COUNT(*)::int AS total
        FROM citas c JOIN medicos m ON m.id=c.medico_id {where}
        GROUP BY medico ORDER BY total DESC
        """,
        params,
    )
    return {"rows": rows, "summary": summary, "byDoctor": by_doctor, "total": len(rows)}


@app.get("/api/reports/pharmacy")
def report_pharmacy(from_: str = Query("2026-06-01", alias="from"), to: str = "2026-06-30"):
    sales_rows = sales(from_, to)
    top = db_query(
        """
        SELECT m.nombre, SUM(vd.cantidad)::int AS total
        FROM venta_detalle vd JOIN medicamentos m ON m.id=vd.medicamento_id JOIN ventas_farmacia v ON v.id=vd.venta_id
        WHERE v.fecha::date BETWEEN %s AND %s
        GROUP BY m.nombre ORDER BY total DESC
        """,
        [from_, to],
    )
    return {"sales": sales_rows, "top": top, "total": sum(float(x["total"] or 0) for x in sales_rows)}


@app.get("/api/roles")
def roles():
    return db_query("SELECT * FROM roles ORDER BY id")


@app.get("/api/users")
def users(search: str = "", rol: str = ""):
    params: List[Any] = []
    where = "WHERE 1=1"
    if search:
        term = f"%{search}%"
        where += " AND (u.nombre ILIKE %s OR u.apellido ILIKE %s OR u.correo ILIKE %s)"
        params += [term, term, term]
    if rol:
        where += " AND r.nombre=%s"
        params.append(rol)
    return db_query(
        f"""
        SELECT u.id, u.rol_id, u.nombre, u.apellido, u.correo, u.estado, u.foto_url, u.paciente_id, u.medico_id, r.nombre AS rol,
               p.nombre || ' ' || p.apellido AS paciente, m.nombre || ' ' || m.apellido AS medico
        FROM usuarios u JOIN roles r ON r.id=u.rol_id
        LEFT JOIN pacientes p ON p.id=u.paciente_id
        LEFT JOIN medicos m ON m.id=u.medico_id
        {where}
        ORDER BY r.id, u.nombre, u.apellido
        """,
        params,
    )


@app.post("/api/users")
async def create_user(request: Request):
    data = await request.json()
    if not data.get("password"):
        raise HTTPException(status_code=400, detail="La contraseña es obligatoria.")
    user = db_query(
        """
        INSERT INTO usuarios (rol_id,nombre,apellido,correo,password_hash,estado,foto_url,paciente_id,medico_id)
        VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s) RETURNING id, nombre, apellido, correo, estado, foto_url, paciente_id, medico_id
        """,
        [data.get("rol_id"), validate_name(data.get("nombre"), "Nombre"), validate_name(data.get("apellido"), "Apellido"), data.get("correo"), sha256(data.get("password")), data.get("estado", "Activo"), data.get("foto_url"), data.get("paciente_id") or None, data.get("medico_id") or None],
        fetch="one",
    )
    log_activity(data.get("usuario_id"), "Usuarios", "Registro", f"Se creó el usuario {user['correo']}.")
    return created(user)


@app.put("/api/users/{user_id}")
async def update_user(user_id: int, request: Request):
    data = await request.json()
    params = [data.get("rol_id"), validate_name(data.get("nombre"), "Nombre"), validate_name(data.get("apellido"), "Apellido"), data.get("correo"), data.get("estado", "Activo"), data.get("foto_url"), data.get("paciente_id") or None, data.get("medico_id") or None]
    sql = """
        UPDATE usuarios SET rol_id=%s,nombre=%s,apellido=%s,correo=%s,estado=%s,foto_url=%s,paciente_id=%s,medico_id=%s
    """
    if data.get("password"):
        sql += ", password_hash=%s"
        params.append(sha256(data.get("password")))
    params.append(user_id)
    sql += " WHERE id=%s RETURNING id,nombre,apellido,correo,estado,foto_url,paciente_id,medico_id"
    user = db_query(sql, params, fetch="one")
    if not user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado.")
    log_activity(data.get("usuario_id"), "Usuarios", "Actualización", f"Se actualizó el usuario {user['correo']}.")
    return user


@app.patch("/api/users/{user_id}/status")
async def user_status(user_id: int, request: Request):
    data = await request.json()
    user = db_query("UPDATE usuarios SET estado=%s WHERE id=%s RETURNING id,nombre,apellido,correo,estado", [data.get("estado"), user_id], fetch="one")
    if not user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado.")
    log_activity(data.get("usuario_id"), "Usuarios", "Cambio de estado", f"El usuario {user['correo']} ahora está {user['estado']}.")
    return user


@app.patch("/api/users/{user_id}/profile")
async def update_profile(user_id: int, request: Request):
    data = await request.json()
    user = db_query(
        """
        UPDATE usuarios SET nombre=%s, apellido=%s, correo=%s, foto_url=%s
        WHERE id=%s RETURNING id, nombre, apellido, correo, estado, foto_url, paciente_id, medico_id,
        (SELECT nombre FROM roles WHERE id=usuarios.rol_id) AS rol
        """,
        [validate_name(data.get("nombre"), "Nombre"), validate_name(data.get("apellido"), "Apellido"), data.get("correo"), data.get("foto_url"), user_id],
        fetch="one",
    )
    if not user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado.")
    user["nombre_completo"] = full_name(user)
    log_activity(user_id, "Perfil", "Actualización", "El usuario actualizó su perfil.")
    return user


@app.post("/api/upload/profile")
async def upload_profile(file: UploadFile = File(...), usuario_id: Optional[int] = Form(None)):
    if not file.content_type or not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="Solo se permiten imágenes para la foto de perfil.")
    ext = Path(file.filename or "foto.png").suffix.lower() or ".png"
    name = f"perfil_{usuario_id or 'user'}_{int(datetime.now().timestamp())}{ext}"
    target = PROFILE_DIR / name
    with target.open("wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
    url = f"/uploads/perfiles/{name}"
    if usuario_id:
        db_query("UPDATE usuarios SET foto_url=%s WHERE id=%s", [url, usuario_id], fetch="none")
    return {"url": url}


@app.post("/api/upload/clinical")
async def upload_clinical(expediente_id: int = Form(...), usuario_id: Optional[int] = Form(None), descripcion: str = Form("Archivo clínico adjunto"), file: UploadFile = File(...)):
    safe_name = re.sub(r"[^A-Za-z0-9_.-]", "_", file.filename or "archivo.pdf")
    name = f"exp_{expediente_id}_{int(datetime.now().timestamp())}_{safe_name}"
    target = CLINICAL_DIR / name
    with target.open("wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
    url = f"/uploads/clinicos/{name}"
    row = db_query(
        "INSERT INTO archivos_clinicos (expediente_id,nombre_archivo,tipo_archivo,storage_provider,storage_url,descripcion,subido_por) VALUES (%s,%s,%s,'Almacenamiento local simulado',%s,%s,%s) RETURNING *",
        [expediente_id, file.filename, file.content_type, url, descripcion, usuario_id],
        fetch="one",
    )
    log_activity(usuario_id, "Expediente clínico", "Archivo", f"Se adjuntó archivo clínico {file.filename}.")
    return row


@app.get("/api/logs")
def logs(rol: str = "", modulo: str = "", search: str = ""):
    params: List[Any] = []
    where = "WHERE 1=1"
    if rol:
        where += " AND r.nombre=%s"; params.append(rol)
    if modulo:
        where += " AND l.modulo ILIKE %s"; params.append(f"%{modulo}%")
    if search:
        where += " AND (l.detalle ILIKE %s OR l.accion ILIKE %s OR COALESCE(u.nombre || ' ' || u.apellido,'Sistema') ILIKE %s)"
        term = f"%{search}%"; params += [term, term, term]
    return db_query(
        f"""
        SELECT l.*, COALESCE(u.nombre || ' ' || u.apellido, 'Sistema') AS usuario, COALESCE(r.nombre, 'Sistema') AS rol
        FROM logs_actividad l
        LEFT JOIN usuarios u ON u.id=l.usuario_id
        LEFT JOIN roles r ON r.id=u.rol_id
        {where}
        ORDER BY l.creado_en DESC LIMIT 200
        """,
        params,
    )


@app.get("/api/patient-panel/{patient_id}")
def patient_panel(patient_id: int):
    record = medical_record(patient_id)
    citas = appointments(paciente_id=patient_id, sort="proximas")
    notifs = notifications(paciente_id=patient_id, rol="Paciente")
    return {"paciente": record["paciente"], "expediente": record, "citas": citas, "notificaciones": notifs}


if FRONTEND_DIST.exists():
    @app.get("/", include_in_schema=False)
    def serve_frontend_index():
        return FileResponse(
            FRONTEND_DIST / "index.html",
            headers={
                "Cache-Control": "no-cache, no-store, must-revalidate",
                "Pragma": "no-cache",
                "Expires": "0",
            },
        )

    app.mount("/assets", StaticFiles(directory=str(FRONTEND_DIST / "assets")), name="assets")
    app.mount("/", StaticFiles(directory=str(FRONTEND_DIST), html=True), name="frontend")
