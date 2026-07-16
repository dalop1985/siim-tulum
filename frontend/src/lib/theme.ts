/** Tema día/noche del SIIM — persiste la preferencia del usuario. */

const KEY = 'siim_tema';

export type Tema = 'claro' | 'oscuro';

export function temaGuardado(): Tema {
	return (localStorage.getItem(KEY) as Tema) ?? 'claro';
}

export function aplicarTema(tema: Tema): void {
	document.documentElement.dataset.theme = tema === 'oscuro' ? 'dark' : '';
	localStorage.setItem(KEY, tema);
}

export function alternarTema(): Tema {
	const nuevo: Tema = document.documentElement.dataset.theme === 'dark' ? 'claro' : 'oscuro';
	aplicarTema(nuevo);
	return nuevo;
}
