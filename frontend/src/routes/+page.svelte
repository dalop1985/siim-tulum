<script lang="ts">
	import { goto } from '$app/navigation';
	import { API_BASE, guardarToken } from '$lib/api';

	let username = $state('');
	let password = $state('');
	let error = $state('');
	let cargando = $state(false);

	async function entrar(e: Event) {
		e.preventDefault();
		error = '';
		cargando = true;
		try {
			const body = new URLSearchParams({ username, password });
			const r = await fetch(`${API_BASE}/auth/login`, {
				method: 'POST',
				headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
				body
			});
			if (!r.ok) {
				const d = await r.json().catch(() => null);
				throw new Error(d?.detail ?? 'No se pudo conectar con el servidor');
			}
			const data = await r.json();
			guardarToken(data.access_token);
			goto('/panel');
		} catch (err) {
			error = err instanceof Error ? err.message : 'Error inesperado';
		} finally {
			cargando = false;
		}
	}
</script>

<div class="pantalla">
	<aside class="marca">
		<div>
			<div class="escudo" aria-hidden="true">
				<svg width="34" height="34" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round">
					<path d="M3 21h18" /><path d="M5 21V10l7-5 7 5v11" /><path d="M9 21v-6h6v6" />
				</svg>
			</div>
			<p class="sello">Gobierno Municipal</p>
			<h1>Sistema Integral de<br />Ingresos Municipales</h1>
			<p class="sub">
				Plataforma de recaudación del H. Ayuntamiento del Municipio de Tulum, Quintana Roo.
			</p>
		</div>
		<div class="pie">
			<strong>H. Ayuntamiento de Tulum</strong> · Quintana Roo<br />
			Ejercicio fiscal 2026 · UMA diaria $113.14 MXN
		</div>
	</aside>

	<main class="acceso">
		<form class="tarjeta" onsubmit={entrar} aria-label="Formulario de acceso">
			<h2>Iniciar sesión</h2>
			<p class="hint">Ingresa con tu usuario institucional.</p>

			<div class="campo">
				<label for="usuario">Usuario</label>
				<div class="control">
					<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" /><circle cx="12" cy="7" r="4" /></svg>
					<input id="usuario" type="text" placeholder="nombre.usuario" autocomplete="username" bind:value={username} required />
				</div>
			</div>

			<div class="campo">
				<label for="password">Contraseña</label>
				<div class="control">
					<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="11" width="18" height="11" rx="2" /><path d="M7 11V7a5 5 0 0 1 10 0v4" /></svg>
					<input id="password" type="password" placeholder="••••••••" autocomplete="current-password" bind:value={password} required />
				</div>
			</div>

			{#if error}
				<p class="error" role="alert">{error}</p>
			{/if}

			<button class="btn" type="submit" disabled={cargando}>
				{cargando ? 'Verificando…' : 'Entrar al sistema'}
			</button>

			<div class="pie">
				Acceso restringido a personal autorizado.<br />
				Todas las operaciones quedan registradas en auditoría.
			</div>
		</form>
	</main>
</div>

<style>
	:global(:root) {
		--tinta: #0f2f35;
		--teal-900: #0c4a4e;
		--teal-700: #116466;
		--teal-500: #1a8a86;
		--oro: #c8a24a;
		--oro-claro: #e3c477;
		--gris-050: #f6f8f8;
		--gris-100: #eef2f2;
		--gris-300: #cdd8d8;
		--gris-500: #6b7b7b;
		--blanco: #ffffff;
		--rojo: #b3452f;
		--radio: 14px;
		--sombra: 0 18px 48px -18px rgba(12, 74, 78, 0.45);
		--foco: 0 0 0 3px rgba(26, 138, 134, 0.35);
	}
	:global(*) { box-sizing: border-box; margin: 0; padding: 0; }
	:global(body) {
		font-family: 'Segoe UI', system-ui, -apple-system, Roboto, Helvetica, Arial, sans-serif;
		color: var(--tinta);
		background: var(--gris-100);
		-webkit-font-smoothing: antialiased;
	}
	.pantalla { min-height: 100vh; display: grid; grid-template-columns: 1.05fr 0.95fr; }
	.marca {
		position: relative; color: var(--blanco);
		background:
			radial-gradient(1200px 600px at 15% -10%, rgba(26, 138, 134, 0.55), transparent 60%),
			linear-gradient(160deg, var(--teal-900) 0%, var(--teal-700) 55%, var(--tinta) 100%);
		padding: 64px 60px; display: flex; flex-direction: column; justify-content: space-between; overflow: hidden;
	}
	.marca::after {
		content: ''; position: absolute; inset: auto 0 0 0; height: 6px;
		background: linear-gradient(90deg, var(--oro), var(--oro-claro), var(--teal-500));
	}
	.escudo {
		width: 76px; height: 76px; border-radius: 50%; display: grid; place-items: center;
		background: rgba(255, 255, 255, 0.08); border: 2px solid rgba(227, 196, 119, 0.6);
		color: var(--oro-claro); margin-bottom: 26px;
	}
	.marca h1 { font-size: 30px; line-height: 1.15; font-weight: 700; letter-spacing: 0.2px; }
	.marca .sub { margin-top: 14px; font-size: 16px; color: #cfe6e4; max-width: 34ch; line-height: 1.5; }
	.sello { font-size: 13px; letter-spacing: 0.16em; text-transform: uppercase; color: var(--oro-claro); font-weight: 600; margin-bottom: 8px; }
	.marca .pie { font-size: 13px; color: #a9c6c4; line-height: 1.6; }
	.marca .pie strong { color: #e6f2f1; }
	.acceso { background: var(--gris-050); display: flex; align-items: center; justify-content: center; padding: 48px 40px; }
	.tarjeta {
		width: 100%; max-width: 400px; background: var(--blanco); border: 1px solid var(--gris-100);
		border-radius: var(--radio); box-shadow: var(--sombra); padding: 40px 36px 32px;
	}
	.tarjeta h2 { font-size: 22px; font-weight: 700; }
	.tarjeta .hint { margin-top: 6px; color: var(--gris-500); font-size: 14px; margin-bottom: 26px; }
	.campo { margin-bottom: 18px; }
	.campo label { display: block; font-size: 13px; font-weight: 600; margin-bottom: 7px; color: #274a4d; }
	.control { position: relative; display: flex; align-items: center; }
	.control svg { position: absolute; left: 13px; width: 18px; height: 18px; color: var(--gris-500); }
	.control input {
		width: 100%; padding: 12px 14px 12px 40px; border: 1.5px solid var(--gris-300); border-radius: 10px;
		font-size: 15px; color: var(--tinta); background: var(--blanco);
		transition: border-color 0.15s, box-shadow 0.15s;
	}
	.control input:focus { outline: none; border-color: var(--teal-500); box-shadow: var(--foco); }
	.error {
		margin: 4px 0 16px; padding: 10px 12px; border-radius: 8px; font-size: 13px;
		color: var(--rojo); background: rgba(179, 69, 47, 0.08); border: 1px solid rgba(179, 69, 47, 0.25);
	}
	.btn {
		width: 100%; padding: 13px 16px; border: none; border-radius: 10px; cursor: pointer;
		font-size: 15px; font-weight: 700; color: var(--blanco); letter-spacing: 0.02em;
		background: linear-gradient(180deg, var(--teal-500), var(--teal-700));
		box-shadow: 0 8px 18px -8px rgba(17, 100, 102, 0.7);
		transition: transform 0.05s, filter 0.15s;
	}
	.btn:hover { filter: brightness(1.05); }
	.btn:active { transform: translateY(1px); }
	.btn:disabled { opacity: 0.7; cursor: wait; }
	.tarjeta .pie {
		margin-top: 22px; padding-top: 18px; border-top: 1px solid var(--gris-100);
		font-size: 12px; color: var(--gris-500); text-align: center; line-height: 1.6;
	}
	@media (max-width: 860px) {
		.pantalla { grid-template-columns: 1fr; }
		.marca { padding: 40px 32px; min-height: auto; }
		.marca .sub { max-width: none; }
		.acceso { padding: 32px 20px; }
	}
</style>
