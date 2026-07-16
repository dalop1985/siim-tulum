<script lang="ts">
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import { apiFetch, limpiarToken } from '$lib/api';

	type Perfil = {
		id_usuario: number;
		username: string;
		email: string;
		nombre_completo: string;
		debe_cambiar_password: boolean;
		roles: string[];
		permisos: string[];
	};

	let perfil = $state<Perfil | null>(null);
	let cargando = $state(true);

	onMount(async () => {
		try {
			const r = await apiFetch('/auth/me');
			if (!r.ok) throw new Error('sesión inválida');
			perfil = await r.json();
		} catch {
			limpiarToken();
			goto('/');
		} finally {
			cargando = false;
		}
	});

	async function salir() {
		await apiFetch('/auth/logout', { method: 'POST' }).catch(() => null);
		limpiarToken();
		goto('/');
	}
</script>

<div class="panel">
	{#if cargando}
		<p class="cargando">Cargando tu sesión…</p>
	{:else if perfil}
		<header>
			<div>
				<p class="sello">SIIM · H. Ayuntamiento de Tulum</p>
				<h1>Hola, {perfil.nombre_completo}</h1>
				<p class="sub">@{perfil.username} · {perfil.email}</p>
			</div>
			<button class="btn-salir" onclick={salir}>Cerrar sesión</button>
		</header>

		{#if perfil.debe_cambiar_password}
			<div class="aviso">
				⚠ Tu contraseña es temporal. Por seguridad, cámbiala desde la API
				(<code>/auth/cambiar-password</code>) o espera el módulo de perfil.
			</div>
		{/if}

		<section class="tarjetas">
			<div class="tarjeta">
				<h3>Tus roles</h3>
				{#if perfil.roles.length}
					<ul>
						{#each perfil.roles as rol}<li>{rol}</li>{/each}
					</ul>
				{:else}
					<p class="vacio">Sin roles asignados</p>
				{/if}
			</div>
			<div class="tarjeta">
				<h3>Permisos efectivos</h3>
				<p class="numero">{perfil.permisos.length}</p>
				<p class="vacio">
					{perfil.roles.includes('SUPER_ADMIN')
						? 'SUPER_ADMIN: acceso total al sistema'
						: 'permisos activos en tu cuenta'}
				</p>
			</div>
			<div class="tarjeta">
				<h3>Próximos módulos</h3>
				<p class="vacio">Caja · Contribuyentes · Predial · Licencias · ISABI…</p>
			</div>
		</section>
	{/if}
</div>

<style>
	.panel { min-height: 100vh; background: #f6f8f8; padding: 40px clamp(20px, 6vw, 72px); }
	.cargando { color: #6b7b7b; }
	header { display: flex; align-items: flex-start; justify-content: space-between; gap: 20px; flex-wrap: wrap; }
	.sello { font-size: 12px; letter-spacing: 0.14em; text-transform: uppercase; color: #116466; font-weight: 700; }
	h1 { margin-top: 6px; font-size: 26px; color: #0f2f35; }
	.sub { margin-top: 4px; color: #6b7b7b; font-size: 14px; }
	.btn-salir {
		padding: 10px 18px; border: 1.5px solid #cdd8d8; background: #fff; border-radius: 10px;
		font-weight: 600; color: #0f2f35; cursor: pointer;
	}
	.btn-salir:hover { border-color: #1a8a86; color: #116466; }
	.aviso {
		margin-top: 22px; padding: 12px 16px; border-radius: 10px; font-size: 14px;
		background: rgba(200, 162, 74, 0.12); border: 1px solid rgba(200, 162, 74, 0.4); color: #6b5518;
	}
	.tarjetas { margin-top: 28px; display: grid; grid-template-columns: repeat(auto-fit, minmax(240px, 1fr)); gap: 18px; }
	.tarjeta {
		background: #fff; border: 1px solid #eef2f2; border-radius: 14px; padding: 22px;
		box-shadow: 0 14px 34px -22px rgba(12, 74, 78, 0.35);
	}
	.tarjeta h3 { font-size: 15px; color: #274a4d; margin-bottom: 10px; }
	.tarjeta ul { list-style: none; }
	.tarjeta li {
		display: inline-block; margin: 3px 6px 3px 0; padding: 4px 10px; border-radius: 999px;
		background: #eef2f2; color: #116466; font-size: 12px; font-weight: 700;
	}
	.numero { font-size: 34px; font-weight: 800; color: #116466; }
	.vacio { color: #6b7b7b; font-size: 13px; margin-top: 4px; }
	code { background: #eef2f2; padding: 1px 6px; border-radius: 6px; font-size: 12px; }
</style>
