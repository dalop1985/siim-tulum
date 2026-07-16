# ROADMAP — SIIM (Sistema Integral de Ingresos Municipales)
### H. Ayuntamiento del Municipio de Tulum, Quintana Roo

Este documento convierte "lo que falta" en un plan ordenado y rastreable.
La idea central que lo hace manejable:

> El SIIM NO son 15 sistemas distintos. Es UNA plataforma + UN patrón que se repite.
> Los cimientos se construyen una sola vez. Cada módulo de trámite (DSA, Multas,
> Desarrollo Urbano, Protección Civil, Salud...) repite el mismo esqueleto:
> catálogo propio -> cálculo según la ley -> pase de caja -> cobro -> recibo -> estado para el CRI.

---

## Decisión de stack: Frontend en Svelte

El frontend se construirá en **Svelte / SvelteKit**, no en React.

- Costo del cambio: CERO. El frontend aún no está construido, no hay retrabajo.
- El backend (FastAPI) es agnóstico al frontend: expone API REST/OpenAPI, Svelte se conecta igual.
- Sustituye en la spec: React 18 -> SvelteKit · Zustand -> Svelte stores ·
  TanStack Query -> svelte-query. Axios se mantiene.

---

## Las tres capas del sistema

```
CAPA 3 — TRANSVERSAL
  Analítica / Dashboards · Generación de PDF · Notificaciones
CAPA 2 — MÓDULOS DE TRÁMITE (mismo patrón, se replican)
  Predial · Licencias · DSA · Multas · Desarrollo Urbano ·
  Protección Civil · Salud · Agua · ZOFEMAT · ISABI · ...
CAPA 1 — CIMIENTOS (se construyen una sola vez)
  Login/RBAC · Catálogos fiscales · Contribuyentes · Caja ·
  Prepóliza · Auditoría · CRI
```

---

## CAPA 1 — Cimientos (prioridad máxima, desbloquean todo)

| # | Componente | Qué incluye | Estado |
|---|---|---|---|
| 1 | Login / Seguridad / RBAC | JWT, sesiones, roles y permisos, bloqueo de usuarios | Especificado, falta código |
| 2 | Catálogos fiscales | UMA, INPC, recargos, ejercicios, fuentes de ingreso, tarifas | Especificado, falta código |
| 3 | Padrón de contribuyentes | Alta/edición, documentos, historial, estado de cuenta | Especificado, falta código |
| 4 | Módulo de Caja | Cajas, series de folios, pases, sesiones y cortes | Especificado, falta código |
| 5 | Prepóliza contable | Póliza/prepóliza diaria para contabilidad (sp_poliza_contable) | Especificado, falta código |
| 6 | Auditoría centralizada | Log de todas las operaciones | Especificado, falta código |
| 7 | CRI (Constancia de Registro de Ingresos) | Pasaporte fiscal: consolida estado de todos los módulos | Especificado, falta código |

---

## CAPA 2 — Módulos de trámite (repiten el patrón)

Cada módulo = catálogos propios + motor de cálculo legal + generación de pase de caja +
método obtener_estado_fiscal() para alimentar el CRI.

| Módulo | Base legal principal | Estado |
|---|---|---|
| ISABI (adquisición de inmuebles) | Ley ISABI QRoo, tasa 4% Tulum | SQL parcial recuperado |
| Predial | Ley de Hacienda QRoo, Tablas Decreto 91 | Especificado + guía catastral |
| Licencias de Funcionamiento | Ley de Hacienda Tulum | Especificado + guía |
| DSA (Derecho de Saneamiento Ambiental) | Arts. 139-143 Ley Hac. Tulum | Guía recuperada, falta código |
| Recolección de Residuos | Art. 118 Ley Hac. Tulum | Guía recuperada (con DSA) |
| Multas | Código Fiscal Municipal QRoo | Por diseñar |
| Desarrollo Urbano (DU) | Reglamentos municipales de DU | Por diseñar |
| Protección Civil (PC) | Dictámenes y tarifas PC | Por diseñar |
| Salud | Reglamentos municipales de Salud | Por diseñar |
| ZOFEMAT | LGBN Arts. 119-131 | Guía recuperada, falta código |
| Agua | Ley de Hacienda Tulum | Especificado como futuro |
| Tránsito / Registro Civil | Marco estatal/municipal | Futuro |

---

## CAPA 3 — Transversal

| Componente | Qué incluye | Estado |
|---|---|---|
| Analítica / Dashboards | Recaudación en tiempo real, metas vs real, cartera, deudores | SP especificados, falta implementar |
| Generación de PDF | Recibos, CRI, cortes de caja (WeasyPrint) | Especificado, falta código |
| Notificaciones | Avisos de vencimiento (licencias, pases) | Por diseñar |

---

## Orden de construcción recomendado

```
FASE A — Fundacional
  1. Proyecto base FastAPI + conexión PostgreSQL + Alembic + Docker
  2. Login / RBAC
  3. Catálogos fiscales + Contribuyentes

FASE B — Corazón transaccional
  4. Módulo de Caja + Prepóliza
  5. Auditoría

FASE C — Primer trámite de punta a punta (plantilla probada)
  6. DSA o Multas completo -> sirve de molde para el resto
  7. CRI, una vez que hay >=1 módulo que consultar

FASE D — Replicar el patrón
  8. Predial, Licencias, DU, PC, Salud, ZOFEMAT... (mismo molde)

FASE E — Frontend Svelte (en paralelo desde Fase B)
  9. SvelteKit: login, layout, módulo de Cajas, módulos de trámite

FASE F — Transversal
 10. Analítica / dashboards + PDF + notificaciones
```

---

## Hitos (milestones)

- [ ] M1 — Base levantada: corre en Docker, login funcional, un usuario admin.
- [ ] M2 — Se puede cobrar: caja abierta, pase generado, cobrado, recibo PDF.
- [ ] M3 — Prepóliza: el cierre de caja genera la prepóliza contable del día.
- [ ] M4 — Primer trámite completo: DSA (o Multas) de punta a punta.
- [ ] M5 — CRI vivo: la constancia consolida el estado de los módulos activos.
- [ ] M6 — Frontend Svelte: login + cajas + primer trámite en la interfaz.
- [ ] M7 — Analítica: dashboard de recaudación en tiempo real.
- [ ] M8 — Replicación: cada nuevo módulo entra rápido con el molde probado.

---

## Notas de recuperación pendientes

- Buscar en otras conversaciones el backend FastAPI y el frontend ya construidos.
- Confirmar catálogos/seed adicionales (colonias SEPOMEX, giros, zonas catastrales).
- Validar el marco legal contra fuentes 2026 antes de congelar tarifas.

- Portar a PostgreSQL los scripts recuperados de ISABI y del clasificador CONAC (hoy en T-SQL de SQL Server).
