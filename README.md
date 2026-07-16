# SIIM — Sistema Integral de Ingresos Municipales
### H. Ayuntamiento del Municipio de Tulum, Quintana Roo

Sistema de recaudación municipal construido como conjunto de microservicios.
Este repositorio concentra la **especificación técnica**, las **guías jurídicas**
y el **código SQL** del proyecto.

> **Nota de recuperación (julio 2026):** este repositorio se reconstruyó a partir
> de los artefactos generados en conversaciones previas, tras la pérdida del equipo
> de desarrollo original. Consulta `ESTADO_DEL_PROYECTO.md` para ver qué está
> recuperado y qué falta por construir.

---

## Stack tecnológico

| Capa | Tecnología |
|---|---|
| Backend API | Python 3.11+ / FastAPI 0.110+ |
| ORM | SQLAlchemy 2.x (async) |
| Base de datos | PostgreSQL 14+ |
| Migraciones | Alembic |
| Validación | Pydantic v2 |
| Autenticación | JWT (python-jose) + OAuth2 |
| Permisos | RBAC propio |
| Task Queue | Celery + Redis |
| Frontend | SvelteKit (Svelte 5) |
| Estado FE | Svelte stores / TanStack Query |
| PDF | WeasyPrint |
| Testing | pytest + pytest-asyncio + httpx |
| Contenedores | Docker + docker-compose |

---

## Arquitectura de microservicios

```
FRONTEND (Svelte + TS)
        | HTTP/REST (OpenAPI)
API GATEWAY (FastAPI, puerto 8000)
        |
   +----+----+---------+------------+----------+
 ms_core  ms_caja  ms_predial  ms_licencias  ms_*
        |
   PostgreSQL — Schemas: core / caja / catalogos /
                predial / licencias / isabi / auditoria
```

---

## Estructura del repositorio

```
siim-tulum/
├── README.md                     <- este archivo
├── ESTADO_DEL_PROYECTO.md        <- inventario: qué está listo y qué falta
├── .gitignore
├── docs/
│   ├── PROMPT_MAESTRO_SIIM_UNIFICADO.md   <- especificación completa (v2.0)
│   ├── PROMPT_MAESTRO_SIIM_v1.md          <- versión previa (v1.0, referencia)
│   └── guias/
│       ├── valor-catastral-tulum-qroo.md
│       ├── licencias-dsa-tulum-guia.md
│       └── zofemat-guia-completa.md
└── database/
    ├── catalogos/
    │   └── cri-completo-siim.sql          <- Clasificador por Rubro de Ingresos (CONAC)
    └── isabi/
        ├── isabi-completo.sql             <- módulo ISABI íntegro (DDL + seed + SP)
        ├── isabi-tipo-operacion.sql       <- catálogo tipos de operación
        └── isabi-cat-notaria.sql          <- catálogo notarías/notarios (32 estados)
```

---

## Marco legal aplicable (vigente 2026)

- Ley de Hacienda del Municipio de Tulum — última reforma POE 10-12-2025
- Ley de Ingresos del Municipio de Tulum — Decreto 162, POE 10-12-2025
- Código Fiscal Municipal del Estado de Quintana Roo
- Ley del ISABI de los Municipios de Quintana Roo
- Ley de Catastro del Estado de Quintana Roo / Tablas de Valores Decreto 91 (POE 25-12-2020)
- Ley General de Contabilidad Gubernamental (CONAC) — clasificador CRI
- Tarifas expresadas en **UMA** — valor diario 2026: **$113.14 MXN**

---

## Por dónde empezar

1. Lee `ESTADO_DEL_PROYECTO.md` para el panorama completo.
2. La especificación maestra (`docs/PROMPT_MAESTRO_SIIM_UNIFICADO.md`) está
   organizada en fases; cada fase depende de la anterior.
3. El código SQL de `database/` ya es ejecutable sobre una BD nueva de PostgreSQL.
