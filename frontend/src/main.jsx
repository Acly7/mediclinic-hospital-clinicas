import React, { useEffect, useMemo, useState } from 'react';
import { createRoot } from 'react-dom/client';
import { apiFetch, apiUpload, formatDate, formatDateTime, formatTime, formatTime12, resolveFileUrl, todayISO } from './api';
import './styles.css';

const BLOOD_TYPES = ['O+','O-','A+','A-','B+','B-','AB+','AB-'];
const USER_STATES = ['Activo', 'Inactivo'];
const DOCTOR_STATES = ['Disponible', 'No disponible', 'Inactivo'];
const APPOINTMENT_STATES = ['Pendiente', 'Confirmada', 'Atendida', 'Cancelada'];
const PRESENTATIONS = ['Tabletas', 'Cápsulas', 'Jarabe', 'Ampollas', 'Inhalador', 'Bolsa', 'Suspensión'];
const CATEGORIES = ['Analgésico', 'Antiinflamatorio', 'Antibiótico', 'Gastroprotector', 'Antialérgico', 'Respiratorio', 'Antidiabético', 'Antihipertensivo', 'Solución'];

const NAV_ITEMS = [
  { key: 'dashboard', label: 'Dashboard', icon: 'dashboard', roles: ['Administrador', 'Recepcion', 'Medico', 'Farmacia'] },
  { key: 'patientHome', label: 'Mi panel', icon: 'heartPulse', roles: ['Paciente'] },
  { key: 'users', label: 'Usuarios', icon: 'users', roles: ['Administrador'] },
  { key: 'patients', label: 'Pacientes', icon: 'patients', roles: ['Administrador', 'Recepcion'] },
  { key: 'doctors', label: 'Médicos', icon: 'stethoscope', roles: ['Administrador'] },
  { key: 'appointments', label: 'Citas', icon: 'calendar', roles: ['Administrador', 'Recepcion', 'Medico'] },
  { key: 'records', label: 'Expedientes', icon: 'folder', roles: ['Administrador', 'Recepcion', 'Medico', 'Paciente'] },
  { key: 'pharmacy', label: 'Farmacia', icon: 'pill', roles: ['Administrador', 'Farmacia', 'Medico'] },
  { key: 'sales', label: 'Ventas', icon: 'cash', roles: ['Administrador', 'Farmacia'] },
  { key: 'notifications', label: 'Notificaciones', icon: 'bell', roles: ['Administrador', 'Recepcion', 'Medico', 'Farmacia', 'Paciente'] },
  { key: 'reports', label: 'Reportes', icon: 'reports', roles: ['Administrador', 'Recepcion'] },
  { key: 'logs', label: 'Logs', icon: 'logs', roles: ['Administrador'] },
  { key: 'profile', label: 'Perfil', icon: 'user', roles: ['Administrador', 'Recepcion', 'Medico', 'Farmacia', 'Paciente'] }
];

const emptyPatient = { nombre: '', apellido: '', ci: '', fecha_nacimiento: '', celular: '', direccion: '', tipo_sangre: 'O+', alergias: '', antecedentes: '', estado: 'Activo' };
const emptyDoctor = { especialidad_id: '', nombre: '', apellido: '', ci: '', correo: '', telefono: '', nro_matricula: '', estado: 'Disponible' };
const emptyAppointment = { paciente_id: '', medico_id: '', especialidad_id: '', fecha: todayISO(), hora: '', motivo: '', estado: 'Pendiente' };
const emptyMedicine = { codigo: '', nombre: '', presentacion: 'Tabletas', concentracion: '', categoria: 'Analgésico', precio: 0, stock: 0, stock_minimo: 5, fecha_vencimiento: '', estado: 'Disponible' };
const emptyUser = { rol_id: '', nombre: '', apellido: '', correo: '', password: '', estado: 'Activo', foto_url: '', paciente_id: '', medico_id: '' };

function Icon({ name, className = '' }) {
  const common = { className: `icon-svg ${className}`.trim(), viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: '2', strokeLinecap: 'round', strokeLinejoin: 'round', 'aria-hidden': 'true' };
  const icons = {
    cross: <><path d="M12 3v18" /><path d="M3 12h18" /></>,
    dashboard: <><rect x="3" y="3" width="7" height="8" rx="2" /><rect x="14" y="3" width="7" height="5" rx="2" /><rect x="14" y="12" width="7" height="9" rx="2" /><rect x="3" y="15" width="7" height="6" rx="2" /></>,
    patients: <><path d="M16 21v-2a4 4 0 0 0-4-4H7a4 4 0 0 0-4 4v2" /><circle cx="9.5" cy="7" r="4" /><path d="M19 8v6" /><path d="M16 11h6" /></>,
    users: <><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2" /><circle cx="9" cy="7" r="4" /><path d="M22 21v-2a4 4 0 0 0-3-3.87" /><path d="M16 3.13a4 4 0 0 1 0 7.75" /></>,
    user: <><circle cx="12" cy="8" r="4" /><path d="M4 21a8 8 0 0 1 16 0" /></>,
    stethoscope: <><path d="M6 3v5a4 4 0 0 0 8 0V3" /><path d="M10 12v3a5 5 0 0 0 10 0v-1" /><circle cx="20" cy="10" r="2" /><path d="M4 3h4" /><path d="M12 3h4" /></>,
    calendar: <><rect x="3" y="4" width="18" height="17" rx="2" /><path d="M16 2v4" /><path d="M8 2v4" /><path d="M3 10h18" /></>,
    folder: <><path d="M3 7a2 2 0 0 1 2-2h5l2 2h7a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2Z" /></>,
    pill: <><path d="M10.5 21 21 10.5a5 5 0 0 0-7-7L3.5 14a5 5 0 0 0 7 7Z" /><path d="m8.5 8.5 7 7" /></>,
    bell: <><path d="M18 8a6 6 0 0 0-12 0c0 7-3 7-3 9h18c0-2-3-2-3-9" /><path d="M13.73 21a2 2 0 0 1-3.46 0" /></>,
    reports: <><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8Z" /><path d="M14 2v6h6" /><path d="M8 13h8" /><path d="M8 17h6" /></>,
    logs: <><path d="M4 5h16" /><path d="M4 12h16" /><path d="M4 19h10" /><circle cx="18" cy="19" r="2" /></>,
    check: <><path d="M20 6 9 17l-5-5" /></>,
    edit: <><path d="M12 20h9" /><path d="M16.5 3.5a2.12 2.12 0 0 1 3 3L7 19l-4 1 1-4Z" /></>,
    paperclip: <><path d="m21.44 11.05-9.19 9.19a6 6 0 0 1-8.49-8.49l9.19-9.19a4 4 0 0 1 5.66 5.66l-9.2 9.19a2 2 0 0 1-2.83-2.83l8.49-8.48" /></>,
    heartPulse: <><path d="M20.8 4.6a5.5 5.5 0 0 0-7.8 0L12 5.6l-1-1a5.5 5.5 0 1 0-7.8 7.8l1 1L12 21l7.8-7.6 1-1a5.5 5.5 0 0 0 0-7.8Z" /><path d="M3.5 12h4l2-3 4 6 2-3h5" /></>,
    image: <><rect x="3" y="3" width="18" height="18" rx="2" /><circle cx="8.5" cy="8.5" r="1.5" /><path d="M21 15l-5-5L5 21" /></>,
    cash: <><rect x="2" y="6" width="20" height="12" rx="2"/><circle cx="12" cy="12" r="3"/><path d="M6 10v4M18 10v4"/></>,
    search: <><circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/></>,
    clock: <><circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/></>
  };
  return <svg {...common}>{icons[name] || icons.cross}</svg>;
}

function App() {
  const [user, setUser] = useState(() => {
    const saved = localStorage.getItem('mediclinic_user');
    return saved ? JSON.parse(saved) : null;
  });
  const [view, setView] = useState(() => {
    const saved = localStorage.getItem('mediclinic_user');
    if (!saved) return 'dashboard';
    const parsed = JSON.parse(saved);
    return parsed.rol === 'Paciente' ? 'patientHome' : 'dashboard';
  });
  const [noticeTick, setNoticeTick] = useState(0);

  const saveUser = (updated) => {
    const finalUser = { ...user, ...updated };
    localStorage.setItem('mediclinic_user', JSON.stringify(finalUser));
    setUser(finalUser);
  };
  const logout = () => { localStorage.removeItem('mediclinic_user'); setUser(null); setView('dashboard'); };
  if (!user) return <Login onLogin={(u) => { setUser(u); setView(u.rol === 'Paciente' ? 'patientHome' : 'dashboard'); }} />;

  const allowedItems = NAV_ITEMS.filter(item => item.roles.includes(user.rol));
  const safeView = allowedItems.some(x => x.key === view) ? view : allowedItems[0]?.key;
  const navigate = (target) => { setView(target); window.scrollTo({ top: 0, behavior: 'smooth' }); };

  return <div className="app-shell">
    <aside className="sidebar">
      <button className="side-profile" onClick={() => navigate('profile')} title="Abrir perfil">
        <UserAvatar user={user} />
        <div><h1>{user.nombre_completo || `${user.nombre} ${user.apellido}`}</h1><p>{user.rol}</p></div>
      </button>
      <nav className="nav-list scrollable-menu">
        {allowedItems.map(item => <button key={item.key} className={`nav-item ${safeView === item.key ? 'active' : ''}`} onClick={() => navigate(item.key)}><span className="nav-icon"><Icon name={item.icon} /></span>{item.label}</button>)}
      </nav>
      <button className="logout-card" onClick={logout}><Icon name="user" /> Cerrar sesión</button>
    </aside>
    <main className="main-panel">
      <header className="topbar">
        <div><p className="eyebrow">Sistema clínico integral</p><h2>{titleForView(safeView)}</h2></div>
        <div className="user-box top-brand-box"><Bell user={user} onOpen={() => navigate('notifications')} tick={noticeTick} /><div className="mini-logo"><span><Icon name="cross" /></span><div><b>MediClinic</b><small>Hospital de Clínicas</small></div></div></div>
      </header>
      {safeView === 'dashboard' && <Dashboard user={user} navigate={navigate} />}
      {safeView === 'patientHome' && <PatientHome user={user} navigate={navigate} />}
      {safeView === 'users' && <Users user={user} />}
      {safeView === 'patients' && <Patients user={user} />}
      {safeView === 'doctors' && <Doctors user={user} />}
      {safeView === 'appointments' && <Appointments user={user} />}
      {safeView === 'records' && <Records user={user} />}
      {safeView === 'pharmacy' && <Pharmacy user={user} />}
      {safeView === 'sales' && <Sales user={user} />}
      {safeView === 'notifications' && <Notifications user={user} refreshBell={() => setNoticeTick(t => t + 1)} />}
      {safeView === 'reports' && <Reports />}
      {safeView === 'logs' && <Logs />}
      {safeView === 'profile' && <Profile user={user} onUpdate={saveUser} refreshBell={() => setNoticeTick(t => t + 1)} />}
    </main>
  </div>;
}

function titleForView(view) { return NAV_ITEMS.find(x => x.key === view)?.label || 'Dashboard'; }

function Login({ onLogin }) {
  const [correo, setCorreo] = useState('admin@mediclinic.bo');
  const [password, setPassword] = useState('admin123');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const submit = async (e) => { e.preventDefault(); setLoading(true); setError(''); try { const data = await apiFetch('/auth/login', { method: 'POST', body: JSON.stringify({ correo, password }) }); localStorage.setItem('mediclinic_user', JSON.stringify(data.user)); onLogin(data.user); } catch (err) { setError(err.message); } finally { setLoading(false); } };
  const quick = (mail, pass) => { setCorreo(mail); setPassword(pass); };
  return <div className="login-page improved-login">
    <div className="login-hero">
      <div className="clinic-badge"><Icon name="cross" /> Hospital de Clínicas</div>
      <h1>MediClinic</h1>
      <p>MediClinic ayuda a organizar la atención de pacientes, citas médicas, expedientes clínicos y farmacia desde una sola plataforma. Está pensado para un hospital con varios roles de trabajo y trazabilidad de cada movimiento.</p>
      <div className="hero-list clean-hero-list">
        <div><Icon name="calendar" /><b>Citas médicas</b></div>
        <div><Icon name="folder" /><b>Expedientes clínicos</b></div>
        <div><Icon name="pill" /><b>Farmacia y ventas</b></div>
      </div>
    </div>
    <form className="login-card" onSubmit={submit}>
      <div className="login-icon"><Icon name="stethoscope" /></div>
      <h2>Ingresar al sistema</h2><p>Ingresa con tus credenciales o prueba un perfil demo.</p>
      {error && <Alert type="error" message={error} />}
      <Input label="Correo" value={correo} onChange={setCorreo} type="email" required />
      <Input label="Contraseña" value={password} onChange={setPassword} type="password" required />
      <button className="primary-btn wide" disabled={loading}>{loading ? 'Ingresando...' : 'Entrar'}</button>
      <div className="quick-login nice-quick-login text-only-login"><button type="button" onClick={() => quick('admin@mediclinic.bo','admin123')}>Administrador</button><button type="button" onClick={() => quick('recepcion@mediclinic.bo','recepcion123')}>Recepción</button><button type="button" onClick={() => quick('doctor@mediclinic.bo','doctor123')}>Médico</button><button type="button" onClick={() => quick('farmacia@mediclinic.bo','farmacia123')}>Farmacia</button><button type="button" onClick={() => quick('juan.perez@paciente.bo','paciente123')}>Paciente</button></div>
    </form>
  </div>;
}

function Bell({ user, onOpen, tick }) {
  const [count, setCount] = useState(0);
  const [open, setOpen] = useState(false);
  const [items, setItems] = useState([]);
  const load = async () => {
    const qs = `usuario_id=${user.id}&rol=${encodeURIComponent(user.rol)}&paciente_id=${user.paciente_id || ''}`;
    const [c, n] = await Promise.all([apiFetch(`/notifications/count?${qs}`), apiFetch(`/notifications?${qs}&unread_only=true`)]);
    setCount(c.total); setItems(n.slice(0, 5));
  };
  useEffect(() => { load().catch(() => {}); }, [user.id, tick]);
  const click = async () => { setOpen(!open); if (!open) await load().catch(() => {}); };
  const markAndOpen = async (id) => { await apiFetch(`/notifications/${id}/read`, { method: 'PATCH' }); setOpen(false); await load(); onOpen(); };
  return <div className="bell-wrap"><button className="icon-btn bell-button" title="Ver notificaciones" onClick={click}><Icon name="bell" />{count > 0 && <span className="bell-count">{count}</span>}</button>{open && <div className="notification-popover"><h4>Notificaciones nuevas</h4>{items.length ? items.map(n => <button key={n.id} className="notice-preview unread" onClick={() => markAndOpen(n.id)}><b>{n.asunto}</b><span>{n.mensaje}</span></button>) : <p className="muted">No hay notificaciones nuevas.</p>}<button className="secondary-btn wide" onClick={onOpen}>Ver todas</button></div>}</div>;
}

function Dashboard({ user, navigate }) {
  const [data, setData] = useState(null), [error, setError] = useState('');
  useEffect(() => { apiFetch(`/dashboard?usuario_id=${user.id}&rol=${user.rol}&paciente_id=${user.paciente_id || ''}&medico_id=${user.medico_id || ''}`).then(setData).catch(e => setError(e.message)); }, [user.id]);
  if (error) return <ErrorBox message={error} />; if (!data) return <Loading />;
  const cards = data.cards || {};
  return <section className="content-grid">
    <MetricCard label="Pacientes activos" value={cards.pacientes} icon="patients" hint="Registrados" onClick={() => navigate('patients')} />
    <MetricCard label="Citas de hoy" value={cards.citas_hoy} icon="calendar" hint="Agenda diaria" onClick={() => navigate('appointments')} />
    <MetricCard label="Atendidas hoy" value={cards.atendidas_hoy} icon="check" hint="Completadas" onClick={() => navigate('appointments')} />
    <MetricCard label="Stock crítico" value={cards.bajo_stock} icon="pill" hint="Farmacia" onClick={() => navigate('pharmacy')} />
    <MetricCard label="Ventas de hoy" value={`Bs ${Number(cards.ventas_hoy || 0).toFixed(2)}`} icon="cash" hint="Farmacia" onClick={() => navigate('pharmacy')} />
    <div className="panel span-2"><PanelHeader title="Pacientes atendidos por día" /><BarChart data={data.pacientesAtendidos} labelKey="fecha" valueKey="total" /></div>
    <div className="panel"><PanelHeader title="Medicamentos más recetados" /><DonutChart data={data.medicamentosRecetados} labelKey="nombre" valueKey="total" /></div>
    <div className="panel"><PanelHeader title="Citas por especialidad" /><DonutChart data={data.citasPorEspecialidad} labelKey="nombre" valueKey="total" /></div>
    <div className="panel"><PanelHeader title="Estado de citas" /><StatusPills data={data.citasPorEstado} /></div>
    <div className="panel"><PanelHeader title="Medicamentos críticos" /><DataList data={data.stockCritico} labelKey="nombre" valueKey="stock" /></div>
    <div className="panel span-2"><PanelHeader title="Citas de hoy" action={<button className="secondary-btn" onClick={() => navigate('appointments')}>Abrir agenda</button>} /><AppointmentMiniList appointments={data.citasHoy} /></div>
    <div className="panel span-1"><PanelHeader title="Actividad reciente" /><Timeline items={data.actividad} /></div>
  </section>;
}

function PatientHome({ user, navigate }) {
  const [data, setData] = useState(null), [error, setError] = useState('');
  useEffect(() => { if (user.paciente_id) apiFetch(`/patient-panel/${user.paciente_id}`).then(setData).catch(e => setError(e.message)); }, [user.paciente_id]);
  if (!user.paciente_id) return <Alert type="error" message="Este usuario paciente no está vinculado a una ficha clínica." />;
  if (error) return <ErrorBox message={error} />; if (!data) return <Loading />;
  const pending = data.citas.filter(c => ['Pendiente','Confirmada'].includes(c.estado));
  return <section className="content-grid patient-dashboard">
    <MetricCard label="Mis citas activas" value={pending.length} icon="calendar" hint="Pendientes o confirmadas" onClick={() => navigate('records')} />
    <MetricCard label="Notificaciones" value={data.notificaciones.filter(n => !n.leida).length} icon="bell" hint="Sin leer" onClick={() => navigate('notifications')} />
    <div className="panel"><PanelHeader title="Mi ficha" /><PatientCard patient={data.paciente} expediente={data.expediente.expediente} /></div>
    <div className="panel span-2"><PanelHeader title="Mis próximas citas" /><AppointmentMiniList appointments={pending} /></div>
    <div className="panel span-3"><PanelHeader title="Mi expediente" /><RecordDetail record={data.expediente} /></div>
  </section>;
}

function Users({ user }) {
  const [users, setUsers] = useState([]), [roles, setRoles] = useState([]), [patients, setPatients] = useState([]), [doctors, setDoctors] = useState([]);
  const [form, setForm] = useState(emptyUser), [editing, setEditing] = useState(null), [search, setSearch] = useState(''), [rol, setRol] = useState(''), [msg, setMsg] = useState(''), [err, setErr] = useState(''), [file, setFile] = useState(null);
  const load = async () => { const [u, r, p, d] = await Promise.all([apiFetch(`/users?search=${encodeURIComponent(search)}&rol=${encodeURIComponent(rol)}`), apiFetch('/roles'), apiFetch('/patients'), apiFetch('/doctors')]); setUsers(u); setRoles(r); setPatients(p); setDoctors(d); };
  useEffect(() => { load().catch(e => setErr(e.message)); }, []);
  const uploadTemp = async () => { if (!file) return form.foto_url; const fd = new FormData(); fd.append('file', file); if (editing) fd.append('usuario_id', editing); const res = await apiUpload('/upload/profile', fd); return res.url; };
  const submit = async (e) => { e.preventDefault(); setErr(''); setMsg(''); try { const foto_url = await uploadTemp(); const path = editing ? `/users/${editing}` : '/users'; const method = editing ? 'PUT' : 'POST'; await apiFetch(path, { method, body: JSON.stringify({ ...form, foto_url, usuario_id: user.id }) }); setForm(emptyUser); setEditing(null); setFile(null); setMsg(editing ? 'Usuario actualizado correctamente.' : 'Usuario creado correctamente.'); load(); } catch (e) { setErr(e.message); } };
  const edit = (u) => { setEditing(u.id); setForm({ rol_id: u.rol_id, nombre: u.nombre, apellido: u.apellido, correo: u.correo, password: '', estado: u.estado, foto_url: u.foto_url || '', paciente_id: u.paciente_id || '', medico_id: u.medico_id || '' }); window.scrollTo({ top: 0, behavior: 'smooth' }); };
  const toggle = async (u) => { const estado = u.estado === 'Activo' ? 'Inactivo' : 'Activo'; await apiFetch(`/users/${u.id}/status`, { method: 'PATCH', body: JSON.stringify({ estado, usuario_id: user.id }) }); load(); };
  return <section className="two-column">
    <div className="panel"><PanelHeader title={editing ? 'Editar usuario' : 'Nuevo usuario'} subtitle="Admins, médicos, recepción, farmacia y pacientes" />{msg && <Alert type="success" message={msg} />}{err && <Alert type="error" message={err} />}
      <form className="form-grid" onSubmit={submit}>
        <label>Rol<select value={form.rol_id} onChange={e => setForm({ ...form, rol_id: e.target.value })} required><option value="">Seleccionar</option>{roles.map(r => <option key={r.id} value={r.id}>{r.nombre}</option>)}</select></label>
        <label>Estado<select value={form.estado} onChange={e => setForm({ ...form, estado: e.target.value })}>{USER_STATES.map(s => <option key={s}>{s}</option>)}</select></label>
        <Input label="Nombre" value={form.nombre} onChange={v => setForm({ ...form, nombre: v })} required />
        <Input label="Apellido" value={form.apellido} onChange={v => setForm({ ...form, apellido: v })} required />
        <Input label="Correo" type="email" value={form.correo} onChange={v => setForm({ ...form, correo: v })} required />
        <Input label={editing ? 'Nueva contraseña opcional' : 'Contraseña'} type="password" value={form.password} onChange={v => setForm({ ...form, password: v })} required={!editing} />
        <label>Paciente vinculado<select value={form.paciente_id} onChange={e => setForm({ ...form, paciente_id: e.target.value })}><option value="">Sin vínculo</option>{patients.map(p => <option key={p.id} value={p.id}>{p.nombre} {p.apellido} · {p.ci}</option>)}</select></label>
        <label>Médico vinculado<select value={form.medico_id} onChange={e => setForm({ ...form, medico_id: e.target.value, hora: '' })}><option value="">Sin vínculo</option>{doctors.map(d => <option key={d.id} value={d.id}>{d.nombre} {d.apellido} · {d.especialidad}</option>)}</select></label>
        <label className="full-field">Foto de perfil<input type="file" accept="image/*" onChange={e => setFile(e.target.files?.[0] || null)} /></label>
        <button className="primary-btn wide">{editing ? 'Guardar cambios' : 'Crear usuario'}</button>{editing && <button type="button" className="secondary-btn wide" onClick={() => { setEditing(null); setForm(emptyUser); setFile(null); }}>Cancelar edición</button>}
      </form></div>
    <div className="panel large-panel"><PanelHeader title="Usuarios del sistema" /><div className="filters"><input value={search} onChange={e => setSearch(e.target.value)} placeholder="Buscar usuario..." /><select value={rol} onChange={e => setRol(e.target.value)}><option value="">Todos los roles</option>{roles.map(r => <option key={r.id}>{r.nombre}</option>)}</select><button className="secondary-btn" onClick={load}>Buscar</button><button className="ghost-btn" onClick={() => { setSearch(''); setRol(''); setTimeout(load,0); }}>Limpiar filtros</button></div><TableUsers users={users} onEdit={edit} onToggle={toggle} /></div>
  </section>;
}

function Patients({ user }) {
  const [patients, setPatients] = useState([]), [search, setSearch] = useState(''), [form, setForm] = useState(emptyPatient), [editing, setEditing] = useState(null), [msg, setMsg] = useState(''), [err, setErr] = useState('');
  const load = () => apiFetch(`/patients?search=${encodeURIComponent(search)}`).then(setPatients).catch(e => setErr(e.message));
  useEffect(() => { load(); }, []);
  const submit = async (e) => { e.preventDefault(); setErr(''); setMsg(''); try { if (form.fecha_nacimiento >= todayISO()) throw new Error('La fecha de nacimiento debe ser anterior a hoy.'); const path = editing ? `/patients/${editing}` : '/patients'; const method = editing ? 'PUT' : 'POST'; await apiFetch(path, { method, body: JSON.stringify({ ...form, usuario_id: user.id }) }); setForm(emptyPatient); setEditing(null); setMsg(editing ? 'Paciente actualizado correctamente.' : 'Paciente registrado y expediente creado.'); load(); } catch (e) { setErr(e.message); } };
  const edit = (p) => { setEditing(p.id); setForm({ nombre: p.nombre, apellido: p.apellido, ci: p.ci, fecha_nacimiento: String(p.fecha_nacimiento).slice(0,10), celular: p.celular || '', direccion: p.direccion || '', tipo_sangre: p.tipo_sangre || 'O+', alergias: p.alergias || '', antecedentes: p.antecedentes || '', estado: p.estado }); };
  const toggle = async (p) => { await apiFetch(`/patients/${p.id}/status`, { method: 'PATCH', body: JSON.stringify({ estado: p.estado === 'Activo' ? 'Inactivo' : 'Activo', usuario_id: user.id }) }); load(); };
  return <section className="two-column"><div className="panel"><PanelHeader title={editing ? 'Editar paciente' : 'Registrar paciente'} />{msg && <Alert type="success" message={msg} />}{err && <Alert type="error" message={err} />}
    <form className="form-grid" onSubmit={submit}><Input label="Nombre" value={form.nombre} onChange={v => setForm({ ...form, nombre: v })} required /><Input label="Apellido" value={form.apellido} onChange={v => setForm({ ...form, apellido: v })} required /><Input label="CI" value={form.ci} onChange={v => setForm({ ...form, ci: v.replace(/\D/g,'') })} required /><Input label="Fecha nacimiento" type="date" value={form.fecha_nacimiento} onChange={v => setForm({ ...form, fecha_nacimiento: v })} max={todayISO()} required /><Input label="Celular" value={form.celular} onChange={v => setForm({ ...form, celular: v.replace(/\D/g,'') })} /><label>Tipo sangre<select value={form.tipo_sangre} onChange={e => setForm({ ...form, tipo_sangre: e.target.value })}>{BLOOD_TYPES.map(t => <option key={t}>{t}</option>)}</select></label><label>Estado<select value={form.estado} onChange={e => setForm({ ...form, estado: e.target.value })}>{USER_STATES.map(s => <option key={s}>{s}</option>)}</select></label><TextArea label="Dirección" value={form.direccion} onChange={v => setForm({ ...form, direccion: v })} /><TextArea label="Alergias" value={form.alergias} onChange={v => setForm({ ...form, alergias: v })} /><TextArea label="Antecedentes" value={form.antecedentes} onChange={v => setForm({ ...form, antecedentes: v })} /><button className="primary-btn wide">{editing ? 'Guardar cambios' : 'Guardar paciente'}</button>{editing && <button type="button" className="secondary-btn wide" onClick={() => { setEditing(null); setForm(emptyPatient); }}>Cancelar edición</button>}</form></div>
    <div className="panel large-panel"><PanelHeader title="Pacientes registrados" /><div className="search-row"><input value={search} onChange={e => setSearch(e.target.value)} placeholder="Buscar por nombre, apellido o CI" /><button className="secondary-btn" onClick={load}>Buscar</button><button className="ghost-btn" onClick={() => { setSearch(''); setTimeout(load,0); }}>Limpiar filtros</button></div><TablePatients patients={patients} onEdit={edit} onToggle={toggle} /></div></section>;
}

function Doctors({ user }) {
  const [doctors, setDoctors] = useState([]), [specialties, setSpecialties] = useState([]), [form, setForm] = useState(emptyDoctor), [editing, setEditing] = useState(null), [msg, setMsg] = useState(''), [err, setErr] = useState('');
  const [filters, setFilters] = useState({ search: '', especialidad: '', estado: '' });
  const load = async () => { const [d, s] = await Promise.all([apiFetch('/doctors'), apiFetch('/specialties')]); setDoctors(d); setSpecialties(s); };
  useEffect(() => { load().catch(e => setErr(e.message)); }, []);
  const submit = async (e) => { e.preventDefault(); setErr(''); setMsg(''); try { const path = editing ? `/doctors/${editing}` : '/doctors'; const method = editing ? 'PUT' : 'POST'; await apiFetch(path, { method, body: JSON.stringify({ ...form, usuario_id: user.id }) }); setForm(emptyDoctor); setEditing(null); setMsg(editing ? 'Médico actualizado.' : 'Médico registrado.'); load(); } catch (e) { setErr(e.message); } };
  const edit = (d) => { setEditing(d.id); setForm({ especialidad_id: d.especialidad_id, nombre: d.nombre, apellido: d.apellido, ci: d.ci, correo: d.correo || '', telefono: d.telefono || '', nro_matricula: d.nro_matricula || '', estado: d.estado }); };
  const toggle = async (d) => { await apiFetch(`/doctors/${d.id}/status`, { method: 'PATCH', body: JSON.stringify({ estado: d.estado === 'Disponible' ? 'Inactivo' : 'Disponible', usuario_id: user.id }) }); load(); };
  const resetFilters = () => setFilters({ search: '', especialidad: '', estado: '' });
  const visibleDoctors = doctors.filter(d => { const text = `${d.nombre} ${d.apellido} ${d.ci} ${d.nro_matricula} ${d.especialidad}`.toLowerCase(); return (!filters.search || text.includes(filters.search.toLowerCase())) && (!filters.especialidad || String(d.especialidad_id) === String(filters.especialidad)) && (!filters.estado || d.estado === filters.estado); });
  return <section className="content-grid"><div className="panel span-2"><PanelHeader title="Equipo médico" />{err && <Alert type="error" message={err} />}<div className="filters"><input value={filters.search} onChange={e => setFilters({ ...filters, search: e.target.value })} placeholder="Buscar médico por nombre, CI o matrícula" /><select value={filters.especialidad} onChange={e => setFilters({ ...filters, especialidad: e.target.value })}><option value="">Todas las especialidades</option>{specialties.map(s => <option key={s.id} value={s.id}>{s.nombre}</option>)}</select><select value={filters.estado} onChange={e => setFilters({ ...filters, estado: e.target.value })}><option value="">Todos los estados</option>{DOCTOR_STATES.map(s => <option key={s}>{s}</option>)}</select><button className="secondary-btn" onClick={load}>Buscar</button><button className="ghost-btn" onClick={resetFilters}>Limpiar filtros</button></div><div className="doctor-grid">{visibleDoctors.map(doc => <article className="doctor-card" key={doc.id}><div className="doctor-avatar">{doc.nombre[0]}{doc.apellido[0]}</div><div><h3>Dr(a). {doc.nombre} {doc.apellido}</h3><p>{doc.especialidad}</p><span>{doc.nro_matricula} · {doc.telefono}</span></div><div className="card-actions"><Badge value={doc.estado} /><button className="tiny-btn" onClick={() => edit(doc)}>Editar</button><button className="tiny-btn" onClick={() => toggle(doc)}>{doc.estado === 'Disponible' ? 'Desactivar' : 'Activar'}</button></div></article>)}</div></div><div className="panel"><PanelHeader title={editing ? 'Editar médico' : 'Nuevo médico'} />{msg && <Alert type="success" message={msg} />}<form className="form-grid" onSubmit={submit}><label className="full-field">Especialidad<select value={form.especialidad_id} onChange={e => setForm({ ...form, especialidad_id: e.target.value })} required><option value="">Seleccionar</option>{specialties.map(s => <option key={s.id} value={s.id}>{s.nombre}</option>)}</select></label><Input label="Nombre" value={form.nombre} onChange={v => setForm({ ...form, nombre: v })} required /><Input label="Apellido" value={form.apellido} onChange={v => setForm({ ...form, apellido: v })} required /><Input label="CI" value={form.ci} onChange={v => setForm({ ...form, ci: v.replace(/\D/g,'') })} required /><Input label="Correo" value={form.correo} onChange={v => setForm({ ...form, correo: v })} /><Input label="Teléfono" value={form.telefono} onChange={v => setForm({ ...form, telefono: v.replace(/\D/g,'') })} /><Input label="Matrícula" value={form.nro_matricula} onChange={v => setForm({ ...form, nro_matricula: v })} /><label>Estado<select value={form.estado} onChange={e => setForm({ ...form, estado: e.target.value })}>{DOCTOR_STATES.map(s => <option key={s}>{s}</option>)}</select></label><button className="primary-btn wide">Guardar médico</button>{editing && <button type="button" className="secondary-btn wide" onClick={() => { setEditing(null); setForm(emptyDoctor); }}>Cancelar edición</button>}</form></div></section>;
}

function Appointments({ user }) {
  const [appointments, setAppointments] = useState([]), [patients, setPatients] = useState([]), [doctors, setDoctors] = useState([]), [specialties, setSpecialties] = useState([]);
  const [form, setForm] = useState(emptyAppointment), [editing, setEditing] = useState(null), [filters, setFilters] = useState({ fecha: '', estado: '', medico_id: user.rol === 'Medico' ? user.medico_id || '' : '', search: '', hora: '', sort: 'proximas' });
  const [slots, setSlots] = useState(null), [msg, setMsg] = useState(''), [err, setErr] = useState('');
  const loadBase = async () => { const [p, d, s] = await Promise.all([apiFetch('/patients'), apiFetch('/doctors'), apiFetch('/specialties')]); setPatients(p); setDoctors(d); setSpecialties(s); };
  const load = () => apiFetch(`/appointments?fecha=${filters.fecha}&estado=${filters.estado}&medico_id=${filters.medico_id}&search=${encodeURIComponent(filters.search)}&hora=${filters.hora}&sort=${filters.sort}`).then(setAppointments).catch(e => setErr(e.message));
  useEffect(() => { loadBase(); load(); }, []);
  useEffect(() => { load(); }, [filters.sort]);
  useEffect(() => { if (form.medico_id && form.fecha) apiFetch(`/doctors/${form.medico_id}/availability?fecha=${form.fecha}${editing ? `&exclude_id=${editing}` : ''}`).then(setSlots).catch(() => setSlots(null)); }, [form.medico_id, form.fecha, editing]);
  const submit = async (e) => { e.preventDefault(); setMsg(''); setErr(''); try { if (form.fecha < todayISO()) throw new Error('No se puede agendar una cita en una fecha pasada.'); const path = editing ? `/appointments/${editing}` : '/appointments'; const method = editing ? 'PUT' : 'POST'; await apiFetch(path, { method, body: JSON.stringify({ ...form, usuario_id: user.id }) }); setForm(emptyAppointment); setEditing(null); setMsg(editing ? 'Cita actualizada correctamente.' : 'Cita agendada y recordatorio generado.'); load(); } catch (e) { setErr(e.message); } };
  const setStatus = async (id, estado) => { await apiFetch(`/appointments/${id}/status`, { method: 'PATCH', body: JSON.stringify({ estado, usuario_id: user.id }) }); load(); };
  const edit = (c) => { setEditing(c.id); setForm({ paciente_id: c.paciente_id, medico_id: c.medico_id, especialidad_id: c.especialidad_id, fecha: String(c.fecha).slice(0,10), hora: formatTime(c.hora), motivo: c.motivo || '', estado: c.estado }); window.scrollTo({ top: 0, behavior: 'smooth' }); };
  const filteredDoctors = form.especialidad_id ? doctors.filter(d => String(d.especialidad_id) === String(form.especialidad_id)) : doctors;
  const availableHours = useMemo(() => (slots?.slots || []).filter(s => !s.ocupado), [slots]);
  const hourPlaceholder = !form.medico_id || !form.fecha ? 'Selecciona médico y fecha' : availableHours.length ? 'Seleccionar' : 'Sin horarios disponibles';
  return <section className="appointments-layout"><div className="panel"><PanelHeader title={editing ? 'Editar cita' : 'Agendar cita'} />{msg && <Alert type="success" message={msg} />}{err && <Alert type="error" message={err} />}<form className="form-grid" onSubmit={submit}><label>Paciente<select value={form.paciente_id} onChange={e => setForm({ ...form, paciente_id: e.target.value })} required><option value="">Seleccionar</option>{patients.map(p => <option key={p.id} value={p.id}>{p.nombre} {p.apellido} · {p.ci}</option>)}</select></label><label>Especialidad<select value={form.especialidad_id} onChange={e => setForm({ ...form, especialidad_id: e.target.value, medico_id: '', hora: '' })} required><option value="">Seleccionar</option>{specialties.map(s => <option key={s.id} value={s.id}>{s.nombre}</option>)}</select></label><label>Médico<select value={form.medico_id} onChange={e => setForm({ ...form, medico_id: e.target.value })} required><option value="">Seleccionar</option>{filteredDoctors.map(d => <option key={d.id} value={d.id}>Dr(a). {d.nombre} {d.apellido} · {d.estado}</option>)}</select></label><Input label="Fecha" type="date" value={form.fecha} onChange={v => setForm({ ...form, fecha: v, hora: '' })} min={todayISO()} required /><label>Hora disponible<select value={form.hora} onChange={e => setForm({ ...form, hora: e.target.value })} required><option value="">{hourPlaceholder}</option>{availableHours.map(s => <option key={s.hora} value={s.hora}>{s.hora} · {s.consultorio || 'Disponible'}</option>)}</select></label><label>Estado<select value={form.estado} onChange={e => setForm({ ...form, estado: e.target.value })}>{APPOINTMENT_STATES.map(s => <option key={s}>{s}</option>)}</select></label><TextArea label="Motivo" value={form.motivo} onChange={v => setForm({ ...form, motivo: v })} required /><button className="primary-btn wide">{editing ? 'Guardar cambios' : 'Agendar cita'}</button>{editing && <button type="button" className="secondary-btn wide" onClick={() => { setEditing(null); setForm(emptyAppointment); }}>Cancelar edición</button>}</form>{slots && <Availability slots={slots} />}</div><div className="panel large-panel"><PanelHeader title="Agenda médica" /><div className="filters agenda-filters"><input placeholder="Buscar paciente, CI o médico" value={filters.search} onChange={e => setFilters({ ...filters, search: e.target.value })} /><Input type="date" label="Fecha" value={filters.fecha} onChange={v => setFilters({ ...filters, fecha: v })} /><Input type="time" label="Hora" value={filters.hora} onChange={v => setFilters({ ...filters, hora: v })} /><select value={filters.medico_id} onChange={e => setFilters({ ...filters, medico_id: e.target.value })}><option value="">Todos los médicos</option>{doctors.map(d => <option key={d.id} value={d.id}>{d.nombre} {d.apellido}</option>)}</select><select value={filters.estado} onChange={e => setFilters({ ...filters, estado: e.target.value })}><option value="">Todos los estados</option>{APPOINTMENT_STATES.map(s => <option key={s}>{s}</option>)}</select><select value={filters.sort} onChange={e => setFilters({ ...filters, sort: e.target.value })}><option value="proximas">Próximas primero</option><option value="recientes">Más recientes primero</option></select><button className="secondary-btn" onClick={load}>Buscar</button><button className="ghost-btn" onClick={() => { setFilters({ fecha: '', estado: '', medico_id: user.rol === 'Medico' ? user.medico_id || '' : '', search: '', hora: '', sort: 'proximas' }); setTimeout(load, 0); }}>Limpiar filtros</button></div><div className="appointment-list">{appointments.map(c => <AppointmentCard key={c.id} cita={c} onStatus={setStatus} onEdit={edit} />)}</div></div></section>;
}

function Availability({ slots }) { return <div className="availability"><h4>Disponibilidad del médico para {slots.dia}</h4>{slots.slots.length ? <div className="slot-grid">{slots.slots.map(s => <span key={s.hora} className={s.ocupado ? 'slot busy' : 'slot free'}>{s.hora}<small>{s.ocupado ? 'Ocupado' : s.consultorio || 'Libre'}</small></span>)}</div> : <p className="muted">El médico no atiende este día.</p>}</div>; }

function Records({ user }) {
  const [records, setRecords] = useState([]), [search, setSearch] = useState(''), [patientId, setPatientId] = useState(user.rol === 'Paciente' ? user.paciente_id : ''), [record, setRecord] = useState(null), [doctors, setDoctors] = useState([]), [medicines, setMedicines] = useState([]);
  const [form, setForm] = useState({ medico_id: user.medico_id || '', diagnostico: '', tratamiento: '', observaciones: '', indicaciones: '', medicamento_id: '', cantidad: 1, dosis: '', frecuencia: '', dias: 1, archivo_desc: '', archivo: null });
  const [msg, setMsg] = useState(''), [err, setErr] = useState('');
  const loadList = () => apiFetch(`/records?search=${encodeURIComponent(search)}`).then(setRecords).catch(e => setErr(e.message));
  const loadRecord = (id = patientId) => { if (!id) return; apiFetch(`/records/${id}`).then(setRecord).catch(e => setErr(e.message)); };
  useEffect(() => { loadList(); apiFetch('/doctors').then(setDoctors); apiFetch('/medicines').then(setMedicines); }, []);
  useEffect(() => { if (patientId) loadRecord(patientId); }, [patientId]);
  const submit = async (e) => { e.preventDefault(); setMsg(''); setErr(''); try { const meds = form.medicamento_id ? [{ medicamento_id: form.medicamento_id, cantidad: Number(form.cantidad), dosis: form.dosis, frecuencia: form.frecuencia, dias: Number(form.dias) }] : []; await apiFetch('/consultations', { method: 'POST', body: JSON.stringify({ paciente_id: patientId, medico_id: form.medico_id, diagnostico: form.diagnostico, tratamiento: form.tratamiento, observaciones: form.observaciones, indicaciones: form.indicaciones, medicamentos: meds, usuario_id: user.id }) }); if (form.archivo && record?.expediente?.id) { const fd = new FormData(); fd.append('expediente_id', record.expediente.id); fd.append('usuario_id', user.id); fd.append('descripcion', form.archivo_desc || 'Archivo clínico adjunto'); fd.append('file', form.archivo); await apiUpload('/upload/clinical', fd); } setForm({ ...form, diagnostico: '', tratamiento: '', observaciones: '', indicaciones: '', medicamento_id: '', cantidad: 1, dosis: '', frecuencia: '', dias: 1, archivo_desc: '', archivo: null }); setMsg('Expediente actualizado correctamente. Farmacia recibirá aviso si se registró receta.'); loadRecord(patientId); } catch (e) { setErr(e.message); } };
  return <section className="records-layout"><div className="panel"><PanelHeader title="Buscar expediente" /><div className="search-row"><input value={search} onChange={e => setSearch(e.target.value)} placeholder="Buscar paciente o expediente..." /><button className="secondary-btn" onClick={loadList}><Icon name="search" /> Buscar</button><button className="ghost-btn" onClick={() => { setSearch(''); setTimeout(loadList, 0); }}>Limpiar filtros</button></div><label>Paciente<select value={patientId || ''} onChange={e => setPatientId(e.target.value)} disabled={user.rol === 'Paciente'}><option value="">Seleccionar</option>{records.map(r => <option key={r.paciente_id} value={r.paciente_id}>{r.nombre} {r.apellido} · {r.ci}</option>)}</select></label>{record && <PatientCard patient={record.paciente} expediente={record.expediente} />}{user.rol !== 'Paciente' && record && <form className="form-grid compact-form" onSubmit={submit}><PanelHeader title="Nueva atención" /><label>Médico<select value={form.medico_id} onChange={e => setForm({ ...form, medico_id: e.target.value })} required><option value="">Seleccionar</option>{doctors.map(d => <option key={d.id} value={d.id}>{d.nombre} {d.apellido}</option>)}</select></label><TextArea label="Diagnóstico" value={form.diagnostico} onChange={v => setForm({ ...form, diagnostico: v })} required /><TextArea label="Tratamiento" value={form.tratamiento} onChange={v => setForm({ ...form, tratamiento: v })} /><TextArea label="Observaciones" value={form.observaciones} onChange={v => setForm({ ...form, observaciones: v })} /><label>Medicamento recetado<select value={form.medicamento_id} onChange={e => setForm({ ...form, medicamento_id: e.target.value })}><option value="">Sin receta</option>{medicines.map(m => <option key={m.id} value={m.id}>{m.nombre} · {m.concentracion} · Stock {m.stock}</option>)}</select></label><Input label="Cantidad" type="number" value={form.cantidad} onChange={v => setForm({ ...form, cantidad: v })} min="1" /><Input label="Dosis" value={form.dosis} onChange={v => setForm({ ...form, dosis: v })} /><Input label="Frecuencia" value={form.frecuencia} onChange={v => setForm({ ...form, frecuencia: v })} /><Input label="Días" type="number" value={form.dias} onChange={v => setForm({ ...form, dias: v })} min="1" /><TextArea label="Indicaciones de receta" value={form.indicaciones} onChange={v => setForm({ ...form, indicaciones: v })} /><label className="full-field">Subir examen o archivo<input type="file" onChange={e => setForm({ ...form, archivo: e.target.files?.[0] || null })} /></label><Input label="Descripción del archivo" value={form.archivo_desc} onChange={v => setForm({ ...form, archivo_desc: v })} /><button className="primary-btn wide">Guardar expediente</button></form>}{msg && <Alert type="success" message={msg} />}{err && <Alert type="error" message={err} />}</div><div className="panel large-panel">{record ? <><PanelHeader title="Detalle del expediente" /><RecordDetail record={record} /></> : <Alert type="info" message="Busca o selecciona un paciente para ver el expediente." />}</div></section>;
}

function Pharmacy({ user }) {
  const [meds, setMeds] = useState([]), [patients, setPatients] = useState([]), [filters, setFilters] = useState({ search: '', presentacion: '', categoria: '', estado: '' });
  const [form, setForm] = useState(emptyMedicine), [editing, setEditing] = useState(null), [msg, setMsg] = useState(''), [err, setErr] = useState('');
  const [saleTarget, setSaleTarget] = useState(null), [sale, setSale] = useState({ paciente_id: '', cantidad: 1, observacion: '' });
  const [issue, setIssue] = useState({ motivo: 'Error en registro de venta', detalle: '' });
  const canManage = ['Administrador','Farmacia'].includes(user.rol);
  const canSell = user.rol === 'Farmacia';
  const load = async () => {
    const [m, p] = await Promise.all([
      apiFetch(`/medicines?search=${encodeURIComponent(filters.search)}&presentacion=${filters.presentacion}&categoria=${filters.categoria}&estado=${filters.estado}`),
      canSell ? apiFetch('/patients') : Promise.resolve([])
    ]);
    setMeds(m); setPatients(p);
  };
  useEffect(() => { load().catch(e => setErr(e.message)); }, []);
  const resetFilters = () => { setFilters({ search: '', presentacion: '', categoria: '', estado: '' }); setTimeout(load, 0); };
  const saveMed = async (e) => { e.preventDefault(); setErr(''); setMsg(''); try { if (form.fecha_vencimiento && form.fecha_vencimiento < todayISO()) throw new Error('La fecha de vencimiento no puede ser anterior a hoy.'); const path = editing ? `/medicines/${editing}` : '/medicines'; const method = editing ? 'PUT' : 'POST'; await apiFetch(path, { method, body: JSON.stringify({ ...form, usuario_id: user.id }) }); setMsg(editing ? 'Medicamento actualizado.' : 'Medicamento registrado.'); setForm(emptyMedicine); setEditing(null); load(); } catch (e) { setErr(e.message); } };
  const edit = (m) => { setEditing(m.id); setForm({ codigo: m.codigo, nombre: m.nombre, presentacion: m.presentacion, concentracion: m.concentracion || '', categoria: m.categoria || 'Analgésico', precio: m.precio || 0, stock: m.stock || 0, stock_minimo: m.stock_minimo || 5, fecha_vencimiento: m.fecha_vencimiento ? String(m.fecha_vencimiento).slice(0,10) : '', estado: m.estado }); };
  const openSale = (m) => { setSaleTarget(m); setSale({ paciente_id: '', cantidad: 1, observacion: '' }); setErr(''); setMsg(''); };
  const saleTotal = saleTarget ? Number(saleTarget.precio || 0) * Number(sale.cantidad || 0) : 0;
  const registerProductSale = async (e) => { e.preventDefault(); if (!saleTarget) return; setErr(''); setMsg(''); try { await apiFetch('/sales', { method: 'POST', body: JSON.stringify({ usuario_id: user.id, paciente_id: sale.paciente_id || null, observacion: sale.observacion, items: [{ medicamento_id: saleTarget.id, cantidad: Number(sale.cantidad) }] }) }); setSaleTarget(null); setSale({ paciente_id: '', cantidad: 1, observacion: '' }); setMsg('Producto vendido exitosamente. Revisa el registro de ventas para ver el detalle.'); load(); } catch (e) { setErr(e.message); } };
  const sendIssue = async (e) => { e.preventDefault(); setErr(''); setMsg(''); try { await apiFetch('/pharmacy/issues', { method: 'POST', body: JSON.stringify({ ...issue, usuario_id: user.id }) }); setIssue({ motivo: 'Error en registro de venta', detalle: '' }); setMsg('Solicitud enviada al administrador.'); } catch (e) { setErr(e.message); } };
  return <section className="content-grid"><div className="panel span-2"><PanelHeader title="Medicamentos" />{err && <Alert type="error" message={err} />}{msg && <Alert type="success" message={msg} />}<div className="filters"><input placeholder="Buscar nombre, código, mg, ml..." value={filters.search} onChange={e => setFilters({ ...filters, search: e.target.value })} /><select value={filters.presentacion} onChange={e => setFilters({ ...filters, presentacion: e.target.value })}><option value="">Presentación</option>{PRESENTATIONS.map(p => <option key={p}>{p}</option>)}</select><select value={filters.categoria} onChange={e => setFilters({ ...filters, categoria: e.target.value })}><option value="">Categoría</option>{CATEGORIES.map(c => <option key={c}>{c}</option>)}</select><select value={filters.estado} onChange={e => setFilters({ ...filters, estado: e.target.value })}><option value="">Estado</option><option>Disponible</option><option>Bajo stock</option><option>Agotado</option><option>Vencido</option></select><button className="secondary-btn" onClick={load}>Buscar</button><button className="ghost-btn" onClick={resetFilters}>Limpiar filtros</button></div><div className="medicine-grid">{meds.map(m => <MedicineCard key={m.id} med={m} onEdit={canManage ? edit : null} onSell={canSell ? openSale : null} />)}</div></div>{canManage && <div className="panel"><PanelHeader title={editing ? 'Editar medicamento' : 'Nuevo medicamento'} /><form className="form-grid" onSubmit={saveMed}><Input label="Código" value={form.codigo} onChange={v => setForm({ ...form, codigo: v.toUpperCase() })} required /><Input label="Nombre" value={form.nombre} onChange={v => setForm({ ...form, nombre: v })} required /><label>Presentación<select value={form.presentacion} onChange={e => setForm({ ...form, presentacion: e.target.value })}>{PRESENTATIONS.map(p => <option key={p}>{p}</option>)}</select></label><Input label="Concentración" value={form.concentracion} onChange={v => setForm({ ...form, concentracion: v })} placeholder="500 mg, 1000 ml..." /><label>Categoría<select value={form.categoria} onChange={e => setForm({ ...form, categoria: e.target.value })}>{CATEGORIES.map(c => <option key={c}>{c}</option>)}</select></label><Input label="Precio Bs" type="number" value={form.precio} onChange={v => setForm({ ...form, precio: v })} min="0" /><Input label="Stock" type="number" value={form.stock} onChange={v => setForm({ ...form, stock: v })} min="0" /><Input label="Stock mínimo" type="number" value={form.stock_minimo} onChange={v => setForm({ ...form, stock_minimo: v })} min="0" /><Input label="Vencimiento" type="date" value={form.fecha_vencimiento} onChange={v => setForm({ ...form, fecha_vencimiento: v })} min={todayISO()} /><label>Estado<select value={form.estado} onChange={e => setForm({ ...form, estado: e.target.value })}><option>Disponible</option><option>Bajo stock</option><option>Agotado</option><option>Vencido</option></select></label><button className="primary-btn wide">Guardar medicamento</button>{editing && <button type="button" className="secondary-btn wide" onClick={() => { setEditing(null); setForm(emptyMedicine); }}>Cancelar edición</button>}</form></div>}{canSell && <div className="panel span-3"><PanelHeader title="Solicitar revisión" /><form className="form-grid" onSubmit={sendIssue}><label>Motivo<select value={issue.motivo} onChange={e => setIssue({ ...issue, motivo: e.target.value })}><option>Error en registro de venta</option><option>Diferencia de stock</option><option>Medicamento vencido</option><option>Venta duplicada</option><option>Otro motivo</option></select></label><TextArea label="Detalle" value={issue.detalle} onChange={v => setIssue({ ...issue, detalle: v })} required /><button className="secondary-btn wide">Enviar al administrador</button></form></div>}{saleTarget && <div className="modal-backdrop"><div className="file-modal sale-modal"><div className="modal-header"><div><h3>Vender medicamento</h3><p>{saleTarget.nombre} · {saleTarget.concentracion} · Stock disponible: {saleTarget.stock}</p></div><button className="tiny-btn" type="button" onClick={() => setSaleTarget(null)}>Cerrar</button></div><form className="form-grid" onSubmit={registerProductSale}><label>Paciente<select value={sale.paciente_id} onChange={e => setSale({ ...sale, paciente_id: e.target.value })}><option value="">Venta general</option>{patients.map(p => <option key={p.id} value={p.id}>{p.nombre} {p.apellido}</option>)}</select></label><Input label="Cantidad" type="number" value={sale.cantidad} onChange={v => setSale({ ...sale, cantidad: Number(v) })} min="1" max={saleTarget.stock} required /><TextArea label="Observación" value={sale.observacion} onChange={v => setSale({ ...sale, observacion: v })} /><div className="sale-total"><span>Total</span><b>Bs {saleTotal.toFixed(2)}</b><small>Precio unitario: Bs {Number(saleTarget.precio || 0).toFixed(2)}</small></div><button className="primary-btn wide">Vender producto</button></form></div></div>}</section>;
}

function Sales({ user }) {
  const [sales, setSales] = useState([]), [err, setErr] = useState(''), [msg, setMsg] = useState('');
  const [filters, setFilters] = useState({ from: '2026-06-01', to: '2026-06-30', search: '' });
  const [editing, setEditing] = useState(null);
  const load = async () => { const s = await apiFetch(`/sales?from=${filters.from}&to=${filters.to}`); setSales(s); };
  useEffect(() => { load().catch(e => setErr(e.message)); }, []);
  const visibleSales = sales.filter(v => { const text = `${v.usuario} ${v.paciente || ''} ${v.observacion || ''} ${(v.detalle || []).map(d => d.medicamento).join(' ')}`.toLowerCase(); return !filters.search || text.includes(filters.search.toLowerCase()); });
  const resetFilters = () => { setFilters({ from: '2026-06-01', to: '2026-06-30', search: '' }); setTimeout(load,0); };
  const saveEdit = async (e) => { e.preventDefault(); setErr(''); setMsg(''); try { await apiFetch(`/sales/${editing.id}`, { method: 'PUT', body: JSON.stringify({ total: editing.total, observacion: editing.observacion, usuario_id: user.id }) }); setEditing(null); setMsg('Venta actualizada por administración.'); load(); } catch (e) { setErr(e.message); } };
  return <section className="content-grid">{err && <div className="span-3"><Alert type="error" message={err} /></div>}{msg && <div className="span-3"><Alert type="success" message={msg} /></div>}{user.rol === 'Administrador' && editing && <div className="panel"><PanelHeader title="Editar venta" /><form className="form-grid" onSubmit={saveEdit}><Input label="Total Bs" type="number" value={editing.total} onChange={v => setEditing({ ...editing, total: v })} min="0" /><TextArea label="Observación" value={editing.observacion || ''} onChange={v => setEditing({ ...editing, observacion: v })} /><button className="primary-btn wide">Guardar corrección</button><button type="button" className="secondary-btn wide" onClick={() => setEditing(null)}>Cancelar</button></form></div>}<div className="panel span-3"><PanelHeader title="Registro de ventas" /><div className="filters"><Input label="Desde" type="date" value={filters.from} onChange={v => setFilters({ ...filters, from: v })} /><Input label="Hasta" type="date" value={filters.to} onChange={v => setFilters({ ...filters, to: v })} /><input value={filters.search} onChange={e => setFilters({ ...filters, search: e.target.value })} placeholder="Buscar medicamento, paciente, usuario u observación" /><button className="secondary-btn" onClick={load}>Buscar</button><button className="ghost-btn" onClick={resetFilters}>Limpiar filtros</button></div><SalesTable rows={visibleSales} onEdit={user.rol === 'Administrador' ? setEditing : null} /></div></section>;
}

function Notifications({ user, refreshBell }) {
  const [items, setItems] = useState([]), [queue, setQueue] = useState([]), [filter, setFilter] = useState(''), [msg, setMsg] = useState(''), [err, setErr] = useState('');
  const qs = `usuario_id=${user.id}&rol=${encodeURIComponent(user.rol)}&paciente_id=${user.paciente_id || ''}`;
  const load = async () => { const [n, q] = await Promise.all([apiFetch(`/notifications?${qs}&estado=${filter}`), apiFetch('/queue')]); setItems(n); setQueue(q); refreshBell?.(); };
  useEffect(() => { load().catch(e => setErr(e.message)); }, [filter]);
  const read = async (n) => { await apiFetch(`/notifications/${n.id}/read`, { method: 'PATCH' }); load(); };
  const readAll = async () => { await apiFetch('/notifications/read-all', { method: 'PATCH', body: JSON.stringify({ usuario_id: user.id, paciente_id: user.paciente_id }) }); load(); };
  const process = async () => { const res = await apiFetch('/notifications/process-queue', { method: 'POST', body: JSON.stringify({ usuario_id: user.id }) }); setMsg(`Se procesaron ${res.processed} mensajes de la cola.`); load(); };
  return <section className="content-grid"><div className="panel span-3"><PanelHeader title="Centro de notificaciones" action={<div className="actions"><button className="secondary-btn" onClick={readAll}>Marcar todo leído</button><button className="primary-btn" onClick={process}>Procesar cola</button></div>} />{msg && <Alert type="success" message={msg} />}{err && <Alert type="error" message={err} />}<div className="filters"><select value={filter} onChange={e => setFilter(e.target.value)}><option value="">Todos los estados</option><option>Pendiente</option><option>Enviada</option><option>Fallida</option></select><button className="ghost-btn" onClick={() => setFilter('')}>Limpiar filtros</button></div><TableNotifications notifications={items} onRead={read} /></div><div className="panel span-3"><PanelHeader title="Cola de mensajes" /><TableQueue items={queue} /></div></section>;
}

function Reports() {
  const [doctors, setDoctors] = useState([]), [filters, setFilters] = useState({ from: '2026-06-01', to: '2026-06-30', estado: '', medico_id: '' }), [data, setData] = useState(null), [pharma, setPharma] = useState(null), [err, setErr] = useState('');
  useEffect(() => { apiFetch('/doctors').then(setDoctors); generate(); }, []);
  const generate = async () => { setErr(''); try { const q = `from=${filters.from}&to=${filters.to}&estado=${filters.estado}&medico_id=${filters.medico_id}`; const [a, p] = await Promise.all([apiFetch(`/reports/appointments?${q}`), apiFetch(`/reports/pharmacy?from=${filters.from}&to=${filters.to}`)]); setData(a); setPharma(p); } catch (e) { setErr(e.message); } };
  const exportCsv = () => { if (!data?.rows?.length) return; const header = 'Fecha,Hora,Paciente,Medico,Especialidad,Estado,Motivo\n'; const body = data.rows.map(r => `${r.fecha},${formatTime(r.hora)},${r.paciente},${r.medico},${r.especialidad},${r.estado},${r.motivo || ''}`).join('\n'); const blob = new Blob([header + body], { type: 'text/csv' }); const a = document.createElement('a'); a.href = URL.createObjectURL(blob); a.download = 'reporte_citas_mediclinic.csv'; a.click(); };
  return <section className="content-grid"><div className="panel span-2"><PanelHeader title="Reporte de citas" action={<button className="primary-btn" onClick={generate}>Generar reporte</button>} />{err && <Alert type="error" message={err} />}<div className="filters report-filters"><Input label="Desde" type="date" value={filters.from} onChange={v => setFilters({ ...filters, from: v })} /><Input label="Hasta" type="date" value={filters.to} onChange={v => setFilters({ ...filters, to: v })} /><select value={filters.estado} onChange={e => setFilters({ ...filters, estado: e.target.value })}><option value="">Todos los estados</option>{APPOINTMENT_STATES.map(s => <option key={s}>{s}</option>)}</select><select value={filters.medico_id} onChange={e => setFilters({ ...filters, medico_id: e.target.value })}><option value="">Todos los médicos</option>{doctors.map(d => <option key={d.id} value={d.id}>{d.nombre} {d.apellido}</option>)}</select><button className="secondary-btn" onClick={generate}>Buscar</button><button className="ghost-btn" onClick={() => { setFilters({ from: '2026-06-01', to: '2026-06-30', estado: '', medico_id: '' }); setTimeout(generate,0); }}>Limpiar filtros</button><button className="secondary-btn" onClick={exportCsv}>Exportar CSV</button><button className="secondary-btn" onClick={() => window.print()}>Imprimir</button></div>{data && <div className="report-help"><b>Total de citas encontradas: {data.total}</b><span>Fechas, estado, médico y detalle de cada cita encontrada.</span></div>}</div><div className="panel"><PanelHeader title="Resumen visual" /><DonutChart data={data?.summary || []} labelKey="estado" valueKey="total" /></div><div className="panel"><PanelHeader title="Atenciones por médico" /><DataList data={data?.byDoctor || []} labelKey="medico" valueKey="total" /></div><div className="panel"><PanelHeader title="Ventas farmacia" /><h2 className="money-total">Bs {Number(pharma?.total || 0).toFixed(2)}</h2><DataList data={pharma?.top || []} labelKey="nombre" valueKey="total" /></div><div className="panel span-3"><PanelHeader title="Detalle del reporte" /><TableReport rows={data?.rows || []} /></div></section>;
}

function Logs() {
  const [logs, setLogs] = useState([]), [roles, setRoles] = useState([]), [filters, setFilters] = useState({ rol: '', modulo: '', search: '' }), [err, setErr] = useState('');
  const load = () => apiFetch(`/logs?rol=${filters.rol}&modulo=${encodeURIComponent(filters.modulo)}&search=${encodeURIComponent(filters.search)}`).then(setLogs).catch(e => setErr(e.message));
  useEffect(() => { apiFetch('/roles').then(setRoles); load(); }, []);
  return <section className="panel"><PanelHeader title="Logs de actividad" />{err && <Alert type="error" message={err} />}<div className="filters"><select value={filters.rol} onChange={e => setFilters({ ...filters, rol: e.target.value })}><option value="">Todos los roles</option>{roles.map(r => <option key={r.id}>{r.nombre}</option>)}</select><input value={filters.modulo} onChange={e => setFilters({ ...filters, modulo: e.target.value })} placeholder="Módulo: Citas, Farmacia..." /><input value={filters.search} onChange={e => setFilters({ ...filters, search: e.target.value })} placeholder="Buscar detalle o usuario" /><button className="secondary-btn" onClick={load}>Buscar</button><button className="ghost-btn" onClick={() => { setFilters({ rol: '', modulo: '', search: '' }); setTimeout(load,0); }}>Limpiar filtros</button></div><Timeline items={logs} showRole /></section>;
}

function Profile({ user, onUpdate }) {
  const [form, setForm] = useState({ nombre: user.nombre, apellido: user.apellido, correo: user.correo, foto_url: user.foto_url || '' }), [file, setFile] = useState(null), [msg, setMsg] = useState(''), [err, setErr] = useState('');
  const submit = async (e) => { e.preventDefault(); setMsg(''); setErr(''); try { let foto_url = form.foto_url; if (file) { const fd = new FormData(); fd.append('file', file); fd.append('usuario_id', user.id); const uploaded = await apiUpload('/upload/profile', fd); foto_url = uploaded.url; } const updated = await apiFetch(`/users/${user.id}/profile`, { method: 'PATCH', body: JSON.stringify({ ...form, foto_url }) }); onUpdate(updated); setMsg('Perfil actualizado correctamente.'); } catch (e) { setErr(e.message); } };
  return <section className="two-column"><div className="panel"><PanelHeader title="Mi perfil" />{msg && <Alert type="success" message={msg} />}{err && <Alert type="error" message={err} />}<div className="profile-preview"><UserAvatar user={{ ...user, ...form }} large /><div><h3>{form.nombre} {form.apellido}</h3><p>{user.rol}</p></div></div><form className="form-grid" onSubmit={submit}><Input label="Nombre" value={form.nombre} onChange={v => setForm({ ...form, nombre: v })} required /><Input label="Apellido" value={form.apellido} onChange={v => setForm({ ...form, apellido: v })} required /><Input label="Correo" type="email" value={form.correo} onChange={v => setForm({ ...form, correo: v })} required /><label className="full-field">Subir foto desde archivos<input type="file" accept="image/*" onChange={e => setFile(e.target.files?.[0] || null)} /></label><button className="primary-btn wide">Guardar perfil</button></form></div><div className="panel"><PanelHeader title="Acceso" /><DataList data={[{ nombre: 'Rol', total: user.rol }, { nombre: 'Estado', total: user.estado }, { nombre: 'Correo', total: user.correo }]} labelKey="nombre" valueKey="total" /></div></section>;
}

function TableUsers({ users, onEdit, onToggle }) { return <div className="table-wrap"><table><thead><tr><th>Usuario</th><th>Rol</th><th>Vínculo</th><th>Estado</th><th>Acciones</th></tr></thead><tbody>{users.map(u => <tr key={u.id}><td><b>{u.nombre} {u.apellido}</b><small>{u.correo}</small></td><td>{u.rol}</td><td>{u.paciente || u.medico || '-'}</td><td><Badge value={u.estado} /></td><td className="actions"><button className="tiny-btn" onClick={() => onEdit(u)}>Editar</button><button className="tiny-btn" onClick={() => onToggle(u)}>{u.estado === 'Activo' ? 'Desactivar' : 'Activar'}</button></td></tr>)}</tbody></table></div>; }
function TablePatients({ patients, onEdit, onToggle }) { return <div className="table-wrap"><table><thead><tr><th>Paciente</th><th>CI</th><th>Edad</th><th>Contacto</th><th>Sangre</th><th>Estado</th><th>Acciones</th></tr></thead><tbody>{patients.map(p => <tr key={p.id}><td><b>{p.nombre} {p.apellido}</b><small>{p.direccion}</small></td><td>{p.ci}</td><td>{p.edad}</td><td>{p.celular || '-'}</td><td>{p.tipo_sangre || '-'}</td><td><Badge value={p.estado} /></td><td className="actions"><button className="tiny-btn" onClick={() => onEdit(p)}>Editar</button><button className="tiny-btn" onClick={() => onToggle(p)}>{p.estado === 'Activo' ? 'Desactivar' : 'Activar'}</button></td></tr>)}</tbody></table></div>; }
function TableNotifications({ notifications, onRead }) { return <div className="table-wrap"><table><thead><tr><th>Estado lectura</th><th>Paciente/Destino</th><th>Asunto</th><th>Canal</th><th>Estado</th><th>Creado</th><th>Acción</th></tr></thead><tbody>{notifications.map(n => <tr key={n.id} className={!n.leida ? 'unread-row' : ''}><td>{n.leida ? 'Leída' : 'Nueva'}</td><td>{n.paciente || n.destinatario || '-'}</td><td><b>{n.asunto}</b><small>{n.mensaje}</small></td><td>{n.canal}</td><td><Badge value={n.estado} /></td><td>{formatDateTime(n.creado_en)}</td><td><button className="tiny-btn" onClick={() => onRead(n)}>{n.leida ? 'Ver' : 'Marcar leída'}</button></td></tr>)}</tbody></table></div>; }
function TableQueue({ items }) { return <div className="table-wrap"><table><thead><tr><th>Tipo</th><th>Referencia</th><th>Estado</th><th>Intentos</th><th>Creado</th><th>Procesado</th></tr></thead><tbody>{items.map(q => <tr key={q.id}><td>{q.tipo}</td><td>{q.referencia_id || '-'}</td><td><Badge value={q.estado} /></td><td>{q.intentos}</td><td>{formatDateTime(q.creado_en)}</td><td>{formatDateTime(q.procesado_en)}</td></tr>)}</tbody></table></div>; }
function TableReport({ rows }) { return <div className="table-wrap"><table><thead><tr><th>Fecha</th><th>Hora</th><th>Paciente</th><th>Médico</th><th>Especialidad</th><th>Estado</th><th>Motivo</th></tr></thead><tbody>{rows.map((r, i) => <tr key={i}><td>{formatDate(r.fecha)}</td><td>{formatTime12(r.hora)}</td><td>{r.paciente}</td><td>{r.medico}</td><td>{r.especialidad}</td><td><Badge value={r.estado} /></td><td>{r.motivo}</td></tr>)}</tbody></table></div>; }
function SalesTable({ rows, onEdit }) { return <div className="table-wrap"><table><thead><tr><th>Fecha</th><th>Paciente</th><th>Usuario</th><th>Detalle</th><th>Total</th>{onEdit && <th>Acción</th>}</tr></thead><tbody>{rows.map(s => <tr key={s.id}><td>{formatDateTime(s.fecha)}</td><td>{s.paciente || 'Venta general'}</td><td>{s.usuario}</td><td>{(s.detalle || []).map((d, i) => <small key={i}>{d.medicamento} x {d.cantidad} · Bs {d.subtotal}</small>)}{s.observacion && <small>{s.observacion}</small>}</td><td><b>Bs {Number(s.total || 0).toFixed(2)}</b></td>{onEdit && <td><button className="tiny-btn" onClick={() => onEdit(s)}>Editar</button></td>}</tr>)}</tbody></table></div>; }
function AppointmentCard({ cita, onStatus, onEdit, readonly = false }) { return <article className="appointment-card"><div className="date-box"><b>{formatTime(cita.hora)}</b><span>{formatDate(cita.fecha)}</span><small>{formatTime12(cita.hora).replace(formatTime(cita.hora), '')}</small></div><div className="appointment-body"><h3>{cita.paciente_nombre} {cita.paciente_apellido}</h3><p>Dr(a). {cita.medico_nombre} {cita.medico_apellido} · {cita.especialidad}</p><span>{cita.motivo || 'Consulta general'}</span></div><div className="status-actions"><Badge value={cita.estado} />{!readonly && <div>{onEdit && <button className="tiny-btn" onClick={() => onEdit(cita)}>Editar</button>}{APPOINTMENT_STATES.filter(s => s !== cita.estado).map(status => <button key={status} className="tiny-btn" onClick={() => onStatus(cita.id, status)}>{status}</button>)}</div>}</div></article>; }
function AppointmentMiniList({ appointments }) { return <div className="appointment-list small-list">{appointments?.length ? appointments.map(c => <AppointmentCard key={c.id} cita={c} readonly />) : <p className="muted">No hay citas registradas.</p>}</div>; }
function PatientCard({ patient, expediente }) { return <div className="patient-summary"><div className="avatar big">{patient.nombre?.[0]}{patient.apellido?.[0]}</div><h3>{patient.nombre} {patient.apellido}</h3>{expediente && <p>{expediente.codigo}</p>}<span>CI: {patient.ci} · Edad: {patient.edad ?? '-'}</span><span>Celular: {patient.celular || '-'} · Tipo de sangre: {patient.tipo_sangre || '-'}</span><span>Alergias: {patient.alergias || 'Sin registro'}</span><span>Antecedentes: {patient.antecedentes || 'Sin registro'}</span><Badge value={patient.estado} /></div>; }
function RecordDetail({ record }) {
  const [viewer, setViewer] = useState(null);
  const openFile = async (item) => {
    const url = resolveFileUrl(item.url);
    try {
      const res = await fetch(url);
      const text = await res.text();
      setViewer({ ...item, text });
    } catch {
      setViewer({ ...item, text: item.descripcion || 'No se pudo leer el archivo, pero el adjunto está registrado en el expediente.' });
    }
  };
  const fileButton = (item) => <button className="file-card file-card-button" key={item.key} type="button" onClick={() => openFile(item)}><span className="file-icon"><Icon name="paperclip" /></span><b>{item.title}</b><small>{item.descripcion}</small></button>;
  const recetaButton = (r) => <button className="file-card file-card-button" key={`r-${r.id}`} type="button" onClick={() => openFile({ key: `r-${r.id}`, title: `Receta #${r.id}`, descripcion: (r.detalle || []).map(d => `${d.medicamento} x${d.cantidad}`).join(', ') || r.indicaciones, url: r.pdf_url })}><span className="file-icon"><Icon name="reports" /></span><b>Receta #{r.id}</b><small>{(r.detalle || []).map(d => `${d.medicamento} x${d.cantidad}`).join(', ') || r.indicaciones}</small></button>;
  return <div className="record-detail"><div className="detail-grid"><div><b>Paciente</b><span>{record.paciente.nombre} {record.paciente.apellido}</span></div><div><b>Expediente</b><span>{record.expediente.codigo}</span></div><div><b>CI</b><span>{record.paciente.ci}</span></div><div><b>Sangre</b><span>{record.paciente.tipo_sangre || '-'}</span></div></div><h3>Consultas registradas</h3><div className="timeline clinical">{record.consultas?.length ? record.consultas.map(item => <div className="timeline-item" key={item.id}><div className="dot"></div><b>{formatDateTime(item.fecha)} · {item.medico}</b><p><strong>Diagnóstico:</strong> {item.diagnostico}</p><p><strong>Tratamiento:</strong> {item.tratamiento || 'Sin tratamiento registrado'}</p><span>{item.observaciones}</span></div>) : <p className="muted">Sin consultas registradas.</p>}</div><h3>Recetas</h3><div className="file-grid">{record.recetas?.length ? record.recetas.map(recetaButton) : <p className="muted">Sin recetas registradas.</p>}</div><h3>Exámenes y archivos</h3><div className="file-grid">{record.examenes?.map(ex => fileButton({ key: `e-${ex.id}`, title: ex.tipo, descripcion: ex.resultado || ex.descripcion, url: ex.archivo_url }))}{record.archivos?.map(file => fileButton({ key: `f-${file.id}`, title: file.nombre_archivo, descripcion: file.descripcion || 'Archivo adjunto', url: file.storage_url }))}{!record.examenes?.length && !record.archivos?.length && <p className="muted">Sin archivos adjuntos.</p>}</div>{viewer && <div className="modal-backdrop" onClick={() => setViewer(null)}><div className="file-modal" onClick={e => e.stopPropagation()}><div className="modal-header"><div><h3>{viewer.title}</h3><p>{viewer.descripcion}</p></div><button className="ghost-btn" onClick={() => setViewer(null)}>Cerrar</button></div><pre>{viewer.text}</pre></div></div>}</div>;
}
function MedicineCard({ med, onEdit, onSell }) { return <article className="medicine-card"><div><small>{med.codigo}</small><h3>{med.nombre}</h3><p>{med.presentacion} · {med.concentracion}</p><span>{med.categoria} · Bs {Number(med.precio || 0).toFixed(2)}</span></div><div className="stock-box"><b>{med.stock}</b><span>unidades</span></div><Badge value={med.estado} /><div className="medicine-actions">{onSell && <button className="tiny-btn sell-btn" onClick={() => onSell(med)} disabled={Number(med.stock || 0) <= 0}>Vender</button>}{onEdit && <button className="tiny-btn" onClick={() => onEdit(med)}>Editar</button>}</div></article>; }
function UserAvatar({ user, large = false }) { if (user.foto_url) return <img className={`avatar-img ${large ? 'big' : ''}`} src={resolveFileUrl(user.foto_url)} alt="Foto de perfil" />; return <div className={`avatar ${large ? 'big' : ''}`}>{user.nombre?.[0]}{user.apellido?.[0]}</div>; }
function MetricCard({ label, value, icon, hint, onClick }) { return <article className={`metric-card ${onClick ? 'clickable' : ''}`} onClick={onClick}><span className="metric-icon"><Icon name={icon} /></span><b>{value ?? 0}</b><p>{label}</p><small>{hint}</small></article>; }
function PanelHeader({ title, subtitle, action }) { return <div className="panel-header"><div><h3>{title}</h3>{subtitle && <p>{subtitle}</p>}</div>{action}</div>; }
function BarChart({ data = [], labelKey, valueKey }) { const max = Math.max(1, ...data.map(item => Number(item[valueKey] || 0))); return <div className="bar-chart">{data.map((item, i) => <div className="bar-item" key={i}><div className="bar-track"><div style={{ height: `${(Number(item[valueKey]) / max) * 100}%` }}></div></div><b>{item[valueKey]}</b><span>{String(item[labelKey]).slice(5,10)}</span></div>)}</div>; }
function DonutChart({ data = [], labelKey, valueKey }) { const safe = data.length ? data : [{ [labelKey]: 'Sin datos', [valueKey]: 1 }]; const total = safe.reduce((s, i) => s + Number(i[valueKey] || 0), 0) || 1; let start = 0; const segments = safe.map((item, i) => { const value = Number(item[valueKey] || 0); const deg = (value / total) * 360; const segment = `var(--chart-${(i % 6) + 1}) ${start}deg ${start + deg}deg`; start += deg; return segment; }); return <div className="donut-layout"><div className="donut" style={{ background: `conic-gradient(${segments.join(', ')})` }}><span>{total}</span></div><div className="legend">{safe.map((item, idx) => <div key={idx}><i style={{ background: `var(--chart-${(idx % 6) + 1})` }}></i><span>{item[labelKey]}</span><b>{item[valueKey]}</b></div>)}</div></div>; }
function DataList({ data = [], labelKey, valueKey }) { return <div className="data-list">{data.length ? data.map((item, idx) => <div key={idx}><span>{item[labelKey]}</span><b>{item[valueKey]}</b></div>) : <p className="muted">Sin datos para mostrar.</p>}</div>; }
function StatusPills({ data = [] }) { return <div className="status-grid">{data.map((item, idx) => <div className="status-pill" key={idx}><Badge value={item.estado} /><b>{item.total}</b></div>)}</div>; }
function Timeline({ items = [], showRole = false }) { return <div className="timeline">{items.length ? items.map(item => <div className="timeline-item" key={item.id}><div className="dot"></div><b>{item.modulo} · {item.accion}</b><p>{item.detalle}</p><span>{item.usuario} {showRole ? `· ${item.rol}` : ''} · {formatDateTime(item.creado_en)}</span></div>) : <p className="muted">Sin actividad registrada.</p>}</div>; }
function Badge({ value }) { const normalized = String(value || '').toLowerCase().replaceAll(' ', '-'); return <span className={`badge badge-${normalized}`}>{value}</span>; }
function Input({ label, value, onChange, type = 'text', required = false, min, max, disabled = false, placeholder = '' }) { return <label>{label}<input type={type} value={value ?? ''} onChange={e => onChange(e.target.value)} required={required} min={min} max={max} disabled={disabled} placeholder={placeholder} /></label>; }
function TextArea({ label, value, onChange, required = false }) { return <label className="full-field">{label}<textarea value={value ?? ''} onChange={e => onChange(e.target.value)} required={required} rows="3" /></label>; }
function Alert({ type, message }) { return <div className={`alert ${type}`}>{message}</div>; }
function Loading() { return <div className="loading"><div></div><span>Cargando información clínica...</span></div>; }
function ErrorBox({ message }) { return <div className="alert error big-error"><b>No se pudo completar la operación.</b><span>{message}</span><p>Revisa que la API esté activa y que PostgreSQL tenga cargado el script SQL actualizado.</p></div>; }

createRoot(document.getElementById('root')).render(<App />);
