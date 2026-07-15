# 🏛️ PROMPT MAESTRO — SISTEMA INTEGRAL DE INGRESOS MUNICIPALES
## H. Ayuntamiento del Municipio de Tulum, Quintana Roo
## Construcción desde cero — Versión 1.0

---

> **¿CÓMO USAR ESTE PROMPT?**
> Este documento es la especificación técnica completa del sistema.
> Está dividido en **FASES** y cada fase en **MÓDULOS**.
> Cada módulo tiene su propio bloque `[IMPLEMENTAR]`.
> Entrega un módulo a la vez al modelo de IA o al equipo de desarrollo.
> El orden de implementación importa: respeta la secuencia de fases.

---

## 🎯 VISIÓN GENERAL DEL SISTEMA

Eres un arquitecto de software senior con experiencia en sistemas de gobierno municipal.
Debes construir el **Sistema Integral de Ingresos Municipales (SIIM)** para el
H. Ayuntamiento de Tulum, Quintana Roo, desde cero, con capacidad de escalar a todos
los módulos de recaudación: Predial, Licencias de Funcionamiento, Agua,
Desarrollo Urbano, Protección Civil, Saneamiento Ambiental, ZOFEMAT, Tránsito,
Registro Civil, Multas y ISABI.

El sistema debe ser **robusto, auditable, escalable y apegado al marco legal vigente**
(Ley de Hacienda del Municipio de Tulum, POE 10-12-2025; Ley de Ingresos 2026,
Decreto 162; Código Fiscal Municipal del Estado de Quintana Roo).

---

## 🏗️ STACK TECNOLÓGICO — INAMOVIBLE

```
Backend API:      Python 3.11+  |  FastAPI 0.110+
ORM:              SQLAlchemy 2.x (async, Core + ORM)
Base de datos:    Microsoft SQL Server 2019/2022
Migraciones:      Alembic
Validación:       Pydantic v2
Autenticación:    JWT (python-jose) + OAuth2PasswordBearer
Permisos:         RBAC (Role-Based Access Control) propio
Task Queue:       Celery + Redis
Frontend:         React 18 + TypeScript  (el usuario ya tiene una plantilla)
UI Components:    [respetar la plantilla existente del usuario]
HTTP Client FE:   Axios + React Query (TanStack Query v5)
Estado global FE: Zustand
PDF:              WeasyPrint (HTML→PDF) o ReportLab
Logging:          Loguru
Testing:          pytest + pytest-asyncio + httpx (TestClient)
Contenedores:     Docker + docker-compose
```

---

## 📐 ARQUITECTURA GENERAL

```
┌─────────────────────────────────────────────────────────────┐
│                    FRONTEND (React + TS)                      │
│  Módulo Admin │ Módulo Cajas │ Módulos por Trámite            │
└──────────────────────────┬──────────────────────────────────┘
                           │ HTTP/REST (OpenAPI)
┌──────────────────────────▼──────────────────────────────────┐
│                  API GATEWAY / ROUTER                         │
│              (FastAPI principal - puerto 8000)                │
└──┬───────────┬──────────┬──────────┬───────────┬────────────┘
   │           │          │          │           │
   ▼           ▼          ▼          ▼           ▼
ms_core    ms_caja   ms_predial  ms_licencias  ms_*
(usuarios  (cajas,   (catastro,  (licencias,   (futuros
 contrib.  pases,    predial,    giros,        módulos)
 catálogos folios)   ISABI)      PC, DU, DSA)
   │           │          │          │           │
   └───────────┴──────────┴──────────┴───────────┘
                           │
              ┌────────────▼────────────┐
              │   SQL Server 2019/2022   │
              │  Schemas: core / caja /  │
              │  predial / licencias /   │
              │  catalogos / auditoria   │
              └─────────────────────────┘
```

---

# ═══════════════════════════════════════════════════════
# FASE 0 — FUNDAMENTOS: SCHEMAS Y CONVENCIONES SQL SERVER
# ═══════════════════════════════════════════════════════

## [IMPLEMENTAR F0-A] Convenciones de base de datos

Antes de cualquier tabla, establece estas convenciones globales en T-SQL:

```sql
-- SCHEMAS A CREAR (uno por dominio de negocio)
CREATE SCHEMA core;        -- usuarios, roles, permisos, contribuyentes, catálogos globales
CREATE SCHEMA caja;        -- cajas, cajeros, pases de caja, folios, series, cortes
CREATE SCHEMA catalogos;   -- catálogos compartidos: UMA, INPC, recargos, fuentes de ingreso
CREATE SCHEMA predial;     -- padrón catastral, predios, avalúos, predial
CREATE SCHEMA licencias;   -- licencias de funcionamiento, giros, tarifas
CREATE SCHEMA auditoria;   -- logs de auditoría centralizados de todos los módulos
-- (futuros: agua, transito, registro_civil, zofemat, saneamiento, etc.)

-- TIPOS DE DATOS ESTÁNDAR (usarlos en TODAS las tablas)
-- PK:               BIGINT IDENTITY(1,1)  o  INT IDENTITY(1,1) para catálogos
-- Fechas:           DATE para solo fecha, DATETIME2(0) para fecha+hora
-- Importes:         DECIMAL(14,4) para cálculos internos, DECIMAL(12,2) para presentación
-- RFC:              VARCHAR(15) + CHECK con patrón
-- Texto corto:      VARCHAR(n) con n definido por negocio
-- Texto largo:      NVARCHAR(MAX) solo cuando sea necesario
-- Flags booleanos:  BIT DEFAULT 0
-- Soft delete:      BIT activo DEFAULT 1 en TODAS las tablas
-- Auditoría base:   fecha_creacion DATETIME2 DEFAULT GETDATE(),
--                   fecha_modificacion DATETIME2,
--                   id_usuario_creacion INT,
--                   id_usuario_modificacion INT

-- TRIGGER ESTÁNDAR de auditoría (aplicar a TODAS las tablas con fecha_modificacion)
-- [IMPLEMENTAR como template reutilizable]

-- SECUENCIAS para folios (evitar colisiones en alta concurrencia)
CREATE SEQUENCE caja.seq_pase_caja START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE caja.seq_folio_recibo START WITH 1 INCREMENT BY 1;
-- (más secuencias por módulo según se definan)
```

---

# ═══════════════════════════════════════════════════════
# FASE 1 — MÓDULO CORE: USUARIOS, ROLES Y SEGURIDAD
# ═══════════════════════════════════════════════════════

## [IMPLEMENTAR F1-A] DDL — Schema CORE: Usuarios y Seguridad

```sql
-- ─── DEPENDENCIAS ORGANIZACIONALES ──────────────────────────────────────

-- Dependencias del ayuntamiento (Tesorería, Catastro, PC, etc.)
core.cat_dependencia
  id_dependencia        INT IDENTITY PK
  clave                 VARCHAR(20) UNIQUE NOT NULL       -- TES, CAT, PC, DU, RC
  nombre                VARCHAR(200) NOT NULL
  nombre_corto          VARCHAR(50)
  responsable           VARCHAR(200)
  activo                BIT DEFAULT 1
  [+ campos auditoría estándar]

-- Áreas dentro de cada dependencia
core.cat_area
  id_area               INT IDENTITY PK
  id_dependencia        INT FK -> cat_dependencia
  clave                 VARCHAR(20) NOT NULL
  nombre                VARCHAR(200) NOT NULL
  activo                BIT DEFAULT 1
  [+ campos auditoría estándar]

-- ─── USUARIOS ────────────────────────────────────────────────────────────

core.usuario
  id_usuario            INT IDENTITY PK
  id_area               INT FK -> cat_area
  username              VARCHAR(50) UNIQUE NOT NULL
  email                 VARCHAR(200) UNIQUE NOT NULL
  password_hash         VARCHAR(255) NOT NULL             -- bcrypt
  nombre                VARCHAR(100) NOT NULL
  apellido_paterno      VARCHAR(100) NOT NULL
  apellido_materno      VARCHAR(100)
  nombre_completo       AS (nombre+' '+apellido_paterno+' '+ISNULL(apellido_materno,'')) PERSISTED
  telefono              VARCHAR(20)
  extension             VARCHAR(10)
  curp                  VARCHAR(20)
  rfc_usuario           VARCHAR(15)
  foto_url              VARCHAR(500)
  -- Control de sesión
  ultimo_login          DATETIME2
  intentos_fallidos     TINYINT DEFAULT 0
  bloqueado             BIT DEFAULT 0
  fecha_bloqueo         DATETIME2
  motivo_bloqueo        VARCHAR(300)
  -- Vigencia del usuario
  fecha_alta            DATE NOT NULL DEFAULT CAST(GETDATE() AS DATE)
  fecha_baja            DATE
  activo                BIT DEFAULT 1
  debe_cambiar_password BIT DEFAULT 1
  fecha_ultimo_password DATETIME2
  [+ campos auditoría estándar]

-- ─── RBAC: ROLES Y PERMISOS ───────────────────────────────────────────────

-- Módulos del sistema
core.cat_modulo
  id_modulo             INT IDENTITY PK
  clave                 VARCHAR(50) UNIQUE NOT NULL       -- CORE, CAJA, PREDIAL, LICENCIAS...
  nombre                VARCHAR(200) NOT NULL
  descripcion           VARCHAR(500)
  icono                 VARCHAR(100)                      -- nombre del ícono en el frontend
  ruta_base             VARCHAR(200)                      -- /predial, /licencias, etc.
  orden_menu            INT DEFAULT 0
  activo                BIT DEFAULT 1

-- Acciones posibles por módulo
core.cat_permiso
  id_permiso            INT IDENTITY PK
  id_modulo             INT FK -> cat_modulo
  clave                 VARCHAR(100) UNIQUE NOT NULL      -- PREDIAL:CONSULTAR, CAJA:COBRAR
  nombre                VARCHAR(200) NOT NULL
  descripcion           VARCHAR(500)
  activo                BIT DEFAULT 1

-- Roles del sistema
core.cat_rol
  id_rol                INT IDENTITY PK
  clave                 VARCHAR(50) UNIQUE NOT NULL
  nombre                VARCHAR(200) NOT NULL
  descripcion           VARCHAR(500)
  es_rol_sistema        BIT DEFAULT 0                    -- roles que no se pueden eliminar
  activo                BIT DEFAULT 1
  [+ campos auditoría estándar]

-- Permisos asignados a cada rol (N:M)
core.rol_permiso
  id_rol_permiso        INT IDENTITY PK
  id_rol                INT FK -> cat_rol
  id_permiso            INT FK -> cat_permiso
  UNIQUE (id_rol, id_permiso)

-- Roles asignados a cada usuario (un usuario puede tener varios roles)
core.usuario_rol
  id_usuario_rol        INT IDENTITY PK
  id_usuario            INT FK -> usuario
  id_rol                INT FK -> cat_rol
  fecha_asignacion      DATE NOT NULL DEFAULT CAST(GETDATE() AS DATE)
  fecha_expiracion      DATE                             -- NULL = sin expiración
  id_usuario_asigna     INT FK -> usuario
  activo                BIT DEFAULT 1
  UNIQUE (id_usuario, id_rol)

-- Sesiones activas (para control de sesiones simultáneas y revocación)
core.sesion_usuario
  id_sesion             BIGINT IDENTITY PK
  id_usuario            INT FK -> usuario
  token_jti             VARCHAR(100) UNIQUE NOT NULL     -- JWT ID único
  ip_origen             VARCHAR(45)
  user_agent            VARCHAR(500)
  fecha_inicio          DATETIME2 DEFAULT GETDATE()
  fecha_expiracion      DATETIME2 NOT NULL
  revocado              BIT DEFAULT 0
  fecha_revocacion      DATETIME2

-- Log de accesos (auditoría de seguridad)
core.log_acceso
  id_log                BIGINT IDENTITY PK
  id_usuario            INT FK -> usuario NULL            -- NULL si login fallido
  username_intento      VARCHAR(50)
  tipo_evento           VARCHAR(30)                      -- LOGIN_OK / LOGIN_FAIL
                                                         -- LOGOUT / TOKEN_REFRESH
                                                         -- BLOQUEO / CAMBIO_PASSWORD
  ip_origen             VARCHAR(45)
  user_agent            VARCHAR(500)
  detalle               VARCHAR(500)
  fecha_evento          DATETIME2 DEFAULT GETDATE()
```

### Roles predefinidos del sistema (seed obligatorio)

```sql
-- [IMPLEMENTAR como script de seed]
ROLES DEL SISTEMA:
  SUPER_ADMIN       → acceso total al sistema, solo IT
  ADMIN_INGRESOS    → administrador del módulo de ingresos (cajas, tarifas, reportes)
  JEFE_CAJA         → supervisa cajeros, hace cortes, ve todos los movimientos
  CAJERO            → solo puede cobrar trámites asignados y ver sus propios movimientos
  CAPTURISTA        → captura trámites pero no cobra (genera pase de caja)
  REVISOR           → aprueba/rechaza trámites, no cobra
  CONSULTA          → solo lectura en los módulos que se le asignen
  AUDITOR           → acceso solo-lectura a logs y reportes de auditoría
```

---

## [IMPLEMENTAR F1-B] API — Microservicio CORE (usuarios y seguridad)

```
Endpoints de autenticación:
POST   /api/v1/auth/login
POST   /api/v1/auth/refresh
POST   /api/v1/auth/logout
POST   /api/v1/auth/cambiar-password
GET    /api/v1/auth/me                        -- perfil del usuario autenticado

Endpoints de usuarios (requiere rol ADMIN_INGRESOS o SUPER_ADMIN):
GET    /api/v1/usuarios
POST   /api/v1/usuarios
GET    /api/v1/usuarios/{id}
PUT    /api/v1/usuarios/{id}
DELETE /api/v1/usuarios/{id}                  -- soft delete
POST   /api/v1/usuarios/{id}/bloquear
POST   /api/v1/usuarios/{id}/desbloquear
POST   /api/v1/usuarios/{id}/resetear-password
GET    /api/v1/usuarios/{id}/roles
POST   /api/v1/usuarios/{id}/roles
DELETE /api/v1/usuarios/{id}/roles/{id_rol}
GET    /api/v1/usuarios/{id}/permisos          -- permisos efectivos del usuario

Endpoints de roles y permisos:
GET    /api/v1/roles
POST   /api/v1/roles
PUT    /api/v1/roles/{id}
GET    /api/v1/roles/{id}/permisos
PUT    /api/v1/roles/{id}/permisos             -- reemplaza todos los permisos del rol
GET    /api/v1/modulos
GET    /api/v1/permisos
```

### Middleware de seguridad (IMPLEMENTAR en FastAPI)

```python
# Dependency para verificar permisos en cada endpoint
# Uso: Depends(require_permission("PREDIAL:CONSULTAR"))

async def require_permission(permiso_clave: str):
    async def verificar(
        current_user: Usuario = Depends(get_current_user),
        db: AsyncSession = Depends(get_db)
    ) -> Usuario:
        """
        1. Obtener todos los roles activos del usuario
        2. Para cada rol, obtener sus permisos
        3. Verificar si el permiso_clave está en el conjunto
        4. Si no → HTTPException 403
        5. Si sí → retornar usuario
        """
        pass
    return verificar
```

---

# ═══════════════════════════════════════════════════════
# FASE 2 — PADRÓN DE CONTRIBUYENTES
# ═══════════════════════════════════════════════════════

## [IMPLEMENTAR F2-A] DDL — Padrón de Contribuyentes

```sql
-- ─── CATÁLOGOS DE SOPORTE ─────────────────────────────────────────────────

-- Tipos de persona
core.cat_tipo_persona
  id_tipo_persona    TINYINT PK   -- 1=Física, 2=Moral, 3=Unidad Económica, 4=Gobierno
  nombre             VARCHAR(50)

-- Tipos de identificación oficial
core.cat_tipo_identificacion
  id_tipo_id         TINYINT PK
  clave              VARCHAR(20)   -- INE, PASAPORTE, FM2, FM3, CURP, ESCRITURA
  nombre             VARCHAR(100)

-- Colonias / Asentamientos (catálogo SEPOMEX)
core.cat_colonia
  id_colonia         INT IDENTITY PK
  codigo_postal      VARCHAR(10) NOT NULL
  nombre_colonia     VARCHAR(200) NOT NULL
  tipo_asentamiento  VARCHAR(80)
  municipio          VARCHAR(200)
  estado             VARCHAR(100)
  activo             BIT DEFAULT 1

-- ─── CONTRIBUYENTE (tabla central del padrón) ─────────────────────────────

core.contribuyente
  id_contribuyente      BIGINT IDENTITY PK
  numero_contribuyente  VARCHAR(20) UNIQUE NOT NULL      -- generado: CONT-000001
  id_tipo_persona       TINYINT FK -> cat_tipo_persona
  -- Persona física
  nombre                VARCHAR(200)
  apellido_paterno      VARCHAR(200)
  apellido_materno      VARCHAR(200)
  fecha_nacimiento      DATE
  -- Persona moral
  razon_social          VARCHAR(500)
  nombre_comercial      VARCHAR(500)
  fecha_constitucion    DATE
  numero_escritura      VARCHAR(50)
  nombre_notario        VARCHAR(200)
  numero_notaria        VARCHAR(20)
  -- Comunes
  nombre_completo_calc  AS (
    CASE WHEN id_tipo_persona = 1
      THEN TRIM(ISNULL(nombre,'')+' '+ISNULL(apellido_paterno,'')+' '+ISNULL(apellido_materno,''))
      ELSE razon_social
    END
  ) PERSISTED
  rfc                   VARCHAR(15)
  curp                  VARCHAR(20)
  -- Contacto
  email                 VARCHAR(200)
  email_secundario      VARCHAR(200)
  telefono_1            VARCHAR(20)
  telefono_2            VARCHAR(20)
  whatsapp              VARCHAR(20)
  -- Domicilio fiscal
  calle_fiscal          VARCHAR(300)
  numero_exterior_fiscal VARCHAR(20)
  numero_interior_fiscal VARCHAR(20)
  id_colonia_fiscal     INT FK -> cat_colonia
  codigo_postal_fiscal  VARCHAR(10)
  referencia_fiscal     VARCHAR(300)
  -- Representante legal (para personas morales)
  representante_legal   VARCHAR(300)
  cargo_representante   VARCHAR(100)
  -- Identificación
  id_tipo_id            TINYINT FK -> cat_tipo_identificacion
  numero_identificacion VARCHAR(100)
  vigencia_identificacion DATE
  -- Estado en el padrón
  activo                BIT DEFAULT 1
  fecha_alta            DATE DEFAULT CAST(GETDATE() AS DATE)
  fecha_baja            DATE
  motivo_baja           VARCHAR(300)
  -- Observaciones
  observaciones         NVARCHAR(MAX)
  [+ campos auditoría estándar]

-- Documentos del contribuyente (escaneados)
core.contribuyente_documento
  id_documento          BIGINT IDENTITY PK
  id_contribuyente      BIGINT FK -> contribuyente
  tipo_documento        VARCHAR(50)     -- IDENTIFICACION / ACTA_CONSTITUTIVA / RFC
                                        -- PODER_NOTARIAL / COMPROBANTE_DOMICILIO
  nombre_archivo        VARCHAR(300)
  ruta_almacenamiento   VARCHAR(500)    -- path en servidor de archivos
  tamanio_bytes         BIGINT
  mime_type             VARCHAR(100)
  fecha_subida          DATETIME2 DEFAULT GETDATE()
  subido_por            INT FK -> core.usuario
  activo                BIT DEFAULT 1

-- Historial de cambios del contribuyente
core.contribuyente_historial
  id_historial          BIGINT IDENTITY PK
  id_contribuyente      BIGINT FK -> contribuyente
  campo_modificado      VARCHAR(100)
  valor_anterior        NVARCHAR(MAX)
  valor_nuevo           NVARCHAR(MAX)
  fecha_modificacion    DATETIME2 DEFAULT GETDATE()
  id_usuario            INT FK -> core.usuario
  motivo                VARCHAR(500)
```

### Endpoints del padrón de contribuyentes

```
GET    /api/v1/contribuyentes?q=&rfc=&tipo=&pagina=&limite=
POST   /api/v1/contribuyentes
GET    /api/v1/contribuyentes/{id}
PUT    /api/v1/contribuyentes/{id}
DELETE /api/v1/contribuyentes/{id}            -- soft delete
GET    /api/v1/contribuyentes/buscar-rfc/{rfc}
GET    /api/v1/contribuyentes/{id}/tramites    -- todos los trámites del contribuyente
GET    /api/v1/contribuyentes/{id}/documentos
POST   /api/v1/contribuyentes/{id}/documentos
GET    /api/v1/contribuyentes/{id}/historial
GET    /api/v1/contribuyentes/{id}/estado-cuenta  -- deuda consolidada de todos módulos
```

---

# ═══════════════════════════════════════════════════════
# FASE 3 — CATÁLOGOS FISCALES Y FINANCIEROS
# ═══════════════════════════════════════════════════════

## [IMPLEMENTAR F3-A] DDL — Schema CATALOGOS: UMA, INPC, Recargos

```sql
-- ─── UMA (Unidad de Medida y Actualización) ───────────────────────────────
catalogos.uma_anual
  id_uma             INT IDENTITY PK
  ejercicio_fiscal   INT UNIQUE NOT NULL
  valor_diario       DECIMAL(12,4) NOT NULL     -- ej: 113.14 para 2026
  valor_mensual      DECIMAL(12,4) NOT NULL     -- valor_diario * 30.4
  valor_anual        DECIMAL(12,4) NOT NULL     -- valor_diario * 365
  fecha_publicacion_dof DATE NOT NULL
  vigente_desde      DATE NOT NULL
  vigente_hasta      DATE
  numero_dof         VARCHAR(50)                -- número del DOF donde se publicó
  activo             BIT DEFAULT 1
  [+ campos auditoría estándar]

-- ─── INPC (Índice Nacional de Precios al Consumidor) ──────────────────────
-- Para actualización de contribuciones vencidas (Art. del Código Fiscal Municipal)
catalogos.inpc_mensual
  id_inpc            BIGINT IDENTITY PK
  anio               INT NOT NULL
  mes                TINYINT NOT NULL            -- 1=Enero ... 12=Diciembre
  valor_inpc         DECIMAL(12,6) NOT NULL      -- publicado por INEGI/Banxico
  fecha_publicacion  DATE
  fuente             VARCHAR(100) DEFAULT 'INEGI'
  UNIQUE (anio, mes)

-- Factor de actualización: INPC_mes_anterior_exigibilidad / INPC_mes_anterior_causacion
-- [IMPLEMENTAR como función T-SQL]
CREATE FUNCTION catalogos.fn_factor_actualizacion(
  @fecha_causacion  DATE,
  @fecha_exigible   DATE
) RETURNS DECIMAL(12,6)

-- ─── TASAS DE RECARGOS ────────────────────────────────────────────────────
-- Los recargos se aplican sobre contribuciones no pagadas en tiempo
catalogos.tasa_recargo
  id_recargo         INT IDENTITY PK
  ejercicio_fiscal   INT NOT NULL
  tasa_mensual       DECIMAL(8,6) NOT NULL       -- ej: 0.0125 = 1.25% mensual
  tasa_diaria        AS (tasa_mensual / 30.0) PERSISTED
  fundamento_legal   VARCHAR(300)                -- Art. X del Código Fiscal Municipal
  vigente_desde      DATE NOT NULL
  vigente_hasta      DATE
  activo             BIT DEFAULT 1
  [+ campos auditoría estándar]

-- Tabla de multas por tipo de infracción fiscal
catalogos.cat_multa_fiscal
  id_multa           INT IDENTITY PK
  clave              VARCHAR(30) UNIQUE NOT NULL
  descripcion        VARCHAR(500) NOT NULL
  tipo_calculo       VARCHAR(20) NOT NULL        -- FIJA / PORCENTAJE_OMITIDO
                                                  -- RANGO_UMA
  valor_minimo       DECIMAL(10,4)               -- en UMAs o porcentaje
  valor_maximo       DECIMAL(10,4)
  fundamento_legal   VARCHAR(300)
  activo             BIT DEFAULT 1

-- ─── EJERCICIOS FISCALES ──────────────────────────────────────────────────
catalogos.ejercicio_fiscal
  id_ejercicio       INT IDENTITY PK
  anio               INT UNIQUE NOT NULL
  fecha_inicio       DATE NOT NULL DEFAULT '2026-01-01'
  fecha_fin          DATE NOT NULL DEFAULT '2026-12-31'
  estado             VARCHAR(20) DEFAULT 'ACTIVO'   -- FUTURO / ACTIVO / CERRADO
  permite_modificaciones BIT DEFAULT 1
  fecha_cierre       DATETIME2
  id_usuario_cierre  INT FK -> core.usuario
  observaciones      VARCHAR(500)

-- ─── FUENTES DE INGRESOS ──────────────────────────────────────────────────
-- Clasificación presupuestal de todos los conceptos de cobro del municipio
catalogos.fuente_ingreso
  id_fuente          INT IDENTITY PK
  clave              VARCHAR(30) UNIQUE NOT NULL
  -- Clasificación CONAC (Consejo Nacional de Armonización Contable)
  clave_conac        VARCHAR(30)
  -- Clasificación por tipo
  tipo               VARCHAR(30) NOT NULL          -- IMPUESTO / DERECHO / PRODUCTO
                                                    -- APROVECHAMIENTO / PARTICIPACION
                                                    -- APORTACION / CONVENIO
  subtipo            VARCHAR(50)                   -- PREDIAL / ISABI / RECOLECCION / etc.
  nombre             VARCHAR(300) NOT NULL
  descripcion        VARCHAR(500)
  cuenta_contable    VARCHAR(50)                   -- cuenta del Plan de Cuentas municipal
  modulo_origen      VARCHAR(50)                   -- PREDIAL / LICENCIAS / CAJA / etc.
  afectable_descuento BIT DEFAULT 0               -- puede tener descuento por pronto pago
  afectable_recargo  BIT DEFAULT 1               -- genera recargos si no se paga
  afectable_actualizacion BIT DEFAULT 1
  activo             BIT DEFAULT 1
  [+ campos auditoría estándar]

-- Tarifas de fuentes de ingreso por ejercicio fiscal
catalogos.tarifa_fuente_ingreso
  id_tarifa          BIGINT IDENTITY PK
  id_fuente          INT FK -> fuente_ingreso
  id_ejercicio       INT FK -> ejercicio_fiscal
  -- Tipo de tarifa
  tipo_tarifa        VARCHAR(30) NOT NULL          -- FIJA_MXN / UMA_DIARIA / PORCENTAJE
                                                    -- TABLA / CALCULADA
  valor_base         DECIMAL(14,4)                 -- monto fijo en MXN o número de UMAs
  porcentaje         DECIMAL(8,6)                  -- si tipo = PORCENTAJE
  -- Monto calculado al inicio del ejercicio (cache)
  monto_mxn_calculado DECIMAL(12,2)
  valor_uma_aplicado  DECIMAL(12,4)
  -- Descuentos por pronto pago
  pct_descuento_enero DECIMAL(5,2) DEFAULT 0       -- ej: 25.00 = 25%
  pct_descuento_febrero DECIMAL(5,2) DEFAULT 0
  -- Vigencia
  vigente_desde      DATE NOT NULL
  vigente_hasta      DATE
  fundamento_legal   VARCHAR(500)
  activo             BIT DEFAULT 1
  [+ campos auditoría estándar]
```

---

# ═══════════════════════════════════════════════════════
# FASE 4 — CATASTRO: PADRÓN DE PREDIOS (BASE PARA PREDIAL E ISABI)
# ═══════════════════════════════════════════════════════

## [IMPLEMENTAR F4-A] DDL — Schema PREDIAL: Catastro

```sql
-- ─── CATÁLOGOS CATASTRALES ────────────────────────────────────────────────

predial.cat_tipo_predio
  id_tipo_predio     TINYINT PK
  clave              VARCHAR(20)           -- URBANO_EDIFICADO / URBANO_BALDIO
                                           -- RUSTICO / EJIDAL_URBANO / CONDOMINAL
  nombre             VARCHAR(100)
  tasa_predial       DECIMAL(10,8)         -- tasa aplicable (ej: 0.00170000)
  activo             BIT DEFAULT 1

predial.cat_uso_suelo
  id_uso_suelo       INT IDENTITY PK
  clave              VARCHAR(20) UNIQUE NOT NULL
  nombre             VARCHAR(200) NOT NULL
  descripcion        VARCHAR(500)
  permite_comercio   BIT DEFAULT 0
  permite_habitacion BIT DEFAULT 1
  activo             BIT DEFAULT 1

predial.cat_zona_catastral
  id_zona            INT IDENTITY PK
  clave              VARCHAR(20) UNIQUE NOT NULL    -- Z-01, Z-02, ZC-AKUMAL
  nombre             VARCHAR(200) NOT NULL
  descripcion        VARCHAR(300)
  -- Coeficientes de la zona
  factor_zona        DECIMAL(8,4) DEFAULT 1.0000
  -- Colindancia ZOFEMAT
  colinda_zofemat    BIT DEFAULT 0
  activo             BIT DEFAULT 1

-- ─── PREDIO (núcleo del catastro) ────────────────────────────────────────

predial.predio
  id_predio             BIGINT IDENTITY PK
  clave_catastral       VARCHAR(30) UNIQUE NOT NULL   -- formato municipal
  cuenta_predial        VARCHAR(20) UNIQUE            -- número de cuenta para cobro
  id_contribuyente      BIGINT FK -> core.contribuyente
  id_tipo_predio        TINYINT FK -> cat_tipo_predio
  id_uso_suelo          INT FK -> cat_uso_suelo
  id_zona_catastral     INT FK -> cat_zona_catastral
  -- Ubicación
  calle                 VARCHAR(300)
  numero_exterior       VARCHAR(20)
  numero_interior       VARCHAR(20)
  id_colonia            INT FK -> core.cat_colonia
  codigo_postal         VARCHAR(10)
  referencia_ubicacion  VARCHAR(500)
  latitud               DECIMAL(12,8)
  longitud              DECIMAL(12,8)
  -- Medidas
  superficie_terreno_m2 DECIMAL(12,2)
  superficie_construida_m2 DECIMAL(12,2)
  numero_niveles        TINYINT DEFAULT 1
  -- Valores catastrales (actualizados en cada avalúo)
  valor_catastral_suelo    DECIMAL(14,2)
  valor_catastral_construccion DECIMAL(14,2)
  valor_catastral_total    AS (ISNULL(valor_catastral_suelo,0) + ISNULL(valor_catastral_construccion,0)) PERSISTED
  fecha_ultimo_avaluo      DATE
  vigencia_avaluo          DATE
  -- Colindancias especiales
  colinda_zofemat       BIT DEFAULT 0
  distancia_linea_costa DECIMAL(8,2)       -- metros
  -- Régimen de propiedad
  regimen_propiedad     VARCHAR(30)         -- PLENA / CONDOMINIO / FIDEICOMISO / EJIDAL
  -- Estado del predio
  estado_predio         VARCHAR(20) DEFAULT 'ACTIVO'  -- ACTIVO / BAJA / LITIGIOSO
  fecha_alta            DATE DEFAULT CAST(GETDATE() AS DATE)
  fecha_baja            DATE
  motivo_baja           VARCHAR(300)
  activo                BIT DEFAULT 1
  observaciones         NVARCHAR(MAX)
  [+ campos auditoría estándar]

-- Historial de propietarios del predio (para ISABI y trazabilidad)
predial.predio_propietario_historial
  id_historial          BIGINT IDENTITY PK
  id_predio             BIGINT FK -> predio
  id_contribuyente      BIGINT FK -> core.contribuyente
  tipo_adquisicion      VARCHAR(50)         -- COMPRAVENTA / HERENCIA / DONACION
                                             -- REMATE / DACION_PAGO / PERMUTA
  fecha_adquisicion     DATE NOT NULL
  fecha_escritura       DATE
  folio_real_registral  VARCHAR(50)
  numero_escritura      VARCHAR(50)
  nombre_notario        VARCHAR(200)
  valor_adquisicion     DECIMAL(14,2)
  id_pago_isabi         BIGINT              -- FK a pago del ISABI correspondiente
  activo                BIT DEFAULT 1
  [+ campos auditoría estándar]
```

---

# ═══════════════════════════════════════════════════════
# FASE 5 — CRI: CONSTANCIA DE REGISTRO DE INGRESOS
# ═══════════════════════════════════════════════════════

## [IMPLEMENTAR F5-A] ¿Qué es el CRI y cómo funciona?

El **CRI (Constancia de Registro de Ingresos)** es el documento oficial que acredita
que un contribuyente está registrado en el padrón de ingresos del municipio y tiene
regularizado su situación fiscal. Es transversal a todos los módulos y actúa como
"pasaporte fiscal municipal".

```sql
-- ─── CRI ────────────────────────────────────────────────────────────────

core.cri
  id_cri                BIGINT IDENTITY PK
  folio_cri             VARCHAR(30) UNIQUE NOT NULL    -- CRI-2026-000001
  id_contribuyente      BIGINT FK -> contribuyente
  -- Módulos incluidos en el CRI
  incluye_predial       BIT DEFAULT 0
  incluye_licencias     BIT DEFAULT 0
  incluye_agua          BIT DEFAULT 0
  incluye_transito      BIT DEFAULT 0
  -- Estado fiscal por módulo (snapshot al momento de emisión)
  estado_predial        VARCHAR(20)     -- AL_CORRIENTE / CON_ADEUDO / NO_APLICA
  estado_licencias      VARCHAR(20)
  estado_agua           VARCHAR(20)
  estado_transito       VARCHAR(20)
  -- Deudas resumidas al momento de emisión
  total_adeudo_predial  DECIMAL(12,2) DEFAULT 0
  total_adeudo_licencias DECIMAL(12,2) DEFAULT 0
  total_adeudo_agua     DECIMAL(12,2) DEFAULT 0
  -- Estado general del CRI
  estado_cri            VARCHAR(20) NOT NULL    -- ACTIVO / VENCIDO / CANCELADO
  -- Al corriente = todos los módulos incluidos están AL_CORRIENTE
  al_corriente          AS (
    CASE WHEN estado_predial IN ('AL_CORRIENTE','NO_APLICA')
          AND estado_licencias IN ('AL_CORRIENTE','NO_APLICA')
          AND estado_agua IN ('AL_CORRIENTE','NO_APLICA')
          AND estado_transito IN ('AL_CORRIENTE','NO_APLICA')
    THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END
  ) PERSISTED
  -- Vigencia
  fecha_emision         DATETIME2 DEFAULT GETDATE()
  vigente_hasta         DATETIME2 NOT NULL     -- normalmente 30 días después de emisión
  -- Uso del CRI
  motivo_solicitud      VARCHAR(300)           -- para qué se solicitó
  usado_en_tramite      VARCHAR(100)           -- folio del trámite donde se usó
  fecha_uso             DATETIME2
  -- Generado por
  id_usuario_emite      INT FK -> core.usuario
  ip_emision            VARCHAR(45)
  -- QR de verificación
  url_verificacion      VARCHAR(500)           -- https://tulum.gob.mx/verificar/CRI-2026-000001
  hash_verificacion     VARCHAR(64)            -- SHA-256 del contenido para validar autenticidad
  activo                BIT DEFAULT 1
  [+ campos auditoría estándar]

-- Detalle de adeudos incluidos en el CRI
core.cri_detalle_adeudo
  id_detalle            BIGINT IDENTITY PK
  id_cri                BIGINT FK -> cri
  modulo                VARCHAR(50)         -- PREDIAL / LICENCIAS / AGUA
  concepto              VARCHAR(300)
  ejercicio             INT
  monto_principal       DECIMAL(12,2)
  monto_actualizacion   DECIMAL(12,2) DEFAULT 0
  monto_recargos        DECIMAL(12,2) DEFAULT 0
  monto_multas          DECIMAL(12,2) DEFAULT 0
  total_adeudo          AS (monto_principal + monto_actualizacion + monto_recargos + monto_multas) PERSISTED
  folio_referencia      VARCHAR(50)         -- folio del crédito fiscal en el módulo correspondiente
```

### Lógica del CRI (IMPLEMENTAR en Python)

```python
class CRIService:
    """
    Genera el CRI consultando en tiempo real todos los módulos activos.
    
    Proceso:
    1. Recibir id_contribuyente + módulos a incluir
    2. Consultar en paralelo (asyncio.gather):
       - PredialService.obtener_estado_fiscal(id_contribuyente)
       - LicenciasService.obtener_estado_fiscal(id_contribuyente)
       - AguaService.obtener_estado_fiscal(id_contribuyente) [futuro]
    3. Consolidar resultado
    4. Generar folio único con SEQUENCE SQL Server
    5. Calcular hash de verificación (SHA-256)
    6. Generar QR con URL de verificación
    7. Guardar snapshot en BD
    8. Generar PDF oficial
    9. Retornar CRI + PDF
    
    El CRI tiene vigencia de 30 días calendario.
    Después de usarse en un trámite, queda marcado como 'utilizado'.
    """
    
    async def generar_cri(
        self,
        id_contribuyente: int,
        modulos: list[str],
        motivo_solicitud: str,
        id_usuario: int
    ) -> CRIResult:
        pass
    
    async def verificar_cri(self, folio_cri: str, hash_verificacion: str) -> CRIVerificacionResult:
        """Endpoint público de verificación (no requiere autenticación)"""
        pass
```

---

# ═══════════════════════════════════════════════════════
# FASE 6 — MÓDULO DE CAJA: CAJEROS, CAJAS, FOLIOS, SERIES
# ═══════════════════════════════════════════════════════

## [IMPLEMENTAR F6-A] DDL — Schema CAJA completo

```sql
-- ─── CAJAS FÍSICAS ───────────────────────────────────────────────────────

caja.caja
  id_caja               INT IDENTITY PK
  clave                 VARCHAR(20) UNIQUE NOT NULL   -- CAJA-01, CAJA-02
  nombre                VARCHAR(100) NOT NULL          -- "Caja 1 - Planta Baja"
  ubicacion             VARCHAR(200)
  id_area               INT FK -> core.cat_area        -- área que la opera
  -- Configuración de la caja
  activa                BIT DEFAULT 1
  permite_efectivo      BIT DEFAULT 1
  permite_tarjeta       BIT DEFAULT 1
  permite_transferencia BIT DEFAULT 1
  permite_cheque        BIT DEFAULT 0
  -- Estado operativo
  estado                VARCHAR(20) DEFAULT 'CERRADA'  -- ABIERTA / CERRADA / BLOQUEADA
  id_cajero_actual      INT FK -> core.usuario NULL    -- quién la tiene abierta
  fecha_apertura_actual DATETIME2
  saldo_inicial_actual  DECIMAL(12,2)
  [+ campos auditoría estándar]

-- ─── SESIONES DE CAJA (cortes) ───────────────────────────────────────────

caja.sesion_caja
  id_sesion_caja        BIGINT IDENTITY PK
  id_caja               INT FK -> caja
  id_cajero             INT FK -> core.usuario
  id_supervisor_apertura INT FK -> core.usuario
  id_supervisor_cierre   INT FK -> core.usuario NULL
  -- Apertura
  fecha_apertura        DATETIME2 NOT NULL DEFAULT GETDATE()
  saldo_inicial         DECIMAL(12,2) NOT NULL DEFAULT 0
  -- Cierre
  fecha_cierre          DATETIME2
  saldo_final_sistema   DECIMAL(12,2)   -- calculado por el sistema
  saldo_final_fisico    DECIMAL(12,2)   -- contado por el cajero
  diferencia            AS (ISNULL(saldo_final_fisico,0) - ISNULL(saldo_final_sistema,0)) PERSISTED
  -- Totales del corte
  total_efectivo        DECIMAL(12,2) DEFAULT 0
  total_tarjeta         DECIMAL(12,2) DEFAULT 0
  total_transferencia   DECIMAL(12,2) DEFAULT 0
  total_cheque          DECIMAL(12,2) DEFAULT 0
  total_recibido        AS (total_efectivo + total_tarjeta + total_transferencia + total_cheque) PERSISTED
  num_operaciones       INT DEFAULT 0
  num_pases_cobrados    INT DEFAULT 0
  -- Estado
  estado                VARCHAR(20) DEFAULT 'ABIERTA'  -- ABIERTA / CERRADA / CONCILIADA
  observaciones_cierre  VARCHAR(500)
  [+ campos auditoría estándar]

-- ─── SERIES DE FOLIOS ────────────────────────────────────────────────────

caja.serie_folio
  id_serie              INT IDENTITY PK
  clave_serie           VARCHAR(20) UNIQUE NOT NULL    -- A, B, C, REC-2026, etc.
  descripcion           VARCHAR(200)
  ejercicio_fiscal      INT NOT NULL
  id_caja               INT FK -> caja NULL            -- NULL = serie global
  modulo                VARCHAR(50)                    -- CAJA / PREDIAL / LICENCIAS / etc.
  tipo_documento        VARCHAR(50)                    -- RECIBO / PASE_CAJA / LICENCIA / CRI
  prefijo               VARCHAR(10)                    -- "REC", "PC", "LF"
  sufijo                VARCHAR(10)
  consecutivo_actual    INT DEFAULT 0
  consecutivo_inicial   INT DEFAULT 1
  consecutivo_final     INT                           -- NULL = sin límite
  longitud_folio        TINYINT DEFAULT 6              -- ceros a la izquierda
  -- Ejemplo: prefijo=REC, ejercicio=2026, consecutivo=1, longitud=6 → REC-2026-000001
  activo                BIT DEFAULT 1
  [+ campos auditoría estándar]

-- Función para generar siguiente folio
CREATE FUNCTION caja.fn_siguiente_folio(@id_serie INT) RETURNS VARCHAR(50)
-- [IMPLEMENTAR con UPDATE OUTPUT para atomicidad]

-- ─── PASES DE CAJA ───────────────────────────────────────────────────────

caja.pase_caja
  id_pase               BIGINT IDENTITY PK
  folio_pase            VARCHAR(30) UNIQUE NOT NULL    -- PC-2026-000001
  id_serie              INT FK -> serie_folio
  -- Origen del trámite
  modulo                VARCHAR(50) NOT NULL            -- PREDIAL / LICENCIAS / AGUA
  tipo_tramite          VARCHAR(100) NOT NULL           -- PAGO_PREDIAL / LICENCIA_NUEVA
  id_tramite            BIGINT NOT NULL                 -- ID en el módulo de origen
  folio_tramite         VARCHAR(50)                     -- folio del trámite de origen
  -- Contribuyente
  id_contribuyente      BIGINT FK -> core.contribuyente
  nombre_contribuyente  VARCHAR(500)
  rfc_contribuyente     VARCHAR(15)
  -- Concepto de cobro
  id_fuente_ingreso     INT FK -> catalogos.fuente_ingreso
  concepto              VARCHAR(500) NOT NULL
  descripcion_desglose  NVARCHAR(MAX)                   -- JSON con desglose
  -- Importes
  monto_base            DECIMAL(12,2) NOT NULL
  monto_descuento       DECIMAL(12,2) DEFAULT 0
  monto_recargos        DECIMAL(12,2) DEFAULT 0
  monto_actualizacion   DECIMAL(12,2) DEFAULT 0
  monto_multas          DECIMAL(12,2) DEFAULT 0
  monto_total           AS (monto_base - monto_descuento + monto_recargos + monto_actualizacion + monto_multas) PERSISTED
  -- Estado del pase
  estado                VARCHAR(20) DEFAULT 'PENDIENTE' -- PENDIENTE / PAGADO / CANCELADO
                                                         -- VENCIDO
  -- Vigencia del pase (si vence, el monto puede cambiar por recargos)
  fecha_generacion      DATETIME2 DEFAULT GETDATE()
  fecha_vencimiento     DATE                            -- normalmente 5 días hábiles
  fecha_pago            DATETIME2
  -- Pago
  id_sesion_caja        BIGINT FK -> sesion_caja NULL
  id_cajero_cobro       INT FK -> core.usuario NULL
  id_caja_cobro         INT FK -> caja NULL
  forma_pago            VARCHAR(30)                     -- EFECTIVO / TARJETA / TRANSFERENCIA / CHEQUE
  referencia_pago       VARCHAR(100)
  -- Cancelación
  cancelado             BIT DEFAULT 0
  motivo_cancelacion    VARCHAR(300)
  id_usuario_cancela    INT FK -> core.usuario NULL
  fecha_cancelacion     DATETIME2
  -- Recibo generado
  folio_recibo          VARCHAR(30)                     -- generado al pagar
  recibo_pdf_url        VARCHAR(500)
  -- Generado por
  id_usuario_genera     INT FK -> core.usuario NOT NULL
  ip_origen             VARCHAR(45)
  [+ campos auditoría estándar]

-- Desglose del pase de caja (para impresión del recibo)
caja.pase_caja_detalle
  id_detalle            BIGINT IDENTITY PK
  id_pase               BIGINT FK -> pase_caja
  orden                 TINYINT
  concepto              VARCHAR(300) NOT NULL
  cantidad              DECIMAL(10,4) DEFAULT 1
  precio_unitario       DECIMAL(12,2) NOT NULL
  importe               AS (cantidad * precio_unitario) PERSISTED
  tipo_linea            VARCHAR(20)             -- CARGO / DESCUENTO / RECARGO / MULTA
```

### Endpoints del módulo de caja

```
# Cajas
GET    /api/v1/cajas
POST   /api/v1/cajas
GET    /api/v1/cajas/{id}
PUT    /api/v1/cajas/{id}
POST   /api/v1/cajas/{id}/abrir                # abre sesión de caja
POST   /api/v1/cajas/{id}/cerrar               # cierra y genera corte
GET    /api/v1/cajas/{id}/sesion-actual

# Series de folios
GET    /api/v1/series-folio
POST   /api/v1/series-folio
PUT    /api/v1/series-folio/{id}
GET    /api/v1/series-folio/{id}/siguiente-folio  # preview sin consumir

# Pases de caja
POST   /api/v1/pases-caja                      # genera el pase (desde cualquier módulo)
GET    /api/v1/pases-caja/{id}
GET    /api/v1/pases-caja/folio/{folio}
GET    /api/v1/pases-caja?estado=&cajero=&fecha_desde=&fecha_hasta=&modulo=
POST   /api/v1/pases-caja/{id}/cobrar          # SOLO cajero con sesión abierta
POST   /api/v1/pases-caja/{id}/cancelar
GET    /api/v1/pases-caja/{id}/recibo-pdf

# Cortes de caja
GET    /api/v1/sesiones-caja
GET    /api/v1/sesiones-caja/{id}
GET    /api/v1/sesiones-caja/{id}/detalle
GET    /api/v1/sesiones-caja/{id}/corte-pdf

# Dashboard de caja (Admin de Ingresos)
GET    /api/v1/caja/dashboard
GET    /api/v1/caja/recaudacion-diaria?fecha=
GET    /api/v1/caja/recaudacion-por-concepto?fecha_desde=&fecha_hasta=
GET    /api/v1/caja/exportar-poliza?fecha=     # exporta póliza contable del día
```

---

# ═══════════════════════════════════════════════════════
# FASE 7 — ADMINISTRADOR DE INGRESOS
# ═══════════════════════════════════════════════════════

## [IMPLEMENTAR F7-A] Módulo del Administrador de Ingresos

Este perfil de usuario es el responsable de toda la operación recaudatoria.
Sus responsabilidades en el sistema:

```
1. GESTIÓN DE CAJAS
   - Crear/configurar cajas físicas
   - Asignar cajeros a cajas
   - Supervisar apertura y cierre de cajas
   - Ver el estado en tiempo real de todas las cajas
   - Hacer conciliaciones del día
   - Generar pólizas contables

2. GESTIÓN DE TARIFAS Y CATÁLOGOS
   - Registrar/actualizar el valor de la UMA cada año
   - Registrar los índices INPC mensualmente
   - Configurar las tasas de recargos
   - Actualizar tarifas de fuentes de ingreso para cada ejercicio
   - Crear y gestionar series de folios

3. CONTROL DE RECAUDACIÓN
   - Dashboard en tiempo real: recaudado hoy / en el mes / en el año
   - Meta vs real por fuente de ingreso
   - Pases de caja pendientes de cobro (cartera)
   - Alertas de pases próximos a vencer

4. REPORTES
   - Recaudación diaria por caja y por cajero
   - Recaudación por fuente de ingreso
   - Reporte de deudores
   - Exportar al sistema de contabilidad (póliza diaria)
   - Estadísticas de eficiencia (tiempo promedio de trámite, etc.)
```

### DDL para configuración del Administrador

```sql
-- Configuración global del sistema (parámetros modificables por el admin)
core.parametro_sistema
  id_parametro          INT IDENTITY PK
  clave                 VARCHAR(100) UNIQUE NOT NULL
  valor                 NVARCHAR(MAX) NOT NULL
  tipo_dato             VARCHAR(20)     -- STRING / INT / DECIMAL / BOOL / JSON / DATE
  descripcion           VARCHAR(500)
  modulo                VARCHAR(50)     -- módulo al que aplica
  es_sensible           BIT DEFAULT 0  -- si es sensible, no se muestra en UI
  modificable_en_ui     BIT DEFAULT 1
  [+ campos auditoría estándar]

-- Parámetros iniciales requeridos (seed):
-- DIAS_VIGENCIA_PASE_CAJA = 5
-- DIAS_VIGENCIA_CRI = 30
-- EJERCICIO_FISCAL_ACTIVO = 2026
-- EMAIL_TESORERO = ''
-- NOMBRE_MUNICIPIO = 'Tulum'
-- NOMBRE_ESTADO = 'Quintana Roo'
-- LOGO_MUNICIPIO_URL = ''
-- RFC_MUNICIPIO = ''
-- PERMITE_PAGO_PARCIAL = false
-- DIAS_AVISO_VENCIMIENTO_LICENCIA = 30
```

---

# ═══════════════════════════════════════════════════════
# FASE 8 — MÓDULO LICENCIAS DE FUNCIONAMIENTO
# (ahora conectado a toda la infraestructura anterior)
# ═══════════════════════════════════════════════════════

## [IMPLEMENTAR F8-A] DDL — Schema LICENCIAS (versión integrada)

Referirse al prompt anterior de Licencias, pero ahora **integrando**:
- `id_contribuyente` → FK a `core.contribuyente`
- `id_predio` → FK a `predial.predio`
- Los pases de caja se generan en `caja.pase_caja`
- Los folios usan `caja.serie_folio`
- Las tarifas referencian `catalogos.tarifa_fuente_ingreso`
- El CRI se verifica antes de emitir la licencia via `core.cri`

---

# ═══════════════════════════════════════════════════════
# FASE 9 — AUDITORÍA CENTRALIZADA
# ═══════════════════════════════════════════════════════

## [IMPLEMENTAR F9-A] DDL — Schema AUDITORIA

```sql
-- Log centralizado de TODAS las operaciones del sistema
auditoria.log_operacion
  id_log                BIGINT IDENTITY PK
  -- Quién
  id_usuario            INT FK -> core.usuario NULL
  username              VARCHAR(50)
  ip_origen             VARCHAR(45)
  user_agent            VARCHAR(500)
  -- Qué
  modulo                VARCHAR(50) NOT NULL     -- CORE / CAJA / PREDIAL / LICENCIAS
  entidad               VARCHAR(100) NOT NULL    -- nombre de la tabla/entidad afectada
  id_entidad            VARCHAR(50)             -- ID del registro afectado
  operacion             VARCHAR(20) NOT NULL     -- INSERT / UPDATE / DELETE
                                                 -- LOGIN / LOGOUT / CONSULTA
                                                 -- PAGO / EMISION / CANCELACION
  -- Detalle del cambio
  datos_anteriores      NVARCHAR(MAX)            -- JSON del estado previo
  datos_nuevos          NVARCHAR(MAX)            -- JSON del estado nuevo
  campos_modificados    NVARCHAR(MAX)            -- JSON array de campos modificados
  -- Contexto
  descripcion           VARCHAR(500)             -- descripción legible del evento
  resultado             VARCHAR(20) DEFAULT 'OK' -- OK / ERROR / RECHAZADO
  mensaje_error         VARCHAR(1000)
  -- Cuándo
  fecha_operacion       DATETIME2 DEFAULT GETDATE()
  duracion_ms           INT                      -- milisegundos que tardó la operación

-- Índices para búsqueda de auditoría
CREATE INDEX IX_log_usuario ON auditoria.log_operacion (id_usuario, fecha_operacion DESC)
CREATE INDEX IX_log_modulo_entidad ON auditoria.log_operacion (modulo, entidad, id_entidad)
CREATE INDEX IX_log_fecha ON auditoria.log_operacion (fecha_operacion DESC)
```

### Middleware de auditoría (Python)

```python
# Implementar como middleware de FastAPI que:
# 1. Intercepta TODAS las requests
# 2. Registra en auditoria.log_operacion automáticamente
# 3. No impacta el tiempo de respuesta (inserción async en background)
# 4. Para operaciones de escritura: captura datos_anteriores y datos_nuevos

class AuditoriaMiddleware:
    """
    Aplicar como middleware global en FastAPI.
    Excluir: GET de catálogos, health check, docs.
    Incluir obligatoriamente: todos los POST/PUT/DELETE y
    operaciones sensibles como login, cobros, emisión de documentos.
    """
    pass
```

---

# ═══════════════════════════════════════════════════════
# FASE 10 — FRONTEND REACT
# ═══════════════════════════════════════════════════════

## [IMPLEMENTAR F10-A] Estructura del frontend

```
src/
├── assets/                  # logos, íconos del ayuntamiento
├── components/
│   ├── common/              # Button, Input, Modal, Table, Badge, Alert...
│   │   ├── DataTable/       # tabla con paginación, filtros, exportar
│   │   ├── FormBuilder/     # formularios dinámicos
│   │   └── StatusBadge/     # badge de estados con colores
│   └── layout/
│       ├── Sidebar.tsx      # menú lateral con permisos dinámicos
│       ├── Header.tsx       # barra superior con usuario activo
│       └── ProtectedRoute.tsx
│
├── features/                # módulos de negocio
│   ├── auth/                # login, cambio de password
│   ├── usuarios/            # CRUD de usuarios y roles
│   ├── contribuyentes/      # padrón de contribuyentes
│   ├── catalogos/           # UMA, INPC, recargos, fuentes de ingreso
│   ├── catastro/            # consulta y gestión de predios
│   ├── cri/                 # generación y verificación de CRI
│   ├── caja/                # apertura/cierre caja, pases, cobros
│   ├── licencias/           # módulo de licencias de funcionamiento
│   └── admin-ingresos/      # dashboard del administrador
│
├── hooks/                   # custom hooks
│   ├── useAuth.ts
│   ├── usePermisos.ts
│   └── usePaseCaja.ts
│
├── services/                # clientes Axios para cada microservicio
│   ├── api.ts               # instancia base con interceptors JWT
│   ├── authService.ts
│   ├── contribuyentesService.ts
│   ├── cajaService.ts
│   └── licenciasService.ts
│
├── store/                   # Zustand
│   ├── authStore.ts         # usuario autenticado, token, permisos
│   └── cajaStore.ts         # caja activa, sesión actual
│
└── types/                   # TypeScript interfaces para todos los modelos
    ├── contribuyente.ts
    ├── paseCaja.ts
    ├── licencia.ts
    └── ...
```

### Pantallas mínimas del frontend (IMPLEMENTAR)

```
1. LOGIN
   - Formulario de usuario/contraseña
   - Validaciones de intentos fallidos
   - Pantalla de cambio de contraseña obligatorio (primer login)

2. DASHBOARD PRINCIPAL
   - Métricas del día: recaudado hoy / pases pendientes / licencias por vencer
   - Acceso rápido a módulos según permisos del usuario

3. MÓDULO USUARIOS (Admin)
   - Tabla de usuarios con búsqueda y filtros
   - Modal de crear/editar usuario
   - Asignación de roles con checkboxes
   - Toggle de bloqueo/desbloqueo

4. MÓDULO CONTRIBUYENTES
   - Búsqueda por nombre, RFC, número de contribuyente
   - Ficha completa del contribuyente
   - Pestaña de trámites históricos
   - Pestaña de estado de cuenta consolidado
   - Botón "Generar CRI"

5. MÓDULO CATÁLOGOS (Admin de Ingresos)
   - Tabla de UMA por ejercicio + formulario de registro
   - Tabla de INPC mensual + carga masiva CSV
   - Tasas de recargos por ejercicio
   - Fuentes de ingreso y sus tarifas

6. MÓDULO CATASTRO
   - Búsqueda de predios por clave catastral, propietario, dirección
   - Ficha del predio con mapa (Leaflet/Google Maps)
   - Historial de propietarios

7. CRI (Constancia de Registro de Ingresos)
   - Formulario de solicitud con selección de módulos
   - Vista previa del CRI antes de emitir
   - Botón de descarga PDF
   - Pantalla pública de verificación (sin login): /verificar/{folio}

8. MÓDULO CAJA
   - Pantalla de apertura de caja (saldo inicial)
   - Lista de pases de caja pendientes de cobro
   - Modal de cobro: forma de pago + referencia + confirmación
   - Pantalla de cierre de caja con conteo físico
   - Impresión de corte

9. MÓDULO LICENCIAS
   - Wizard de solicitud (paso a paso):
     Paso 1: Buscar contribuyente o registrar nuevo
     Paso 2: Seleccionar predio
     Paso 3: Seleccionar giro + tipo de licencia
     Paso 4: Verificación automática de requisitos (con spinner por módulo)
     Paso 5: Resumen de montos y generación de pase de caja
   - Bandeja de trámites en proceso (para revisores)
   - Consulta de licencias activas

10. DASHBOARD ADMIN DE INGRESOS
    - Gráfica de recaudación diaria (últimos 30 días)
    - Tabla de recaudación por fuente de ingreso
    - Alertas: pases próximos a vencer, cajas abiertas, licencias por vencer
    - Exportar reporte Excel del día
```

### Componente clave: VerificadorRequisitos (React)

```tsx
// Para el wizard de Licencias - muestra el estado en tiempo real
// de cada requisito consultando los microservicios

interface RequisitoStatus {
  tipo: string
  label: string
  estado: 'cargando' | 'ok' | 'pendiente' | 'bloqueante'
  mensaje: string
  folio_referencia?: string
  accion_url?: string    // link al módulo para regularizar
}

const VerificadorRequisitos: React.FC<{
  idContribuyente: number
  idPredio: number
  idGiro: number
}> = ({ idContribuyente, idPredio, idGiro }) => {
  // Muestra cada requisito como una fila con:
  // - ícono de estado (spinner / check verde / X roja / advertencia amarilla)
  // - nombre del requisito
  // - mensaje descriptivo
  // - si está pendiente: botón "¿Cómo regularizar?"
  // Al final: botón "Continuar" habilitado solo si puede_emitirse = true
}
```

---

# ═══════════════════════════════════════════════════════
# RESUMEN: ORDEN DE IMPLEMENTACIÓN RECOMENDADO
# ═══════════════════════════════════════════════════════

```
SPRINT 1 (Infraestructura base):
  ├── F0: Schemas SQL Server + convenciones
  ├── F1: Usuarios, roles, permisos + autenticación JWT
  └── Login en React + sidebar con permisos dinámicos

SPRINT 2 (Padrón y catálogos):
  ├── F2: Padrón de contribuyentes
  ├── F3: UMA, INPC, recargos, fuentes de ingreso
  └── Pantallas de contribuyentes y catálogos en React

SPRINT 3 (Catastro y CRI):
  ├── F4: Catastro (predios)
  ├── F5: CRI con generación de PDF y QR
  └── Pantallas de catastro y CRI en React

SPRINT 4 (Caja y cobros):
  ├── F6: Cajas, series, pases de caja
  ├── F7: Dashboard del Administrador de Ingresos
  └── Módulo de caja completo en React

SPRINT 5 (Primer módulo de trámites):
  ├── F8: Licencias de Funcionamiento (integrado al core)
  └── Wizard de licencias en React

SPRINT 6+ (Escalamiento):
  ├── Módulo Predial + ISABI
  ├── Módulo Tránsito + Multas
  ├── Módulo Registro Civil
  └── Módulo Saneamiento Ambiental / ZOFEMAT
```

---

# ═══════════════════════════════════════════════════════
# VARIABLES DE ENTORNO — SISTEMA COMPLETO
# ═══════════════════════════════════════════════════════

```env
# ─── SQL Server ──────────────────────────────────────
SQLSERVER_HOST=localhost
SQLSERVER_PORT=1433
SQLSERVER_DATABASE=siim_tulum
SQLSERVER_USER=sa
SQLSERVER_PASSWORD=

# ─── JWT ─────────────────────────────────────────────
JWT_SECRET_KEY=
JWT_ALGORITHM=HS256
JWT_EXPIRE_MINUTES=480
JWT_REFRESH_EXPIRE_DAYS=1

# ─── Redis ───────────────────────────────────────────
REDIS_URL=redis://localhost:6379/0

# ─── Almacenamiento de archivos ───────────────────────
STORAGE_PATH=./storage
STORAGE_URL=http://localhost:8000/storage

# ─── Email ───────────────────────────────────────────
SMTP_HOST=
SMTP_PORT=587
SMTP_USER=
SMTP_PASSWORD=
EMAIL_FROM=noreply@tulum.gob.mx

# ─── URLs microservicios (si se separan) ─────────────
MS_CORE_URL=http://localhost:8001
MS_CAJA_URL=http://localhost:8002
MS_PREDIAL_URL=http://localhost:8003
MS_LICENCIAS_URL=http://localhost:8004

# ─── Frontend ────────────────────────────────────────
VITE_API_BASE_URL=http://localhost:8000/api/v1
VITE_APP_NOMBRE=SIIM Tulum
VITE_APP_VERSION=1.0.0

# ─── Parámetros municipales ───────────────────────────
MUNICIPIO_NOMBRE=Tulum
MUNICIPIO_ESTADO=Quintana Roo
MUNICIPIO_RFC=MTU8503...
UMA_2026_DIARIO=113.14
EJERCICIO_FISCAL_ACTIVO=2026
```

---

*Prompt Maestro v1.0 — Sistema Integral de Ingresos Municipales (SIIM)*
*H. Ayuntamiento del Municipio de Tulum, Quintana Roo*
*Marco Legal: Ley de Hacienda del Municipio de Tulum POE 10-12-2025 | Ley de Ingresos 2026 Decreto 162*
