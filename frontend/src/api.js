export const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:4000/api';
export const BASE_URL = API_URL.replace('/api', '');

export async function apiFetch(path, options = {}) {
  const response = await fetch(`${API_URL}${path}`, {
    headers: { 'Content-Type': 'application/json', ...(options.headers || {}) },
    ...options
  });
  const text = await response.text();
  let data = null;
  try { data = text ? JSON.parse(text) : null; } catch { data = null; }
  if (!response.ok) {
    const message = data?.detail || data?.message || 'No se pudo completar la operación.';
    throw new Error(message);
  }
  return data;
}

export async function apiUpload(path, formData) {
  const response = await fetch(`${API_URL}${path}`, { method: 'POST', body: formData });
  const text = await response.text();
  let data = null;
  try { data = text ? JSON.parse(text) : null; } catch { data = null; }
  if (!response.ok) throw new Error(data?.detail || data?.message || 'No se pudo subir el archivo.');
  return data;
}

export const todayISO = () => new Date().toISOString().slice(0, 10);

export const formatDate = (value) => {
  if (!value) return '-';
  const date = new Date(`${String(value).slice(0, 10)}T12:00:00`);
  if (Number.isNaN(date.getTime())) return value;
  return date.toLocaleDateString('es-BO', { year: 'numeric', month: 'short', day: '2-digit' });
};

export const formatDateTime = (value) => {
  if (!value) return '-';
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return value;
  return date.toLocaleString('es-BO', { dateStyle: 'medium', timeStyle: 'short' });
};

export const formatTime = (value) => String(value || '').slice(0,5);
export const formatTime12 = (value) => {
  const [h, m] = formatTime(value).split(':').map(Number);
  if (Number.isNaN(h)) return '-';
  const suffix = h >= 12 ? 'p. m.' : 'a. m.';
  const hh = h % 12 || 12;
  return `${String(h).padStart(2,'0')}:${String(m || 0).padStart(2,'0')} (${hh}:${String(m || 0).padStart(2,'0')} ${suffix})`;
};

export const resolveFileUrl = (url) => {
  if (!url) return '#';
  if (url.startsWith('http')) return url;
  return `${BASE_URL}${url}`;
};
