# Estado del proyecto SIIM — Inventario de recuperación

**Fecha de recuperación:** 15 de julio de 2026
**Origen:** artefactos generados en conversaciones previas, recuperados tras la
pérdida del equipo de desarrollo original.

Este documento es el mapa de qué se recuperó, qué fase del sistema cubre cada
pieza, y qué falta por construir. Úsalo como punto de partida.

---

## 1. Resumen ejecutivo

| Dimensión | Estado |
|---|---|
| Especificación técnica (arquitectura, DDL, endpoints, lógica) | RECUPERADA casi íntegra |
| Marco legal y guías jurídicas | RECUPERADO (3 guías) |
| Código SQL implementado (ISABI + clasificador CONAC) | RECUPERADO (T-SQL, pendiente portar a PostgreSQL) |
| Backend Python / FastAPI (código real) | NO presente en esta carpeta |
| Frontend Svelte / TypeScript | NO presente en esta carpeta |
| Migraciones Alembic | Pendiente |
| Docker / docker-compose | Pendiente |
| Tests (pytest) | Pendiente (era lo último en lo que se trabajaba) |

**Conclusión:** el diseño, el modelo de datos y el marco legal están a salvo.
Lo que falta es principalmente la implementación del backend/frontend, que puede
estar en otras conversaciones o ser el trabajo aún por generar.

---

## 2. Inventario de archivos recuperados

### Especificación (docs/)

| Archivo | Contenido | Estado |
|---|---|---|
| PROMPT_MAESTRO_SIIM_UNIFICADO.md | Especificación completa v2.0 — 1,821 líneas — 9 fases con DDL, endpoints y lógica | Íntegro |
| PROMPT_MAESTRO_SIIM_v1.md | Versión previa v1.0 — 1,384 líneas — referencia histórica | Íntegro |

### Guías técnicas jurídicas (docs/guias/)

| Archivo | Contenido | Estado |
|---|---|---|
| valor-catastral-tulum-qroo.md | Metodología del valor catastral — Tablas Decreto 91 | Íntegro |
| licencias-dsa-tulum-guia.md | Licencias de funcionamiento + Saneamiento Ambiental (DSA) | Íntegro |
| zofemat-guia-completa.md | Zona Federal Marítimo Terrestre: concesiones y cobro | Íntegro |

### Código SQL (database/)

| Archivo | Contenido | Estado |
|---|---|---|
| catalogos/cri-completo-siim.sql | Clasificador por Rubro de Ingresos (CONAC) | Ejecutable |
| isabi/isabi-completo.sql | Módulo ISABI completo: tipos, tasas 2000-2026, SP, vistas | Ejecutable |
| isabi/isabi-tipo-operacion.sql | Catálogo de tipos de operación de traslado de dominio | Ejecutable |
| isabi/isabi-cat-notaria.sql | Catálogo de notarías y notarios (32 estados) | Ejecutable |

> NOTA sobre "CRI": el término aparece con dos significados. En la especificación
> maestra, CRI = Constancia de Registro de Ingresos (el "pasaporte fiscal" del
> contribuyente). En el archivo cri-completo-siim.sql, CRI = Clasificador por Rubro
> de Ingresos (estructura contable CONAC). Son cosas diferentes.

---

## 3. Cobertura por fases (según la especificación maestra)

| Fase | Módulo | Especificado | Implementado |
|---|---|:---:|:---:|
| F0 | Fundamentos: schemas y convenciones | Sí | parcial (en spec) |
| F1 | Usuarios, roles y seguridad (RBAC) | Sí | No |
| F2 | Padrón de contribuyentes | Sí | No |
| F3 | Catálogos fiscales (UMA, INPC, recargos) | Sí | No |
| F4 | Catastro: padrón de predios | Sí | guía de valor catastral |
| F5 | CRI (Constancia de Registro de Ingresos) | Sí | No |
| F6 | Módulo de caja (cajas, folios, cortes) | Sí | No |
| F7 | Administrador de ingresos | Sí | No |
| F8 | Licencias de funcionamiento | Sí | guía DSA/licencias |
| F9 | Auditoría centralizada | Sí | No |
| -- | ISABI (impuesto adquisición de inmuebles) | Sí | SQL completo |
| -- | Clasificador CONAC (CRI) | Sí | SQL completo |
| -- | ZOFEMAT | guía | No |

---

## 4. Próximos pasos sugeridos

1. Recuperar lo que falte de otras conversaciones. Revisa tu historial de chats por
   si el backend FastAPI o el frontend React quedaron en otra conversación
   (busca: "SIIM", "FastAPI", "React", "microservicio", "testing").
2. Blindar en GitHub: subir este repositorio a un remoto privado para historial y respaldo.
3. Reconstruir el backend por fases (F0 -> F1 -> ...), reutilizando el SQL ya recuperado.
4. Retomar el testing, que era el punto donde se quedó el trabajo original.

---

## 5. Qué verificar (para no dar nada por sentado)

- [ ] Confirmar si existe código Python/FastAPI en otras conversaciones o carpetas.
- [ ] Confirmar si existe la plantilla de frontend Svelte mencionada en la spec.
- [ ] Validar que los scripts SQL corren sin error sobre una BD nueva de PostgreSQL.
- [ ] Revisar si hay más artefactos (diagramas, .env de ejemplo, seeds) en otras conversaciones.

- [ ] Portar ISABI y el clasificador CONAC de T-SQL (SQL Server) a PostgreSQL.
