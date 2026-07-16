-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  SIIM — FASE 0: INICIALIZACIÓN DE SCHEMAS, SECUENCIAS Y CONVENCIONES      ║
-- ║  H. Ayuntamiento del Municipio de Tulum, Quintana Roo                    ║
-- ║  Motor: PostgreSQL 14+                                                    ║
-- ║  Ejecutar PRIMERO, sobre una base de datos NUEVA y VACÍA.                 ║
-- ╚══════════════════════════════════════════════════════════════════════════╝
--
-- CONVENCIONES ESTÁNDAR (aplican a TODAS las tablas del sistema):
--   PK transaccional : BIGINT GENERATED ALWAYS AS IDENTITY
--   PK catálogo      : INT   GENERATED ALWAYS AS IDENTITY
--   Fechas           : DATE (solo fecha) | TIMESTAMPTZ (fecha+hora con zona)
--   Importes         : NUMERIC(14,4) internos | NUMERIC(12,2) presentación
--   Flags            : BOOLEAN DEFAULT false
--   Soft delete      : columna 'activo' BOOLEAN DEFAULT true en todas las tablas
--   Texto largo      : TEXT
--   Auditoría base   : fecha_creacion, fecha_modificacion,
--                      id_usuario_creacion, id_usuario_modificacion
-- ════════════════════════════════════════════════════════════════════════════

-- ══════════════════════════════════════════════════════════════════
-- SECCIÓN 1: CREACIÓN DE SCHEMAS (uno por dominio de negocio)
-- ══════════════════════════════════════════════════════════════════
CREATE SCHEMA IF NOT EXISTS core;
CREATE SCHEMA IF NOT EXISTS caja;
CREATE SCHEMA IF NOT EXISTS catalogos;
CREATE SCHEMA IF NOT EXISTS predial;
CREATE SCHEMA IF NOT EXISTS licencias;
CREATE SCHEMA IF NOT EXISTS auditoria;
-- Nota: el schema 'isabi' se crea en sus propios scripts (database/isabi/).
-- Futuros: agua, transito, registro_civil, zofemat, saneamiento, salud, proteccion_civil.

-- ══════════════════════════════════════════════════════════════════
-- SECCIÓN 2: SECUENCIAS PARA FOLIOS (garantizan unicidad en concurrencia)
-- ══════════════════════════════════════════════════════════════════
CREATE SEQUENCE IF NOT EXISTS core.seq_contribuyente AS BIGINT START 1 INCREMENT 1 NO CYCLE;
CREATE SEQUENCE IF NOT EXISTS core.seq_cri           AS BIGINT START 1 INCREMENT 1 NO CYCLE;
CREATE SEQUENCE IF NOT EXISTS caja.seq_pase_caja     AS BIGINT START 1 INCREMENT 1 NO CYCLE;
CREATE SEQUENCE IF NOT EXISTS caja.seq_folio_recibo  AS BIGINT START 1 INCREMENT 1 NO CYCLE;
CREATE SEQUENCE IF NOT EXISTS licencias.seq_licencia AS BIGINT START 1 INCREMENT 1 NO CYCLE;

DO $$ BEGIN RAISE NOTICE '>> Fase 0 completada: schemas y secuencias creados.'; END $$;
