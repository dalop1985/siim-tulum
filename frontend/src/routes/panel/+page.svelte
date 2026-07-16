<script lang="ts">
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import { apiFetch, limpiarToken } from '$lib/api';
	import { temaGuardado, aplicarTema, alternarTema, type Tema } from '$lib/theme';

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
	let tema = $state<Tema>('claro');

	onMount(async () => {
		tema = temaGuardado();
		aplicarTema(tema);
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

	function cambiarTema() { tema = alternarTema(); }

	function pantallaCompleta() {
		if (document.fullscreenElement) document.exitFullscreen();
		else document.documentElement.requestFullscreen().catch(() => {});
	}

	async function salir() {
		await apiFetch('/auth/logout', { method: 'POST' }).catch(() => null);
		limpiarToken();
		goto('/');
	}

	function iniciales(nombre: string): string {
		return nombre.split(' ').map(p => p[0]).join('').slice(0, 2).toUpperCase();
	}

	/* ── datos de demostración (se conectarán a la API por módulo) ── */
	const meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul'];
	const a2026 = [4.9, 3.6, 2.7, 2.4, 2.6, 2.9, 2.41];
	const a2025 = [4.3, 3.4, 2.6, 2.3, 2.4, 2.6, 2.7];
	const fuentes: [string, number][] = [
		['Predial', 912], ['ISABI', 688], ['Licencias', 342],
		['DSA', 201], ['Recolección', 148], ['Otros', 119],
	];
	const cajas = [
		{ id: 'CAJA-01', quien: 'L. Martínez', abierta: true },
		{ id: 'CAJA-02', quien: 'R. Uc Canul', abierta: true },
		{ id: 'CAJA-03', quien: 'S. Herrera', abierta: true },
		{ id: 'CAJA-04', quien: 'Sin asignar', abierta: false },
	];
	const actividad = [
		{ hora: '09:42', que: 'Pago predial', folio: 'REC-2026-004512', det: 'CAJA-02 · $8,940' },
		{ hora: '09:37', que: 'Pase generado', folio: 'PC-2026-001208', det: 'Licencia de funcionamiento' },
		{ hora: '09:31', que: 'Pago ISABI', folio: 'REC-2026-004511', det: 'CAJA-01 · $64,200' },
		{ hora: '09:12', que: 'Apertura de caja', folio: 'CAJA-03', det: 'Supervisor: J. Pech' },
		{ hora: '08:58', que: 'Alta contribuyente', folio: 'CONT-018233', det: 'Persona moral' },
	];

	/* ── geometría de la gráfica ── */
	const W = 640, H = 235, padL = 34, padB = 26, padT = 12;
	const maxV = 5.5, plotW = W - padL - 10, plotH = H - padT - padB;
	const y = (v: number) => padT + plotH - (v / maxV) * plotH;
	const bw = 26, band = plotW / meses.length;
	const cx = (i: number) => padL + band * i + band / 2;
	const iMax = a2026.indexOf(Math.max(...a2026));
	const maxF = Math.max(...fuentes.map(f => f[1]));

	function barraD(i: number): string {
		const h = (a2026[i] / maxV) * plotH;
		const c = cx(i);
		return `M${c - bw / 2},${y(0)} v-${Math.max(h - 4, 0)} q0,-4 4,-4 h${bw - 8} q4,0 4,4 v${Math.max(h - 4, 0)} z`;
	}
	const lineaD = meses.map((_, i) => (i ? 'L' : 'M') + cx(i) + ',' + y(a2025[i])).join('');

	/* ── tooltip ── */
	let svgEl = $state<SVGSVGElement | null>(null);
	let tip = $state<{ i: number; x: number; y: number } | null>(null);
	function muestraTip(i: number) {
		if (!svgEl) return;
		const r = svgEl.getBoundingClientRect();
		tip = {
			i,
			x: cx(i) * (r.width / W),
			y: y(Math.max(a2026[i], a2025[i])) * (r.height / H),
		};
	}
</script>

<svelte:head><title>SIIM — Panel de Ingresos</title></svelte:head>

{#if cargando}
	<div class="cargando-full">Cargando tu sesión…</div>
{:else if perfil}
<div class="app">

	<!-- ══ SIDEBAR ══ -->
	<aside class="side">
		<div class="marca">
			<div class="escudo">
				<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M3 21h18"/><path d="M5 21V10l7-5 7 5v11"/><path d="M9 21v-6h6v6"/></svg>
			</div>
			<div><b>SIIM</b><span>Tulum · Q. Roo</span></div>
		</div>

		<nav class="nav">
			<div class="grupo" style="padding-top:6px">Principal</div>
			<a class="act" href="/panel"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="7" height="9" rx="1.5"/><rect x="14" y="3" width="7" height="5" rx="1.5"/><rect x="14" y="12" width="7" height="9" rx="1.5"/><rect x="3" y="16" width="7" height="5" rx="1.5"/></svg>Panel de ingresos</a>
			<a href="#" title="Próximamente"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M21 11.5a8.38 8.38 0 0 1-.9 3.8 8.5 8.5 0 0 1-7.6 4.7 8.38 8.38 0 0 1-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 0 1-.9-3.8 8.5 8.5 0 0 1 4.7-7.6 8.38 8.38 0 0 1 3.8-.9h.5a8.48 8.48 0 0 1 8 8z"/></svg>Chat interno<span class="badge">3</span></a>
			<a href="#" title="Próximamente"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M22 12h-4l-3 9L9 3l-3 9H2"/></svg>Timeline</a>
			<a href="#" title="Próximamente"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="5" height="18" rx="1.5"/><rect x="10" y="3" width="5" height="12" rx="1.5"/><rect x="17" y="3" width="5" height="8" rx="1.5"/></svg>Kanban</a>
			<a href="#" title="Próximamente"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M18 8a6 6 0 0 0-12 0c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.7 21a2 2 0 0 1-3.4 0"/></svg>Notificaciones<span class="badge">12</span></a>
			<a href="#" title="Próximamente"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M3 3v18h18"/><path d="M7 13l4-4 4 4 5-6"/></svg>Analítica</a>

			<div class="grupo">Módulos</div>
			<a href="#" title="Próximamente"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="5" width="20" height="14" rx="2"/><path d="M2 10h20"/></svg>Caja</a>
			<a href="#" title="Próximamente"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>Contribuyentes</a>
			<a href="#" title="Próximamente"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M3 21h18"/><path d="M5 21V10l7-5 7 5v11"/></svg>Predial y Catastro</a>
			<a href="#" title="Próximamente"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><path d="M14 2v6h6"/></svg>Licencias</a>
			<a href="#" title="Próximamente"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M3 9l9-6 9 6v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><path d="M9 22V12h6v10"/></svg>ISABI</a>
			<a href="#" title="Próximamente"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><path d="M12 8v4l3 3"/></svg>Multas</a>
			<a href="#" title="Próximamente"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M2 22s4-2 10-2 10 2 10 2"/><path d="M12 2v16"/><path d="M5 12c2 1 5 1.5 7 1.5s5-.5 7-1.5"/></svg>ZOFEMAT</a>
			<a href="#" title="Próximamente"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><path d="M14 2v6h6"/><path d="M9 15h6M9 11h2"/></svg>Reportes</a>

			<div class="grupo">Configuraciones</div>
			<a href="#" title="Próximamente"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>Perfiles</a>
			<a href="#" title="Próximamente"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 1 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 1 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 1 1-2.83-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 1 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 1 1 2.83-2.83l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 1 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 1 1 2.83 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 1 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z"/></svg>Configuración administrativa</a>
			<a href="#" title="Próximamente"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"/><path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"/></svg>Catálogos del sistema</a>
		</nav>

		<div class="pie-side">H. Ayuntamiento de Tulum<br>Ejercicio fiscal 2026</div>
	</aside>

	<!-- ══ MAIN ══ -->
	<main class="main">
		<div class="top">
			<div class="busca">
				<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><circle cx="11" cy="11" r="7"/><path d="M21 21l-4.3-4.3"/></svg>
				Buscar contribuyente, folio, predio…
			</div>
			<div class="sep"></div>
			<span class="chip">Ejercicio 2026</span>
			<span class="chip">UMA $113.14</span>
			<button class="icono-btn" title="Pantalla completa" onclick={pantallaCompleta}>
				<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"><path d="M8 3H5a2 2 0 0 0-2 2v3"/><path d="M21 8V5a2 2 0 0 0-2-2h-3"/><path d="M3 16v3a2 2 0 0 0 2 2h3"/><path d="M16 21h3a2 2 0 0 0 2-2v-3"/></svg>
			</button>
			<button class="icono-btn" title="Cambiar tema día/noche" onclick={cambiarTema}>
				{#if tema === 'oscuro'}
					<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4"/></svg>
				{:else}
					<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"><path d="M21 12.8A9 9 0 1 1 11.2 3a7 7 0 0 0 9.8 9.8z"/></svg>
				{/if}
			</button>
			<button class="icono-btn" title="Notificaciones">
				<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"><path d="M18 8a6 6 0 0 0-12 0c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.7 21a2 2 0 0 1-3.4 0"/></svg>
			</button>
			<div class="quien-top">
				<div class="avatar">{iniciales(perfil.nombre_completo)}</div>
				<div><b>{perfil.nombre_completo}</b><span>{perfil.roles.join(' · ') || 'Sin rol'}</span></div>
			</div>
			<button class="icono-btn" title="Cerrar sesión" onclick={salir}>
				<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><path d="M16 17l5-5-5-5"/><path d="M21 12H9"/></svg>
			</button>
		</div>

		<div class="saludo">
			<h1>Hola, {perfil.nombre_completo.split(' ')[0]}</h1>
			<p>{new Date().toLocaleDateString('es-MX', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' })} · Tesorería Municipal</p>
		</div>

		{#if perfil.debe_cambiar_password}
			<div class="aviso">⚠ Tu contraseña es temporal. Cámbiala desde la API (<code>/auth/cambiar-password</code>) mientras llega el módulo de Perfiles.</div>
		{/if}

		<!-- KPIs (datos de demostración) -->
		<section class="kpis">
			<div class="kpi">
				<div class="lbl"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/></svg>Recaudado hoy</div>
				<div class="num">$184,320</div>
				<div class="sub">47 operaciones · 3 cajas</div>
				<span class="delta up">▲ 12% vs ayer</span>
			</div>
			<div class="kpi">
				<div class="lbl"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><rect x="3" y="4" width="18" height="17" rx="2"/><path d="M8 2v4M16 2v4M3 10h18"/></svg>Recaudado en julio</div>
				<div class="num">$2.41 M</div>
				<div class="sub">Meta mensual: $3.55 M</div>
				<div class="meta-bar"><i></i></div>
				<div class="sub" style="margin-top:5px">68% de la meta</div>
			</div>
			<div class="kpi">
				<div class="lbl"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M3 3v18h18"/><path d="M7 13l4-4 4 4 5-6"/></svg>Acumulado 2026</div>
				<div class="num">$21.87 M</div>
				<div class="sub">Enero – julio</div>
				<span class="delta up">▲ 9% vs 2025</span>
			</div>
			<div class="kpi">
				<div class="lbl"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><path d="M14 2v6h6"/></svg>Pases de caja activos</div>
				<div class="num">128</div>
				<div class="sub">pendientes de cobro</div>
				<span class="delta warn">⚠ 9 vencen en 48 h</span>
			</div>
		</section>

		<div class="cols">
			<div>
				<div class="card" style="margin-bottom:16px">
					<h2>Recaudación mensual</h2>
					<p class="desc">Millones de pesos · comparativo con 2025 · datos de demostración</p>
					<div class="leyenda">
						<span><i style="background:var(--d-teal)"></i>2026</span>
						<span><i style="background:var(--d-oro)"></i>2025</span>
					</div>
					<div class="grafica">
						<!-- svelte-ignore a11y_no_noninteractive_element_interactions -->
						<svg bind:this={svgEl} viewBox="0 0 640 235" width="100%" role="img" aria-label="Recaudación mensual 2026 contra 2025" onmouseleave={() => (tip = null)}>
							{#each [0, 1, 2, 3, 4, 5] as v}
								<line class="grid-l" x1={padL} x2={W - 8} y1={y(v)} y2={y(v)} />
								<text class="ax" x={padL - 7} y={y(v) + 3.5} text-anchor="end">{v}</text>
							{/each}
							{#each meses as m, i}
								<!-- svelte-ignore a11y_no_static_element_interactions -->
								<path class="barra" d={barraD(i)} onmouseenter={() => muestraTip(i)} />
								<text class="mes" x={cx(i)} y={H - 8} text-anchor="middle">{m}</text>
							{/each}
							<text class="dlabel" x={cx(iMax)} y={y(a2026[iMax]) - 7} text-anchor="middle">${a2026[iMax]} M</text>
							<path class="linea25" d={lineaD} fill="none" stroke-width="2" stroke-linejoin="round" stroke-linecap="round" />
							{#each meses as _, i}
								<!-- svelte-ignore a11y_no_static_element_interactions -->
								<circle class="pt" cx={cx(i)} cy={y(a2025[i])} r="4" stroke-width="2" onmouseenter={() => muestraTip(i)} />
							{/each}
						</svg>
						{#if tip}
							<div class="tip" style="left:{tip.x}px; top:{tip.y}px; opacity:1">
								<b>{meses[tip.i]}</b> · <span class="t2">2026:</span> <b>${a2026[tip.i]} M</b> · <span class="t2">2025:</span> ${a2025[tip.i]} M
							</div>
						{/if}
					</div>
				</div>

				<div class="card">
					<h2>Por fuente de ingreso — julio</h2>
					<p class="desc">Miles de pesos · datos de demostración</p>
					{#each fuentes as [n, v]}
						<div class="fuente">
							<span class="n">{n}</span>
							<span class="pista"><i style="width:{((v / maxF) * 100).toFixed(1)}%"></i></span>
							<span class="v">${v.toLocaleString('es-MX')} k</span>
						</div>
					{/each}
				</div>
			</div>

			<div>
				<div class="card" style="margin-bottom:16px">
					<h2>Cajas</h2>
					<p class="desc">Estado en tiempo real · demostración</p>
					{#each cajas as c}
						<div class="caja-item">
							<span class="dot" class:ok={c.abierta} class:off={!c.abierta}></span>
							<b>{c.id}</b><span class="quien">{c.quien}</span>
							<span class="estado-txt" class:ok={c.abierta} class:off={!c.abierta}>{c.abierta ? '✓ Abierta' : '— Cerrada'}</span>
						</div>
					{/each}
				</div>

				<div class="card">
					<h2>Actividad reciente</h2>
					<p class="desc">Bitácora de auditoría · demostración</p>
					{#each actividad as a}
						<div class="act-item">
							<span class="cuando">{a.hora}</span>
							<div class="que"><b>{a.que}</b> · {a.folio}<br><span>{a.det}</span></div>
						</div>
					{/each}
				</div>
			</div>
		</div>

		<p class="nota">SIIM v0.2 · H. Ayuntamiento de Tulum · los indicadores mostrados son datos de demostración</p>
	</main>
</div>
{/if}

<style>
	:global(:root){
		--teal-900:#0c4a4e; --teal-700:#116466; --teal-500:#1a8a86;
		--oro:#c8a24a; --oro-claro:#e3c477;
		--sup:#f6f8f8; --card:#ffffff; --linea:#e4ecec;
		--ink-1:#0f2f35; --ink-2:#44605f; --ink-3:#7d9291;
		--d-teal:#0e8f84; --d-oro:#9c7a2f;
		--ok:#1c7c44; --warn:#9c6d1f;
		--chip-bg:#e3efee; --chip-tx:#116466;
		--ctl-bg:#ffffff; --ctl-bd:#e4ecec;
		--tip-bg:#0f2f35; --tip-tx:#eaf4f3; --tip-t2:#c9dedd;
		--r:14px; --sombra:0 10px 30px -18px rgba(12,74,78,.35);
	}
	:global([data-theme="dark"]){
		--sup:#0e2124; --card:#142c30; --linea:#1f3d41;
		--ink-1:#e8f2f1; --ink-2:#a9c2c0; --ink-3:#7d9695;
		--d-teal:#18978b; --d-oro:#b08a30;
		--ok:#4cc07a; --warn:#d9a84e;
		--chip-bg:#173539; --chip-tx:#8fd4cd;
		--ctl-bg:#142c30; --ctl-bd:#1f3d41;
		--tip-bg:#e8f2f1; --tip-tx:#12292d; --tip-t2:#44605f;
		--sombra:0 10px 30px -18px rgba(0,0,0,.55);
	}
	:global(body){
		margin:0;
		font-family:'Segoe UI',system-ui,-apple-system,Roboto,Helvetica,Arial,sans-serif;
		background:var(--sup); color:var(--ink-1); -webkit-font-smoothing:antialiased;
		transition:background .25s, color .25s;
	}
	*{box-sizing:border-box}
	.cargando-full{min-height:100vh; display:grid; place-items:center; color:var(--ink-3)}
	.app{display:grid; grid-template-columns:240px 1fr; min-height:100vh}

	/* sidebar */
	.side{
		color:#eaf4f3; padding:22px 14px 18px;
		background:linear-gradient(175deg,var(--teal-900) 0%,var(--teal-700) 60%,#0d3a40 100%);
		display:flex; flex-direction:column;
	}
	.marca{display:flex; align-items:center; gap:11px; padding:4px 8px 16px; border-bottom:1px solid rgba(255,255,255,.12); margin-bottom:10px}
	.escudo{width:40px;height:40px;border-radius:50%; display:grid;place-items:center; flex:none;
		background:rgba(255,255,255,.09); border:1.5px solid rgba(227,196,119,.55); color:var(--oro-claro)}
	.marca b{font-size:16px; letter-spacing:.03em}
	.marca span{display:block; font-size:10.5px; color:#a9c6c4; letter-spacing:.08em; text-transform:uppercase}
	.grupo{font-size:10px; letter-spacing:.16em; text-transform:uppercase; color:#d8bd7e; padding:16px 10px 6px; font-weight:700}
	.nav{overflow-y:auto; scrollbar-width:thin; scrollbar-color:rgba(255,255,255,.25) transparent; margin-right:-6px; padding-right:6px}
	.nav a{display:flex; align-items:center; gap:10px; padding:8px 10px; border-radius:9px;
		color:#cfe3e1; text-decoration:none; font-size:13.5px; position:relative}
	.nav a :global(svg){width:16px;height:16px; flex:none; opacity:.85}
	.nav a:hover{background:rgba(255,255,255,.07); color:#fff}
	.nav a.act{background:rgba(255,255,255,.12); color:#fff; font-weight:600}
	.nav a.act::before{content:""; position:absolute; left:-14px; top:6px; bottom:6px; width:3.5px; border-radius:0 3px 3px 0; background:var(--oro-claro)}
	.badge{margin-left:auto; background:var(--oro-claro); color:#3c2f0e; font-size:9.5px; font-weight:800; border-radius:999px; padding:1.5px 7px; line-height:1.4}
	.pie-side{margin-top:auto; font-size:10.5px; color:#8fb3b1; text-align:center; padding-top:14px}

	/* main / top bar */
	.main{padding:0 30px 30px; min-width:0}
	.top{display:flex; align-items:center; gap:12px; padding:14px 0; border-bottom:1px solid var(--linea); margin-bottom:22px}
	.busca{flex:1; max-width:380px; display:flex; align-items:center; gap:8px;
		background:var(--ctl-bg); border:1.5px solid var(--ctl-bd); border-radius:10px; padding:8px 12px; color:var(--ink-3); font-size:13px}
	.top .sep{flex:1}
	.chip{font-size:12px; font-weight:600; color:var(--chip-tx); background:var(--chip-bg); border-radius:999px; padding:5px 12px; white-space:nowrap}
	.icono-btn{width:34px;height:34px; border-radius:9px; border:1.5px solid var(--ctl-bd);
		background:var(--ctl-bg); display:grid;place-items:center; color:var(--ink-2); cursor:pointer}
	.icono-btn:hover{border-color:var(--teal-500); color:var(--teal-500)}
	.quien-top{display:flex; align-items:center; gap:10px; padding:5px 12px 5px 6px;
		border:1.5px solid var(--ctl-bd); border-radius:999px; background:var(--ctl-bg)}
	.avatar{width:28px;height:28px;border-radius:50%; background:var(--oro-claro); color:#3c2f0e; display:grid;place-items:center; font-weight:700; font-size:12px; flex:none}
	.quien-top b{font-size:12.5px; display:block; line-height:1.15}
	.quien-top span{font-size:10.5px; color:var(--ink-3)}

	.saludo{display:flex; align-items:baseline; justify-content:space-between; flex-wrap:wrap; gap:8px; margin-bottom:18px}
	.saludo h1{font-size:21px; margin:0}
	.saludo p{color:var(--ink-3); font-size:13px; margin:0}
	.aviso{margin-bottom:18px; padding:12px 16px; border-radius:10px; font-size:13px;
		background:color-mix(in srgb, var(--warn) 12%, transparent); border:1px solid color-mix(in srgb, var(--warn) 40%, transparent); color:var(--warn)}
	.aviso code{background:var(--chip-bg); padding:1px 6px; border-radius:6px; font-size:12px}

	/* kpis */
	.kpis{display:grid; grid-template-columns:repeat(4,1fr); gap:16px; margin-bottom:18px}
	.kpi{background:var(--card); border:1px solid var(--linea); border-radius:var(--r); box-shadow:var(--sombra); padding:16px 18px 15px}
	.kpi .lbl{font-size:12px; color:var(--ink-2); font-weight:600; display:flex; align-items:center; gap:7px}
	.kpi .lbl :global(svg){width:14px;height:14px; color:var(--teal-500)}
	.kpi .num{font-size:25px; font-weight:800; letter-spacing:-.01em; margin-top:7px; font-variant-numeric:tabular-nums}
	.kpi .sub{font-size:11.5px; color:var(--ink-3); margin-top:3px}
	.delta{display:inline-flex; align-items:center; gap:4px; font-size:11px; font-weight:700; border-radius:999px; padding:2.5px 8px; margin-top:8px}
	.delta.up{color:var(--ok); background:color-mix(in srgb, var(--ok) 12%, transparent)}
	.delta.warn{color:var(--warn); background:color-mix(in srgb, var(--warn) 14%, transparent)}
	.meta-bar{height:6px; border-radius:999px; background:var(--linea); margin-top:10px; overflow:hidden}
	.meta-bar i{display:block; height:100%; width:68%; border-radius:999px; background:var(--d-teal)}

	/* layout inferior */
	.cols{display:grid; grid-template-columns:1fr 320px; gap:16px; align-items:start}
	.card{background:var(--card); border:1px solid var(--linea); border-radius:var(--r); box-shadow:var(--sombra); padding:18px 20px}
	.card h2{font-size:14.5px; margin:0 0 2px}
	.card .desc{font-size:12px; color:var(--ink-3); margin:0 0 14px}
	.leyenda{display:flex; gap:16px; font-size:11.5px; color:var(--ink-2); margin-bottom:10px}
	.leyenda i{width:10px;height:10px;border-radius:3px; display:inline-block; margin-right:6px; vertical-align:-1px}

	/* gráfica */
	.grafica{position:relative}
	.grid-l{stroke:var(--linea); stroke-width:1}
	.ax{fill:var(--ink-3); font-size:9.5px}
	.mes{fill:var(--ink-2); font-size:10px}
	.dlabel{fill:var(--ink-1); font-size:10.5px; font-weight:700}
	.barra{fill:var(--d-teal)}
	.linea25{stroke:var(--d-oro)}
	.pt{fill:var(--d-oro); stroke:var(--card)}
	.tip{position:absolute; pointer-events:none; transition:opacity .12s;
		background:var(--tip-bg); color:var(--tip-tx); font-size:11.5px; border-radius:8px;
		padding:7px 10px; transform:translate(-50%,-115%); white-space:nowrap; z-index:5}
	.tip b{color:var(--tip-tx)}
	.tip .t2{color:var(--tip-t2)}

	/* fuentes */
	.fuente{display:grid; grid-template-columns:92px 1fr 74px; align-items:center; gap:10px; margin-bottom:9px; font-size:12px}
	.fuente .n{color:var(--ink-2)}
	.fuente .pista{height:14px; position:relative}
	.fuente .pista i{position:absolute; inset:0 auto 0 0; border-radius:0 4px 4px 0; background:var(--d-teal)}
	.fuente .v{text-align:right; font-variant-numeric:tabular-nums; font-weight:600}

	/* panel derecho */
	.caja-item{display:flex; align-items:center; gap:10px; padding:9px 0; border-bottom:1px solid var(--linea); font-size:12.5px}
	.caja-item:last-child{border-bottom:0}
	.dot{width:8px;height:8px;border-radius:50%; flex:none}
	.dot.ok{background:var(--ok)} .dot.off{background:var(--ink-3)}
	.caja-item b{flex:none}
	.caja-item .quien{color:var(--ink-3); flex:1; overflow:hidden; text-overflow:ellipsis; white-space:nowrap}
	.estado-txt{font-size:11px; font-weight:700; display:inline-flex; align-items:center; gap:5px}
	.estado-txt.ok{color:var(--ok)} .estado-txt.off{color:var(--ink-3)}
	.act-item{display:flex; gap:10px; padding:8px 0; border-bottom:1px solid var(--linea); font-size:12px}
	.act-item:last-child{border-bottom:0}
	.act-item .cuando{color:var(--ink-3); flex:none; width:44px; font-variant-numeric:tabular-nums}
	.act-item .que span{color:var(--ink-2)}
	.nota{margin-top:16px; text-align:center; font-size:11px; color:var(--ink-3)}
</style>
