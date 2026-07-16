/** Cliente de la API del SIIM (backend FastAPI en el puerto 6679). */

export const API_BASE = 'http://localhost:6679/api/v1';

const TOKEN_KEY = 'siim_token';

export function guardarToken(token: string): void {
	localStorage.setItem(TOKEN_KEY, token);
}

export function obtenerToken(): string | null {
	return localStorage.getItem(TOKEN_KEY);
}

export function limpiarToken(): void {
	localStorage.removeItem(TOKEN_KEY);
}

/** fetch con el token Bearer incluido automáticamente. */
export async function apiFetch(ruta: string, init: RequestInit = {}): Promise<Response> {
	const token = obtenerToken();
	const headers = new Headers(init.headers);
	if (token) headers.set('Authorization', `Bearer ${token}`);
	return fetch(`${API_BASE}${ruta}`, { ...init, headers });
}
