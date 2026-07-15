# ╔══════════════════════════════════════════════════════════════════════╗
# ║   PROMPT MAESTRO UNIFICADO — SIIM                                   ║
# ║   Sistema Integral de Ingresos Municipales                          ║
# ║   H. Ayuntamiento del Municipio de Tulum, Quintana Roo              ║
# ║   Versión 2.0 — Base de datos nueva desde cero                      ║
# ╚══════════════════════════════════════════════════════════════════════╝

---

> **¿CÓMO USAR ESTE PROMPT?**
> Es la especificación técnica completa del sistema, organizada en FASES.
> Entrega una fase o módulo a la vez al modelo de IA o al equipo de desarrollo.
> Respeta el orden: cada fase depende de la anterior.
> Los bloques `[IMPLEMENTAR]` son los entregables esperados en cada paso.

---

# ══════════════════════════════════════════════════════
# 🔌 SECCIÓN 0 — CONEXIÓN A BASE DE DATOS
# COMPLETA ESTOS DATOS ANTES DE INICIAR CUALQUIER FASE
# ══════════════════════════════════════════════════════

```
┌─────────────────────────────────────────────────────┐
│         CONFIGURACIÓN DE BASE DE DATOS               │
│         (Base de datos NUEVA — creada desde cero)    │
├─────────────────────────────────────────────────────┤
│  HOST     : ________________________________         │
│  PUERTO   : ________________________________         │
│  NOMBRE BD: ________________________________         │
│  USUARIO  : ________________________________         │
│  CONTRASEÑA: _______________________________         │
└─────────────────────────────────────────────────────┘
```

Estos datos se usarán en TODO el sistema. La cadena de conexión Python será:

```python
# database.py — usar estos valores en TODO el proyecto
DB_HOST      = ""   # <-- RELLENAR
DB_PORT      = ""   # <-- RELLENAR  (SQL Server default: 1433)
DB_NAME      = ""   # <-- RELLENAR  (nombre de la BD nueva)
DB_USER      = ""   # <-- RELLENAR
DB_PASSWORD  = ""   # <-- RELLENAR

DATABASE_URL = (
    f"mssql+pyodbc://{DB_USER}:{DB_PASSWORD}"
    f"@{DB_HOST}:{DB_PORT}/{DB_NAME}"
    f"?driver=ODBC+Driver+18+for+SQL+Server"
    f"&TrustServerCertificate=yes"
)
```

Y en el archivo `.env` del proyecto:

```env
# ════════════════════════════════════════════════
# CONEXIÓN BASE DE DATOS — RELLENAR ANTES DE USAR
# ════════════════════════════════════════════════
DB_HOST=
DB_PORT=1433
DB_NAME=
DB_USER=
DB_PASSWORD=
```

> ⚠️ IMPORTANTE: La base de datos referenciada es NUEVA y VACÍA.
> El sistema creará todos los schemas, tablas, índices, secuencias,
> stored procedures y datos semilla desde cero mediante scripts DDL
> y migraciones Alembic. No se conecta a ninguna base de datos preexistente.

---

# ══════════════════════════════════════════════════════
# 🎯 VISIÓN GENERAL DEL SISTEMA
# ══════════════════════════════════════════════════════

Eres un arquitecto de software senior especializado en sistemas gubernamentales
de recaudación municipal. Debes construir el **Sistema Integral de Ingresos
Municipales (SIIM)** para el H. Ayuntamiento de Tulum, Quintana Roo,
desde cero, sobre una base de datos nueva.

El sistema debe escalar a todos los módulos de recaudación municipal:
Predial, Licencias de Funcionamiento, Agua, Desarrollo Urbano,
Protección Civil, Saneamiento Ambiental, ZOFEMAT, Tránsito, Registro Civil,
Multas e ISABI, apegado al marco legal vigente en 2026.

### Marco Legal Aplicable (vigente 2026)
- Ley de Hacienda del Municipio de Tulum — Última reforma POE 10-12-2025
- Ley de Ingresos del Municipio de Tulum — Decreto 162, POE 10-12-2025
- Código Fiscal Municipal del Estado de Quintana Roo
- Ley de Hacienda del Estado de Quintana Roo
- Tarifas expresadas en **UMA** — valor diario 2026: **$113.14 MXN**

---

# ══════════════════════════════════════════════════════
# 🏗️ STACK TECNOLÓGICO — INAMOVIBLE
# ══════════════════════════════════════════════════════

```
Backend API:      Python 3.11+  |  FastAPI 0.110+
ORM:              SQLAlchemy 2.x (async, Core + ORM)
Base de datos:    Microsoft SQL Server 2019/2022  ← BD NUEVA
Migraciones:      Alembic
Validación:       Pydantic v2
Autenticación:    JWT (python-jose) + OAuth2PasswordBearer
Permisos:         RBAC (Role-Based Access Control) propio
Task Queue:       Celery + Redis
Frontend:         React 18 + TypeScript  (plantilla existente del usuario)
HTTP Client FE:   Axios + React Query (TanStack Query v5)
Estado global FE: Zustand
PDF:              WeasyPrint (HTML → PDF)
Logging:          Loguru
Testing:          pytest + pytest-asyncio + httpx
Contenedores:     Docker + docker-compose
```

---

# ══════════════════════════════════════════════════════
# 📐 ARQUITECTURA GENERAL
# ══════════════════════════════════════════════════════

```
┌──────────────────────────────────────────────────────────────┐
│                    FRONTEND (React + TS)                      │
│   Módulo Admin │ Módulo Cajas │ Módulos de Trámites           │
└──────────────────────────┬───────────────────────────────────┘
                           │ HTTP/REST (OpenAPI)
┌──────────────────────────▼───────────────────────────────────┐
│              API GATEWAY / ROUTER                             │
│           (FastAPI principal — puerto 8000)                   │
└──┬──────────┬───────────┬────────────┬───────────┬───────────┘
   │          │           │            │           │
   ▼          ▼           ▼            ▼           ▼
ms_core   ms_caja   ms_predial  ms_licencias   ms_*
(usuarios (cajas,   (catastro,  (licencias,   (futuros
 contrib. pases,    predial,    giros,        módulos)
 catálog. folios)   ISABI)      PC, DU, DSA)
   │          │           │            │           │
   └──────────┴───────────┴────────────┴───────────┘
                           │
              ┌────────────▼─────────────┐
              │   SQL Server — BD NUEVA   │
              │  Schemas:                 │
              │  core / caja / catalogos  │
              │  predial / licencias /    │
              │  auditoria               │
              └───────────────────────────┘
```

---

# ══════════════════════════════════════════════════════
# FASE 0 — FUNDAMENTOS: SCHEMAS Y CONVENCIONES
# ══════════════════════════════════════════════════════

## [IMPLEMENTAR F0] Script de inicialización de la BD nueva

```sql
-- ═══════════════════════════════════════════════════
-- PASO 1: CREAR SCHEMAS (ejecutar en la BD nueva)
-- ═══════════════════════════════════════════════════
CREATE SCHEMA core;        -- usuarios, roles, contribuyentes, catálogos globales
CREATE SCHEMA caja;        -- cajas, cajeros, pases, folios, series, cortes
CREATE SCHEMA catalogos;   -- UMA, INPC, recargos, fuentes de ingreso
CREATE SCHEMA predial;     -- catastro, predios, avalúos
CREATE SCHEMA licencias;   -- licencias de funcionamiento, giros, tarifas
CREATE SCHEMA auditoria;   -- logs centralizados de todos los módulos
GO

-- ═══════════════════════════════════════════════════
-- PASO 2: TIPOS Y CONVENCIONES ESTÁNDAR
-- (aplicar en TODAS las tablas del sistema)
-- ═══════════════════════════════════════════════════

-- PK:            BIGINT IDENTITY(1,1) para transaccionales
--                INT IDENTITY(1,1) para catálogos
-- Fechas:        DATE para solo fecha | DATETIME2(0) para fecha+hora
-- Importes:      DECIMAL(14,4) internos | DECIMAL(12,2) presentación
-- RFC:           VARCHAR(15) + CHECK LIKE '[A-Z][A-Z][A-Z][A-Z][0-9]...'
-- Flags:         BIT DEFAULT 0
-- Soft delete:   BIT activo DEFAULT 1  — en TODAS las tablas
-- Auditoría:     fecha_creacion    DATETIME2 DEFAULT GETDATE()
--                fecha_modificacion DATETIME2
--                id_usuario_creacion INT
--                id_usuario_modificacion INT

-- ═══════════════════════════════════════════════════
-- PASO 3: SECUENCIAS PARA FOLIOS (garantizan unicidad en concurrencia)
-- ═══════════════════════════════════════════════════
CREATE SEQUENCE caja.seq_pase_caja     START WITH 1 INCREMENT BY 1 NO CYCLE;
CREATE SEQUENCE caja.seq_folio_recibo  START WITH 1 INCREMENT BY 1 NO CYCLE;
CREATE SEQUENCE core.seq_contribuyente START WITH 1 INCREMENT BY 1 NO CYCLE;
CREATE SEQUENCE core.seq_cri           START WITH 1 INCREMENT BY 1 NO CYCLE;
CREATE SEQUENCE licencias.seq_licencia START WITH 1 INCREMENT BY 1 NO CYCLE;
GO

-- ═══════════════════════════════════════════════════
-- PASO 4: TRIGGER ESTÁNDAR DE AUDITORÍA (template)
-- Aplicar este patrón a todas las tablas con fecha_modificacion
-- ═══════════════════════════════════════════════════
-- [IMPLEMENTAR como template reutilizable]
-- CREATE TRIGGER trg_[schema]_[tabla]_auditoria
-- ON [schema].[tabla] AFTER UPDATE AS ...
```

---

# ══════════════════════════════════════════════════════
# FASE 1 — USUARIOS, ROLES Y SEGURIDAD (Schema: core)
# ══════════════════════════════════════════════════════

## [IMPLEMENTAR F1-A] DDL — Usuarios y RBAC

```sql
-- ─── DEPENDENCIAS Y ÁREAS ────────────────────────────────────────────────
core.cat_dependencia
  id_dependencia        INT IDENTITY PK
  clave                 VARCHAR(20) UNIQUE NOT NULL     -- TES, CAT, PC, DU, RC
  nombre                VARCHAR(200) NOT NULL
  nombre_corto          VARCHAR(50)
  responsable           VARCHAR(200)
  activo                BIT DEFAULT 1
  [+ auditoría estándar]

core.cat_area
  id_area               INT IDENTITY PK
  id_dependencia        INT FK -> cat_dependencia
  clave                 VARCHAR(20) NOT NULL
  nombre                VARCHAR(200) NOT NULL
  activo                BIT DEFAULT 1
  [+ auditoría estándar]

-- ─── USUARIOS ────────────────────────────────────────────────────────────
core.usuario
  id_usuario            INT IDENTITY PK
  id_area               INT FK -> cat_area
  username              VARCHAR(50) UNIQUE NOT NULL
  email                 VARCHAR(200) UNIQUE NOT NULL
  password_hash         VARCHAR(255) NOT NULL           -- bcrypt
  nombre                VARCHAR(100) NOT NULL
  apellido_paterno      VARCHAR(100) NOT NULL
  apellido_materno      VARCHAR(100)
  nombre_completo       AS (TRIM(nombre+' '+apellido_paterno+' '+ISNULL(apellido_materno,''))) PERSISTED
  telefono              VARCHAR(20)
  curp                  VARCHAR(20)
  rfc_usuario           VARCHAR(15)
  foto_url              VARCHAR(500)
  ultimo_login          DATETIME2
  intentos_fallidos     TINYINT DEFAULT 0
  bloqueado             BIT DEFAULT 0
  fecha_bloqueo         DATETIME2
  motivo_bloqueo        VARCHAR(300)
  fecha_alta            DATE NOT NULL DEFAULT CAST(GETDATE() AS DATE)
  fecha_baja            DATE
  activo                BIT DEFAULT 1
  debe_cambiar_password BIT DEFAULT 1
  fecha_ultimo_password DATETIME2
  [+ auditoría estándar]

-- ─── RBAC ─────────────────────────────────────────────────────────────────
core.cat_modulo
  id_modulo             INT IDENTITY PK
  clave                 VARCHAR(50) UNIQUE NOT NULL    -- CORE/CAJA/PREDIAL/LICENCIAS
  nombre                VARCHAR(200) NOT NULL
  descripcion           VARCHAR(500)
  icono                 VARCHAR(100)
  ruta_base             VARCHAR(200)
  orden_menu            INT DEFAULT 0
  activo                BIT DEFAULT 1

core.cat_permiso
  id_permiso            INT IDENTITY PK
  id_modulo             INT FK -> cat_modulo
  clave                 VARCHAR(100) UNIQUE NOT NULL   -- PREDIAL:CONSULTAR / CAJA:COBRAR
  nombre                VARCHAR(200) NOT NULL
  descripcion           VARCHAR(500)
  activo                BIT DEFAULT 1

core.cat_rol
  id_rol                INT IDENTITY PK
  clave                 VARCHAR(50) UNIQUE NOT NULL
  nombre                VARCHAR(200) NOT NULL
  descripcion           VARCHAR(500)
  es_rol_sistema        BIT DEFAULT 0                 -- no se puede eliminar
  activo                BIT DEFAULT 1
  [+ auditoría estándar]

core.rol_permiso
  id_rol_permiso        INT IDENTITY PK
  id_rol                INT FK -> cat_rol
  id_permiso            INT FK -> cat_permiso
  UNIQUE (id_rol, id_permiso)

core.usuario_rol
  id_usuario_rol        INT IDENTITY PK
  id_usuario            INT FK -> usuario
  id_rol                INT FK -> cat_rol
  fecha_asignacion      DATE NOT NULL DEFAULT CAST(GETDATE() AS DATE)
  fecha_expiracion      DATE
  id_usuario_asigna     INT FK -> usuario
  activo                BIT DEFAULT 1
  UNIQUE (id_usuario, id_rol)

core.sesion_usuario
  id_sesion             BIGINT IDENTITY PK
  id_usuario            INT FK -> usuario
  token_jti             VARCHAR(100) UNIQUE NOT NULL  -- JWT ID único
  ip_origen             VARCHAR(45)
  user_agent            VARCHAR(500)
  fecha_inicio          DATETIME2 DEFAULT GETDATE()
  fecha_expiracion      DATETIME2 NOT NULL
  revocado              BIT DEFAULT 0
  fecha_revocacion      DATETIME2

core.log_acceso
  id_log                BIGINT IDENTITY PK
  id_usuario            INT NULL FK -> usuario
  username_intento      VARCHAR(50)
  tipo_evento           VARCHAR(30)   -- LOGIN_OK/LOGIN_FAIL/LOGOUT/BLOQUEO/CAMBIO_PASSWORD
  ip_origen             VARCHAR(45)
  user_agent            VARCHAR(500)
  detalle               VARCHAR(500)
  fecha_evento          DATETIME2 DEFAULT GETDATE()
```

### Seed obligatorio de roles del sistema

```sql
-- Roles predefinidos (es_rol_sistema = 1, no eliminables)
SUPER_ADMIN       → acceso total, solo IT
ADMIN_INGRESOS    → administra cajas, tarifas, reportes
JEFE_CAJA         → supervisa cajeros, hace cortes
CAJERO            → cobra trámites, ve sus propios movimientos
CAPTURISTA        → captura trámites, genera pase de caja (no cobra)
REVISOR           → aprueba/rechaza trámites (no cobra)
CONSULTA          → solo lectura en módulos asignados
AUDITOR           → acceso solo-lectura a logs y auditoría
```

## [IMPLEMENTAR F1-B] API — Autenticación y Usuarios

```
POST  /api/v1/auth/login
POST  /api/v1/auth/refresh
POST  /api/v1/auth/logout
POST  /api/v1/auth/cambiar-password
GET   /api/v1/auth/me

GET   /api/v1/usuarios
POST  /api/v1/usuarios
GET   /api/v1/usuarios/{id}
PUT   /api/v1/usuarios/{id}
DELETE /api/v1/usuarios/{id}
POST  /api/v1/usuarios/{id}/bloquear
POST  /api/v1/usuarios/{id}/desbloquear
POST  /api/v1/usuarios/{id}/resetear-password
GET   /api/v1/usuarios/{id}/permisos      -- permisos efectivos (union de todos sus roles)

GET   /api/v1/roles
POST  /api/v1/roles
PUT   /api/v1/roles/{id}
GET   /api/v1/roles/{id}/permisos
PUT   /api/v1/roles/{id}/permisos
GET   /api/v1/modulos
GET   /api/v1/permisos
```

### Dependency de permisos (FastAPI)

```python
# Uso en cualquier endpoint: Depends(require_permission("PREDIAL:CONSULTAR"))
async def require_permission(permiso_clave: str):
    async def verificar(
        current_user = Depends(get_current_user),
        db = Depends(get_db)
    ):
        # 1. Obtener roles activos del usuario
        # 2. Unir todos los permisos de esos roles
        # 3. Verificar si permiso_clave está en el conjunto
        # 4. Si no → HTTP 403 con mensaje claro
        pass
    return verificar
```

---

# ══════════════════════════════════════════════════════
# FASE 2 — PADRÓN DE CONTRIBUYENTES (Schema: core)
# ══════════════════════════════════════════════════════

## [IMPLEMENTAR F2] DDL — Contribuyentes

```sql
-- ─── CATÁLOGOS DE SOPORTE ─────────────────────────────────────────────────
core.cat_tipo_persona
  id_tipo_persona  TINYINT PK    -- 1=Física / 2=Moral / 3=Unid.Económica / 4=Gobierno
  nombre           VARCHAR(50)

core.cat_tipo_identificacion
  id_tipo_id       TINYINT PK
  clave            VARCHAR(20)   -- INE / PASAPORTE / FM2 / FM3 / CURP / ESCRITURA
  nombre           VARCHAR(100)

core.cat_colonia                 -- catálogo SEPOMEX
  id_colonia       INT IDENTITY PK
  codigo_postal    VARCHAR(10) NOT NULL
  nombre_colonia   VARCHAR(200) NOT NULL
  tipo_asentamiento VARCHAR(80)
  municipio        VARCHAR(200)
  estado           VARCHAR(100)
  activo           BIT DEFAULT 1

-- ─── CONTRIBUYENTE ────────────────────────────────────────────────────────
core.contribuyente
  id_contribuyente       BIGINT IDENTITY PK
  numero_contribuyente   VARCHAR(20) UNIQUE NOT NULL  -- CONT-000001 (usa seq_contribuyente)
  id_tipo_persona        TINYINT FK -> cat_tipo_persona
  -- Persona física
  nombre                 VARCHAR(200)
  apellido_paterno       VARCHAR(200)
  apellido_materno       VARCHAR(200)
  fecha_nacimiento       DATE
  -- Persona moral
  razon_social           VARCHAR(500)
  nombre_comercial       VARCHAR(500)
  fecha_constitucion     DATE
  numero_escritura       VARCHAR(50)
  nombre_notario         VARCHAR(200)
  numero_notaria         VARCHAR(20)
  -- Campo calculado para búsqueda
  nombre_completo_calc   AS (
    CASE WHEN id_tipo_persona = 1
      THEN TRIM(ISNULL(nombre,'')+' '+ISNULL(apellido_paterno,'')+' '+ISNULL(apellido_materno,''))
      ELSE razon_social END
  ) PERSISTED
  rfc                    VARCHAR(15)
  curp                   VARCHAR(20)
  -- Contacto
  email                  VARCHAR(200)
  email_secundario       VARCHAR(200)
  telefono_1             VARCHAR(20)
  telefono_2             VARCHAR(20)
  whatsapp               VARCHAR(20)
  -- Domicilio fiscal
  calle_fiscal           VARCHAR(300)
  numero_exterior_fiscal VARCHAR(20)
  numero_interior_fiscal VARCHAR(20)
  id_colonia_fiscal      INT FK -> cat_colonia
  codigo_postal_fiscal   VARCHAR(10)
  referencia_fiscal      VARCHAR(300)
  -- Representante legal
  representante_legal    VARCHAR(300)
  cargo_representante    VARCHAR(100)
  -- Identificación
  id_tipo_id             TINYINT FK -> cat_tipo_identificacion
  numero_identificacion  VARCHAR(100)
  vigencia_identificacion DATE
  -- Estado
  activo                 BIT DEFAULT 1
  fecha_alta             DATE DEFAULT CAST(GETDATE() AS DATE)
  fecha_baja             DATE
  motivo_baja            VARCHAR(300)
  observaciones          NVARCHAR(MAX)
  [+ auditoría estándar]

core.contribuyente_documento
  id_documento           BIGINT IDENTITY PK
  id_contribuyente       BIGINT FK -> contribuyente
  tipo_documento         VARCHAR(50)  -- IDENTIFICACION/ACTA_CONSTITUTIVA/RFC/PODER/DOMICILIO
  nombre_archivo         VARCHAR(300)
  ruta_almacenamiento    VARCHAR(500)
  tamanio_bytes          BIGINT
  mime_type              VARCHAR(100)
  fecha_subida           DATETIME2 DEFAULT GETDATE()
  subido_por             INT FK -> core.usuario
  activo                 BIT DEFAULT 1

core.contribuyente_historial
  id_historial           BIGINT IDENTITY PK
  id_contribuyente       BIGINT FK -> contribuyente
  campo_modificado       VARCHAR(100)
  valor_anterior         NVARCHAR(MAX)
  valor_nuevo            NVARCHAR(MAX)
  fecha_modificacion     DATETIME2 DEFAULT GETDATE()
  id_usuario             INT FK -> core.usuario
  motivo                 VARCHAR(500)
```

### Endpoints del padrón

```
GET    /api/v1/contribuyentes?q=&rfc=&tipo=&pagina=&limite=
POST   /api/v1/contribuyentes
GET    /api/v1/contribuyentes/{id}
PUT    /api/v1/contribuyentes/{id}
DELETE /api/v1/contribuyentes/{id}
GET    /api/v1/contribuyentes/buscar-rfc/{rfc}
GET    /api/v1/contribuyentes/{id}/tramites
GET    /api/v1/contribuyentes/{id}/documentos
POST   /api/v1/contribuyentes/{id}/documentos
GET    /api/v1/contribuyentes/{id}/historial
GET    /api/v1/contribuyentes/{id}/estado-cuenta   -- deuda total de todos los módulos
```

---

# ══════════════════════════════════════════════════════
# FASE 3 — CATÁLOGOS FISCALES Y FINANCIEROS (Schema: catalogos)
# ══════════════════════════════════════════════════════

## [IMPLEMENTAR F3] DDL — UMA, INPC, Recargos, Fuentes de Ingreso

```sql
-- ─── UMA ──────────────────────────────────────────────────────────────────
catalogos.uma_anual
  id_uma              INT IDENTITY PK
  ejercicio_fiscal    INT UNIQUE NOT NULL
  valor_diario        DECIMAL(12,4) NOT NULL   -- 113.14 para 2026
  valor_mensual       DECIMAL(12,4) NOT NULL   -- valor_diario * 30.4
  valor_anual         DECIMAL(12,4) NOT NULL   -- valor_diario * 365
  fecha_publicacion_dof DATE NOT NULL
  vigente_desde       DATE NOT NULL
  vigente_hasta       DATE
  numero_dof          VARCHAR(50)
  activo              BIT DEFAULT 1
  [+ auditoría estándar]

-- ─── INPC ─────────────────────────────────────────────────────────────────
-- Para calcular actualización de contribuciones vencidas
catalogos.inpc_mensual
  id_inpc             BIGINT IDENTITY PK
  anio                INT NOT NULL
  mes                 TINYINT NOT NULL           -- 1=Enero ... 12=Diciembre
  valor_inpc          DECIMAL(12,6) NOT NULL
  fecha_publicacion   DATE
  fuente              VARCHAR(100) DEFAULT 'INEGI'
  UNIQUE (anio, mes)

-- Función de actualización: INPC_mes_anterior_pago / INPC_mes_anterior_causacion
CREATE FUNCTION catalogos.fn_factor_actualizacion(
  @fecha_causacion DATE,
  @fecha_pago      DATE
) RETURNS DECIMAL(12,6)
-- [IMPLEMENTAR]

-- ─── TASAS DE RECARGOS ────────────────────────────────────────────────────
catalogos.tasa_recargo
  id_recargo          INT IDENTITY PK
  ejercicio_fiscal    INT NOT NULL
  tasa_mensual        DECIMAL(8,6) NOT NULL      -- ej: 0.0125 = 1.25%
  tasa_diaria         AS (tasa_mensual / 30.0) PERSISTED
  fundamento_legal    VARCHAR(300)
  vigente_desde       DATE NOT NULL
  vigente_hasta       DATE
  activo              BIT DEFAULT 1
  [+ auditoría estándar]

-- ─── MULTAS FISCALES ──────────────────────────────────────────────────────
catalogos.cat_multa_fiscal
  id_multa            INT IDENTITY PK
  clave               VARCHAR(30) UNIQUE NOT NULL
  descripcion         VARCHAR(500) NOT NULL
  tipo_calculo        VARCHAR(20) NOT NULL  -- FIJA / PORCENTAJE_OMITIDO / RANGO_UMA
  valor_minimo        DECIMAL(10,4)
  valor_maximo        DECIMAL(10,4)
  fundamento_legal    VARCHAR(300)
  activo              BIT DEFAULT 1

-- ─── EJERCICIOS FISCALES ──────────────────────────────────────────────────
catalogos.ejercicio_fiscal
  id_ejercicio        INT IDENTITY PK
  anio                INT UNIQUE NOT NULL
  fecha_inicio        DATE NOT NULL
  fecha_fin           DATE NOT NULL
  estado              VARCHAR(20) DEFAULT 'ACTIVO'  -- FUTURO/ACTIVO/CERRADO
  permite_modificaciones BIT DEFAULT 1
  fecha_cierre        DATETIME2
  id_usuario_cierre   INT FK -> core.usuario
  observaciones       VARCHAR(500)

-- ─── FUENTES DE INGRESO ───────────────────────────────────────────────────
-- Clasificación presupuestal de todos los conceptos de cobro
catalogos.fuente_ingreso
  id_fuente           INT IDENTITY PK
  clave               VARCHAR(30) UNIQUE NOT NULL
  clave_conac         VARCHAR(30)                -- clasificación CONAC
  tipo                VARCHAR(30) NOT NULL        -- IMPUESTO/DERECHO/PRODUCTO
                                                  -- APROVECHAMIENTO/PARTICIPACION
  subtipo             VARCHAR(50)
  nombre              VARCHAR(300) NOT NULL
  descripcion         VARCHAR(500)
  cuenta_contable     VARCHAR(50)
  modulo_origen       VARCHAR(50)               -- PREDIAL/LICENCIAS/CAJA/etc.
  afectable_descuento BIT DEFAULT 0
  afectable_recargo   BIT DEFAULT 1
  afectable_actualizacion BIT DEFAULT 1
  activo              BIT DEFAULT 1
  [+ auditoría estándar]

-- ─── TARIFAS DE FUENTES DE INGRESO ────────────────────────────────────────
catalogos.tarifa_fuente_ingreso
  id_tarifa           BIGINT IDENTITY PK
  id_fuente           INT FK -> fuente_ingreso
  id_ejercicio        INT FK -> ejercicio_fiscal
  tipo_tarifa         VARCHAR(30) NOT NULL       -- FIJA_MXN/UMA_DIARIA/PORCENTAJE/TABLA
  valor_base          DECIMAL(14,4)              -- monto fijo MXN o número de UMAs
  porcentaje          DECIMAL(8,6)
  monto_mxn_calculado DECIMAL(12,2)             -- cache calculado al inicio del ejercicio
  valor_uma_aplicado  DECIMAL(12,4)
  pct_descuento_enero DECIMAL(5,2) DEFAULT 0
  pct_descuento_febrero DECIMAL(5,2) DEFAULT 0
  vigente_desde       DATE NOT NULL
  vigente_hasta       DATE
  fundamento_legal    VARCHAR(500)
  activo              BIT DEFAULT 1
  [+ auditoría estándar]

-- ─── PARÁMETROS DEL SISTEMA ───────────────────────────────────────────────
core.parametro_sistema
  id_parametro        INT IDENTITY PK
  clave               VARCHAR(100) UNIQUE NOT NULL
  valor               NVARCHAR(MAX) NOT NULL
  tipo_dato           VARCHAR(20)   -- STRING/INT/DECIMAL/BOOL/JSON/DATE
  descripcion         VARCHAR(500)
  modulo              VARCHAR(50)
  es_sensible         BIT DEFAULT 0
  modificable_en_ui   BIT DEFAULT 1
  [+ auditoría estándar]

-- Seed obligatorio de parámetros:
-- DIAS_VIGENCIA_PASE_CAJA          = 5
-- DIAS_VIGENCIA_CRI                = 30
-- EJERCICIO_FISCAL_ACTIVO          = 2026
-- NOMBRE_MUNICIPIO                 = 'Tulum'
-- NOMBRE_ESTADO                    = 'Quintana Roo'
-- RFC_MUNICIPIO                    = ''
-- LOGO_MUNICIPIO_URL               = ''
-- PERMITE_PAGO_PARCIAL             = false
-- DIAS_AVISO_VENCIMIENTO_LICENCIA  = 30
-- UMA_VALOR_DIARIO_2026            = 113.14
```

---

# ══════════════════════════════════════════════════════
# FASE 4 — CATASTRO: PADRÓN DE PREDIOS (Schema: predial)
# ══════════════════════════════════════════════════════

## [IMPLEMENTAR F4] DDL — Catastro y Predios

```sql
-- ─── CATÁLOGOS CATASTRALES ────────────────────────────────────────────────
predial.cat_tipo_predio
  id_tipo_predio       TINYINT PK
  clave                VARCHAR(20)    -- URBANO_EDIFICADO/URBANO_BALDIO/RUSTICO/EJIDAL
  nombre               VARCHAR(100)
  tasa_predial         DECIMAL(10,8)  -- tasa aplicable
  activo               BIT DEFAULT 1

predial.cat_uso_suelo
  id_uso_suelo         INT IDENTITY PK
  clave                VARCHAR(20) UNIQUE NOT NULL
  nombre               VARCHAR(200) NOT NULL
  descripcion          VARCHAR(500)
  permite_comercio     BIT DEFAULT 0
  permite_habitacion   BIT DEFAULT 1
  activo               BIT DEFAULT 1

predial.cat_zona_catastral
  id_zona              INT IDENTITY PK
  clave                VARCHAR(20) UNIQUE NOT NULL   -- Z-01, ZC-AKUMAL
  nombre               VARCHAR(200) NOT NULL
  descripcion          VARCHAR(300)
  factor_zona          DECIMAL(8,4) DEFAULT 1.0000
  colinda_zofemat      BIT DEFAULT 0
  activo               BIT DEFAULT 1

-- ─── PREDIO ───────────────────────────────────────────────────────────────
predial.predio
  id_predio                  BIGINT IDENTITY PK
  clave_catastral            VARCHAR(30) UNIQUE NOT NULL
  cuenta_predial             VARCHAR(20) UNIQUE
  id_contribuyente           BIGINT FK -> core.contribuyente
  id_tipo_predio             TINYINT FK -> cat_tipo_predio
  id_uso_suelo               INT FK -> cat_uso_suelo
  id_zona_catastral          INT FK -> cat_zona_catastral
  -- Ubicación
  calle                      VARCHAR(300)
  numero_exterior            VARCHAR(20)
  numero_interior            VARCHAR(20)
  id_colonia                 INT FK -> core.cat_colonia
  codigo_postal              VARCHAR(10)
  referencia_ubicacion       VARCHAR(500)
  latitud                    DECIMAL(12,8)
  longitud                   DECIMAL(12,8)
  -- Medidas
  superficie_terreno_m2      DECIMAL(12,2)
  superficie_construida_m2   DECIMAL(12,2)
  numero_niveles             TINYINT DEFAULT 1
  -- Valores catastrales
  valor_catastral_suelo         DECIMAL(14,2)
  valor_catastral_construccion  DECIMAL(14,2)
  valor_catastral_total         AS (ISNULL(valor_catastral_suelo,0)+ISNULL(valor_catastral_construccion,0)) PERSISTED
  fecha_ultimo_avaluo           DATE
  vigencia_avaluo               DATE
  -- Colindancias especiales
  colinda_zofemat               BIT DEFAULT 0
  distancia_linea_costa         DECIMAL(8,2)     -- metros
  -- Régimen de propiedad
  regimen_propiedad             VARCHAR(30)      -- PLENA/CONDOMINIO/FIDEICOMISO/EJIDAL
  estado_predio                 VARCHAR(20) DEFAULT 'ACTIVO'
  fecha_alta                    DATE DEFAULT CAST(GETDATE() AS DATE)
  fecha_baja                    DATE
  activo                        BIT DEFAULT 1
  observaciones                 NVARCHAR(MAX)
  [+ auditoría estándar]

predial.predio_propietario_historial
  id_historial          BIGINT IDENTITY PK
  id_predio             BIGINT FK -> predio
  id_contribuyente      BIGINT FK -> core.contribuyente
  tipo_adquisicion      VARCHAR(50)  -- COMPRAVENTA/HERENCIA/DONACION/REMATE/PERMUTA
  fecha_adquisicion     DATE NOT NULL
  fecha_escritura       DATE
  folio_real_registral  VARCHAR(50)
  numero_escritura      VARCHAR(50)
  nombre_notario        VARCHAR(200)
  valor_adquisicion     DECIMAL(14,2)
  id_pago_isabi         BIGINT       -- FK al pago de ISABI correspondiente
  activo                BIT DEFAULT 1
  [+ auditoría estándar]
```

---

# ══════════════════════════════════════════════════════
# FASE 5 — CRI: CONSTANCIA DE REGISTRO DE INGRESOS (Schema: core)
# ══════════════════════════════════════════════════════

## [IMPLEMENTAR F5-A] DDL — CRI

El CRI es el "pasaporte fiscal municipal". Acredita que un contribuyente tiene
su situación fiscal regularizada ante el municipio. Es transversal a todos los
módulos y obligatorio para ciertos trámites.

```sql
core.cri
  id_cri                  BIGINT IDENTITY PK
  folio_cri               VARCHAR(30) UNIQUE NOT NULL  -- CRI-2026-000001
  id_contribuyente        BIGINT FK -> contribuyente
  -- Módulos evaluados
  incluye_predial         BIT DEFAULT 0
  incluye_licencias       BIT DEFAULT 0
  incluye_agua            BIT DEFAULT 0
  incluye_transito        BIT DEFAULT 0
  -- Estado por módulo al momento de emisión (snapshot)
  estado_predial          VARCHAR(20)   -- AL_CORRIENTE / CON_ADEUDO / NO_APLICA
  estado_licencias        VARCHAR(20)
  estado_agua             VARCHAR(20)
  estado_transito         VARCHAR(20)
  -- Montos de adeudo por módulo
  total_adeudo_predial    DECIMAL(12,2) DEFAULT 0
  total_adeudo_licencias  DECIMAL(12,2) DEFAULT 0
  total_adeudo_agua       DECIMAL(12,2) DEFAULT 0
  -- Estado general
  estado_cri              VARCHAR(20) NOT NULL         -- ACTIVO/VENCIDO/CANCELADO/UTILIZADO
  al_corriente            AS (
    CASE WHEN ISNULL(estado_predial,'NO_APLICA') IN ('AL_CORRIENTE','NO_APLICA')
          AND ISNULL(estado_licencias,'NO_APLICA') IN ('AL_CORRIENTE','NO_APLICA')
          AND ISNULL(estado_agua,'NO_APLICA') IN ('AL_CORRIENTE','NO_APLICA')
          AND ISNULL(estado_transito,'NO_APLICA') IN ('AL_CORRIENTE','NO_APLICA')
    THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END
  ) PERSISTED
  -- Vigencia (30 días calendario)
  fecha_emision           DATETIME2 DEFAULT GETDATE()
  vigente_hasta           DATETIME2 NOT NULL
  -- Uso del CRI
  motivo_solicitud        VARCHAR(300)
  usado_en_tramite        VARCHAR(100)
  fecha_uso               DATETIME2
  -- Trazabilidad
  id_usuario_emite        INT FK -> core.usuario
  ip_emision              VARCHAR(45)
  url_verificacion        VARCHAR(500)
  hash_verificacion       VARCHAR(64)   -- SHA-256 del contenido
  activo                  BIT DEFAULT 1
  [+ auditoría estándar]

core.cri_detalle_adeudo
  id_detalle              BIGINT IDENTITY PK
  id_cri                  BIGINT FK -> cri
  modulo                  VARCHAR(50)
  concepto                VARCHAR(300)
  ejercicio               INT
  monto_principal         DECIMAL(12,2)
  monto_actualizacion     DECIMAL(12,2) DEFAULT 0
  monto_recargos          DECIMAL(12,2) DEFAULT 0
  monto_multas            DECIMAL(12,2) DEFAULT 0
  total_adeudo            AS (monto_principal+monto_actualizacion+monto_recargos+monto_multas) PERSISTED
  folio_referencia        VARCHAR(50)
```

## [IMPLEMENTAR F5-B] Servicio Python — CRIService

```python
class CRIService:
    """
    Genera el CRI consultando en tiempo real todos los módulos activos.

    Proceso:
    1. Recibir id_contribuyente + lista de módulos a incluir
    2. Consultar EN PARALELO (asyncio.gather):
       - PredialService.obtener_estado_fiscal(id_contribuyente)
       - LicenciasService.obtener_estado_fiscal(id_contribuyente)
       - [futuros: Agua, Tránsito]
    3. Consolidar resultado y determinar al_corriente
    4. Generar folio con NEXT VALUE FOR core.seq_cri
    5. Calcular hash SHA-256 del contenido
    6. Generar QR con URL de verificación
    7. Guardar snapshot en BD
    8. Generar PDF oficial
    9. Retornar objeto CRI + PDF
    Vigencia: 30 días. Después de usarse en un trámite → estado UTILIZADO.
    """

    async def generar_cri(self, id_contribuyente, modulos, motivo, id_usuario): pass
    async def verificar_cri(self, folio_cri, hash_verificacion): pass
    # Endpoint público de verificación (sin autenticación):
    # GET /verificar/{folio_cri}
```

---

# ══════════════════════════════════════════════════════
# FASE 6 — MÓDULO DE CAJA (Schema: caja)
# ══════════════════════════════════════════════════════

## [IMPLEMENTAR F6] DDL — Cajas, Series, Pases de Caja, Cortes

```sql
-- ─── CAJAS FÍSICAS ───────────────────────────────────────────────────────
caja.caja
  id_caja                 INT IDENTITY PK
  clave                   VARCHAR(20) UNIQUE NOT NULL   -- CAJA-01, CAJA-02
  nombre                  VARCHAR(100) NOT NULL
  ubicacion               VARCHAR(200)
  id_area                 INT FK -> core.cat_area
  activa                  BIT DEFAULT 1
  permite_efectivo        BIT DEFAULT 1
  permite_tarjeta         BIT DEFAULT 1
  permite_transferencia   BIT DEFAULT 1
  permite_cheque          BIT DEFAULT 0
  estado                  VARCHAR(20) DEFAULT 'CERRADA'  -- ABIERTA/CERRADA/BLOQUEADA
  id_cajero_actual        INT FK -> core.usuario NULL
  fecha_apertura_actual   DATETIME2
  saldo_inicial_actual    DECIMAL(12,2)
  [+ auditoría estándar]

-- ─── SESIONES DE CAJA (cortes) ────────────────────────────────────────────
caja.sesion_caja
  id_sesion_caja          BIGINT IDENTITY PK
  id_caja                 INT FK -> caja
  id_cajero               INT FK -> core.usuario
  id_supervisor_apertura  INT FK -> core.usuario
  id_supervisor_cierre    INT FK -> core.usuario NULL
  fecha_apertura          DATETIME2 NOT NULL DEFAULT GETDATE()
  saldo_inicial           DECIMAL(12,2) NOT NULL DEFAULT 0
  fecha_cierre            DATETIME2
  saldo_final_sistema     DECIMAL(12,2)
  saldo_final_fisico      DECIMAL(12,2)
  diferencia              AS (ISNULL(saldo_final_fisico,0)-ISNULL(saldo_final_sistema,0)) PERSISTED
  total_efectivo          DECIMAL(12,2) DEFAULT 0
  total_tarjeta           DECIMAL(12,2) DEFAULT 0
  total_transferencia     DECIMAL(12,2) DEFAULT 0
  total_cheque            DECIMAL(12,2) DEFAULT 0
  total_recibido          AS (total_efectivo+total_tarjeta+total_transferencia+total_cheque) PERSISTED
  num_operaciones         INT DEFAULT 0
  num_pases_cobrados      INT DEFAULT 0
  estado                  VARCHAR(20) DEFAULT 'ABIERTA'  -- ABIERTA/CERRADA/CONCILIADA
  observaciones_cierre    VARCHAR(500)
  [+ auditoría estándar]

-- ─── SERIES DE FOLIOS ────────────────────────────────────────────────────
caja.serie_folio
  id_serie                INT IDENTITY PK
  clave_serie             VARCHAR(20) UNIQUE NOT NULL   -- A, B, REC-2026
  descripcion             VARCHAR(200)
  ejercicio_fiscal        INT NOT NULL
  id_caja                 INT FK -> caja NULL            -- NULL = serie global
  modulo                  VARCHAR(50)                   -- CAJA/PREDIAL/LICENCIAS
  tipo_documento          VARCHAR(50)                   -- RECIBO/PASE_CAJA/LICENCIA/CRI
  prefijo                 VARCHAR(10)                   -- REC, PC, LF, CRI
  sufijo                  VARCHAR(10)
  consecutivo_actual      INT DEFAULT 0
  consecutivo_inicial     INT DEFAULT 1
  consecutivo_final       INT
  longitud_folio          TINYINT DEFAULT 6
  -- Formato: {prefijo}-{ejercicio}-{000001}
  activo                  BIT DEFAULT 1
  [+ auditoría estándar]

-- Función atómica para generar siguiente folio
CREATE FUNCTION caja.fn_siguiente_folio(@id_serie INT) RETURNS VARCHAR(50)
-- [IMPLEMENTAR con UPDATE ... OUTPUT para garantizar atomicidad]

-- ─── PASES DE CAJA ───────────────────────────────────────────────────────
caja.pase_caja
  id_pase                 BIGINT IDENTITY PK
  folio_pase              VARCHAR(30) UNIQUE NOT NULL   -- PC-2026-000001
  id_serie                INT FK -> serie_folio
  -- Origen
  modulo                  VARCHAR(50) NOT NULL          -- PREDIAL/LICENCIAS/AGUA
  tipo_tramite            VARCHAR(100) NOT NULL         -- PAGO_PREDIAL/LICENCIA_NUEVA
  id_tramite              BIGINT NOT NULL
  folio_tramite           VARCHAR(50)
  -- Contribuyente
  id_contribuyente        BIGINT FK -> core.contribuyente
  nombre_contribuyente    VARCHAR(500)
  rfc_contribuyente       VARCHAR(15)
  -- Concepto
  id_fuente_ingreso       INT FK -> catalogos.fuente_ingreso
  concepto                VARCHAR(500) NOT NULL
  descripcion_desglose    NVARCHAR(MAX)                 -- JSON con líneas del desglose
  -- Importes
  monto_base              DECIMAL(12,2) NOT NULL
  monto_descuento         DECIMAL(12,2) DEFAULT 0
  monto_recargos          DECIMAL(12,2) DEFAULT 0
  monto_actualizacion     DECIMAL(12,2) DEFAULT 0
  monto_multas            DECIMAL(12,2) DEFAULT 0
  monto_total             AS (monto_base-monto_descuento+monto_recargos+monto_actualizacion+monto_multas) PERSISTED
  -- Estado
  estado                  VARCHAR(20) DEFAULT 'PENDIENTE'  -- PENDIENTE/PAGADO/CANCELADO/VENCIDO
  fecha_generacion        DATETIME2 DEFAULT GETDATE()
  fecha_vencimiento       DATE                          -- +5 días hábiles
  fecha_pago              DATETIME2
  -- Pago
  id_sesion_caja          BIGINT FK -> sesion_caja NULL
  id_cajero_cobro         INT FK -> core.usuario NULL
  id_caja_cobro           INT FK -> caja NULL
  forma_pago              VARCHAR(30)                   -- EFECTIVO/TARJETA/TRANSFERENCIA/CHEQUE
  referencia_pago         VARCHAR(100)
  -- Cancelación
  cancelado               BIT DEFAULT 0
  motivo_cancelacion      VARCHAR(300)
  id_usuario_cancela      INT FK -> core.usuario NULL
  fecha_cancelacion       DATETIME2
  -- Recibo
  folio_recibo            VARCHAR(30)
  recibo_pdf_url          VARCHAR(500)
  -- Generado por
  id_usuario_genera       INT FK -> core.usuario NOT NULL
  ip_origen               VARCHAR(45)
  [+ auditoría estándar]

caja.pase_caja_detalle
  id_detalle              BIGINT IDENTITY PK
  id_pase                 BIGINT FK -> pase_caja
  orden                   TINYINT
  concepto                VARCHAR(300) NOT NULL
  cantidad                DECIMAL(10,4) DEFAULT 1
  precio_unitario         DECIMAL(12,2) NOT NULL
  importe                 AS (cantidad * precio_unitario) PERSISTED
  tipo_linea              VARCHAR(20)   -- CARGO/DESCUENTO/RECARGO/MULTA/ACTUALIZACION
```

### Endpoints del módulo de caja

```
# Cajas
GET    /api/v1/cajas
POST   /api/v1/cajas
GET    /api/v1/cajas/{id}
PUT    /api/v1/cajas/{id}
POST   /api/v1/cajas/{id}/abrir
POST   /api/v1/cajas/{id}/cerrar
GET    /api/v1/cajas/{id}/sesion-actual
GET    /api/v1/cajas/{id}/estado-tiempo-real

# Series de folios
GET    /api/v1/series-folio
POST   /api/v1/series-folio
PUT    /api/v1/series-folio/{id}
GET    /api/v1/series-folio/{id}/siguiente-folio   -- preview sin consumir

# Pases de caja
POST   /api/v1/pases-caja                          -- genera el pase (desde cualquier módulo)
GET    /api/v1/pases-caja/{id}
GET    /api/v1/pases-caja/folio/{folio}
GET    /api/v1/pases-caja?estado=&cajero=&fecha_desde=&fecha_hasta=&modulo=
POST   /api/v1/pases-caja/{id}/cobrar              -- solo cajero con sesión abierta
POST   /api/v1/pases-caja/{id}/cancelar
GET    /api/v1/pases-caja/{id}/recibo-pdf

# Sesiones / cortes
GET    /api/v1/sesiones-caja
GET    /api/v1/sesiones-caja/{id}
GET    /api/v1/sesiones-caja/{id}/detalle
GET    /api/v1/sesiones-caja/{id}/corte-pdf

# Dashboard de caja
GET    /api/v1/caja/dashboard
GET    /api/v1/caja/recaudacion-diaria?fecha=
GET    /api/v1/caja/recaudacion-por-concepto?fecha_desde=&fecha_hasta=
GET    /api/v1/caja/exportar-poliza?fecha=
```

---

# ══════════════════════════════════════════════════════
# FASE 7 — ADMINISTRADOR DE INGRESOS
# ══════════════════════════════════════════════════════

## [IMPLEMENTAR F7] Panel del Administrador de Ingresos

Este perfil es el responsable de toda la operación recaudatoria. Sus funciones:

```
1. GESTIÓN DE CAJAS
   Crear cajas, asignar cajeros, supervisar aperturas/cierres,
   hacer conciliaciones, generar pólizas contables del día.

2. GESTIÓN DE TARIFAS Y CATÁLOGOS
   Registrar valor UMA cada año, capturar INPC mensual,
   configurar tasas de recargos, actualizar tarifas por ejercicio,
   gestionar series de folios.

3. CONTROL DE RECAUDACIÓN
   Dashboard en tiempo real: recaudado hoy / mes / año vs meta.
   Cartera de pases pendientes. Alertas de vencimientos.

4. REPORTES Y EXPORTACIONES
   Recaudación por caja/cajero/fuente de ingreso.
   Reporte de deudores. Póliza diaria para contabilidad.
   Exportar a Excel. Estadísticas de eficiencia.
```

### Stored Procedures T-SQL para el Dashboard

```sql
-- SP_01: Resumen ejecutivo del ejercicio
CREATE PROCEDURE catalogos.sp_dashboard_ingresos
    @ejercicio_fiscal INT
AS BEGIN
    -- Totales por fuente de ingreso: esperado vs real vs % cumplimiento
    -- Pases pendientes de cobro
    -- Cajas abiertas en este momento
    -- Comparativo mes actual vs mes anterior
END

-- SP_02: Recaudación diaria detallada
CREATE PROCEDURE caja.sp_recaudacion_dia
    @fecha DATE, @id_caja INT = NULL
AS BEGIN
    -- Desglose por fuente de ingreso, forma de pago y cajero
END

-- SP_03: Pases próximos a vencer (alertas)
CREATE PROCEDURE caja.sp_pases_por_vencer
    @dias_anticipacion INT = 2
AS BEGIN
    -- Lista de pases PENDIENTE cuya fecha_vencimiento <= GETDATE() + @dias
END

-- SP_04: Póliza contable diaria
CREATE PROCEDURE caja.sp_poliza_contable
    @fecha DATE
AS BEGIN
    -- Agrupado por cuenta_contable de la fuente_ingreso
    -- Formato exportable al sistema de contabilidad municipal
END
```

---

# ══════════════════════════════════════════════════════
# FASE 8 — LICENCIAS DE FUNCIONAMIENTO (Schema: licencias)
# ══════════════════════════════════════════════════════

## [IMPLEMENTAR F8-A] DDL — Catálogos de Licencias

```sql
-- ─── TIPOS DE LICENCIA ────────────────────────────────────────────────────
licencias.cat_tipo_licencia
  id_tipo_licencia        INT IDENTITY PK
  clave                   VARCHAR(20) UNIQUE NOT NULL  -- LF-BAA / LF-HOSP / LF-GEN
  nombre                  VARCHAR(200) NOT NULL
  descripcion             VARCHAR(500)
  requiere_pc             BIT DEFAULT 0  -- dictamen Protección Civil
  requiere_dsa            BIT DEFAULT 0  -- pago Saneamiento Ambiental
  requiere_du             BIT DEFAULT 0  -- constancia Desarrollo Urbano
  requiere_zofemat        BIT DEFAULT 0  -- constancia no adeudo ZOFEMAT
  es_bebida_alcoholica    BIT DEFAULT 0  -- Ley de Bebidas Alcohólicas
  activo                  BIT DEFAULT 1
  [+ auditoría estándar]

-- ─── GIROS COMERCIALES ────────────────────────────────────────────────────
licencias.cat_giro
  id_giro                 INT IDENTITY PK
  id_tipo_licencia        INT FK -> cat_tipo_licencia
  clave_giro              VARCHAR(30) UNIQUE NOT NULL  -- REST-01 / HOTEL-5E
  nombre_giro             VARCHAR(300) NOT NULL
  descripcion             VARCHAR(500)
  nivel_riesgo            VARCHAR(20)   -- BAJO / MEDIO / ALTO / MUY_ALTO
  categoria_scian         VARCHAR(10)   -- código SCIAN del INEGI
  activo                  BIT DEFAULT 1
  observaciones           VARCHAR(1000)

-- ─── TARIFAS POR GIRO ─────────────────────────────────────────────────────
-- Referencia catalogos.tarifa_fuente_ingreso, pero mantiene copia para licencias
licencias.cat_tarifa_giro
  id_tarifa               INT IDENTITY PK
  id_giro                 INT FK -> cat_giro
  id_fuente_ingreso       INT FK -> catalogos.fuente_ingreso
  ejercicio_fiscal        INT NOT NULL
  tarifa_uma_anual        DECIMAL(10,4) NOT NULL
  tarifa_mxn_calculada    DECIMAL(12,2)
  valor_uma_aplicado      DECIMAL(10,4)
  aplica_desde            DATE
  aplica_hasta            DATE
  fundamento_legal        VARCHAR(500)
  activo                  BIT DEFAULT 1
```

## [IMPLEMENTAR F8-B] DDL — Licencias (tabla principal y relacionadas)

```sql
-- ─── LICENCIA DE FUNCIONAMIENTO ───────────────────────────────────────────
licencias.licencia_funcionamiento
  id_licencia             BIGINT IDENTITY PK
  folio                   VARCHAR(30) UNIQUE NOT NULL  -- LF-2026-000001 (usa seq_licencia)
  id_serie                INT FK -> caja.serie_folio
  -- Relaciones core
  id_contribuyente        BIGINT FK -> core.contribuyente
  id_predio               BIGINT FK -> predial.predio
  id_giro                 INT FK -> licencias.cat_giro
  id_tipo_licencia        INT FK -> licencias.cat_tipo_licencia
  -- Datos del establecimiento
  razon_social            VARCHAR(500) NOT NULL
  nombre_comercial        VARCHAR(500)
  rfc                     VARCHAR(15)
  domicilio_fiscal        VARCHAR(500)
  domicilio_establecimiento VARCHAR(500)
  telefono                VARCHAR(20)
  email                   VARCHAR(200)
  aforo_personas          INT
  metros_cuadrados        DECIMAL(10,2)
  -- Estado y ejercicio
  estado_licencia         VARCHAR(30) NOT NULL
    -- SOLICITUD / EN_REVISION / REQUISITOS_PENDIENTES
    -- APROBADA_PENDIENTE_PAGO / ACTIVA / SUSPENDIDA
    -- CANCELADA / VENCIDA / RECHAZADA
  CONSTRAINT CK_estado_licencia CHECK (estado_licencia IN (
    'SOLICITUD','EN_REVISION','REQUISITOS_PENDIENTES',
    'APROBADA_PENDIENTE_PAGO','ACTIVA','SUSPENDIDA',
    'CANCELADA','VENCIDA','RECHAZADA'))
  ejercicio_fiscal        INT NOT NULL
  -- Fechas del ciclo de vida
  fecha_solicitud         DATETIME2 NOT NULL DEFAULT GETDATE()
  fecha_emision           DATETIME2
  fecha_vencimiento       DATE             -- siempre 31-DIC del ejercicio
  fecha_cancelacion       DATETIME2
  motivo_cancelacion      VARCHAR(500)
  -- Importes
  id_tarifa               INT FK -> cat_tarifa_giro
  monto_total             DECIMAL(12,2)
  monto_pagado            DECIMAL(12,2) DEFAULT 0
  saldo_pendiente         AS (ISNULL(monto_total,0) - ISNULL(monto_pagado,0)) PERSISTED
  -- Pase de caja generado
  id_pase_caja            BIGINT FK -> caja.pase_caja NULL
  -- Renovación
  id_licencia_anterior    BIGINT FK -> licencia_funcionamiento NULL
  es_nueva                BIT DEFAULT 1
  -- Operadores
  id_usuario_captura      INT FK -> core.usuario
  id_usuario_autoriza     INT FK -> core.usuario NULL
  -- CRI usado en la tramitación
  id_cri_usado            BIGINT FK -> core.cri NULL
  -- PDF generado
  pdf_url                 VARCHAR(500)
  observaciones           NVARCHAR(2000)
  activo                  BIT DEFAULT 1
  [+ auditoría estándar]

-- ─── HISTORIAL DE ESTADOS ─────────────────────────────────────────────────
licencias.historial_estado_licencia
  id_historial            BIGINT IDENTITY PK
  id_licencia             BIGINT FK -> licencia_funcionamiento
  estado_anterior         VARCHAR(30)
  estado_nuevo            VARCHAR(30) NOT NULL
  fecha_cambio            DATETIME2 DEFAULT GETDATE()
  id_usuario              INT FK -> core.usuario
  motivo                  VARCHAR(500)
  ip_origen               VARCHAR(45)

-- ─── REQUISITOS DE LICENCIA ───────────────────────────────────────────────
licencias.requisito_licencia
  id_requisito            BIGINT IDENTITY PK
  id_licencia             BIGINT FK -> licencia_funcionamiento
  tipo_requisito          VARCHAR(50)
    -- PREDIAL / PROTECCION_CIVIL / SANEAMIENTO_AMBIENTAL
    -- DESARROLLO_URBANO / ZOFEMAT / IDENTIFICACION
    -- RFC / ACTA_CONSTITUTIVA / USO_SUELO
  descripcion             VARCHAR(300)
  cumplido                BIT DEFAULT 0
  fecha_cumplimiento      DATETIME2
  folio_referencia        VARCHAR(100)       -- folio del dictamen o pago del módulo externo
  modulo_origen           VARCHAR(50)        -- nombre del MS que validó este requisito
  observaciones           VARCHAR(500)
  id_usuario_valida       INT FK -> core.usuario NULL

-- ─── PAGOS DE LICENCIA ────────────────────────────────────────────────────
-- El pago pasa POR el módulo de caja; aquí se registra la referencia
licencias.pago_licencia
  id_pago                 BIGINT IDENTITY PK
  id_licencia             BIGINT FK -> licencia_funcionamiento
  id_pase_caja            BIGINT FK -> caja.pase_caja
  folio_pago              VARCHAR(50) UNIQUE NOT NULL
  monto                   DECIMAL(12,2) NOT NULL
  fecha_pago              DATETIME2 NOT NULL
  tipo_pago               VARCHAR(30)    -- EFECTIVO/TRANSFERENCIA/TARJETA/CHEQUE
  referencia_bancaria     VARCHAR(100)
  id_caja                 INT FK -> caja.caja
  id_usuario_cajero       INT FK -> core.usuario
  cancelado               BIT DEFAULT 0
  motivo_cancelacion      VARCHAR(300)
  fecha_cancelacion       DATETIME2
```

## [IMPLEMENTAR F8-C] Servicios Python — Licencias

### TarifaService — Cálculo de montos en UMA con proporcionalidad

```python
class TarifaService:
    """
    Calcula el monto de la licencia basado en:
    - Giro comercial → número de UMAs anuales
    - Valor UMA del ejercicio fiscal
    - Proporcionalidad mensual (si se tramita después de enero)
    - Descuento por pronto pago (enero/febrero)

    Regla: monto = tarifa_uma_anual × valor_uma_diario × 365
    Proporcional: si se tramita en marzo → cobra 10/12 del monto anual
    """
    async def calcular_monto_licencia(
        self, id_giro, ejercicio_fiscal, es_renovacion=False, fecha_solicitud=None
    ) -> MontoLicenciaResult: ...

    async def calcular_proporcional(
        self, monto_anual, fecha_solicitud, ejercicio
    ) -> Decimal: ...
```

### RequisitoService — Verificación en paralelo con módulos externos

```python
class RequisitoService:
    """
    Verifica automáticamente los requisitos llamando en paralelo
    (asyncio.gather) a los módulos externos:

    SIEMPRE:
    → PredialService.verificar_no_adeudo(id_predio, ejercicio)

    Si giro.requiere_pc:
    → ProteccionCivilService.obtener_dictamen_vigente(id_predio, id_giro)

    Si giro.requiere_dsa:
    → SaneamientoService.verificar_pago_vigente(rfc, ejercicio)

    Si giro.requiere_du:
    → DesarrolloUrbanoService.verificar_uso_suelo(id_predio, id_giro)

    Si giro.requiere_zofemat:
    → ZofematService.verificar_no_adeudo(id_predio, ejercicio)

    Retorna: puede_emitirse: bool + lista de pendientes + bloqueantes
    """
    async def verificar_todos_los_requisitos(
        self, id_licencia, id_predio, id_contribuyente, id_giro, ejercicio
    ) -> RequisitoVerificacionResult: ...
```

### LicenciaService — Máquina de estados

```python
class LicenciaService:
    """
    Máquina de estados del ciclo de vida de la licencia.

    TRANSICIONES PERMITIDAS:
    SOLICITUD              → EN_REVISION, RECHAZADA
    EN_REVISION            → REQUISITOS_PENDIENTES, APROBADA_PENDIENTE_PAGO, RECHAZADA
    REQUISITOS_PENDIENTES  → EN_REVISION
    APROBADA_PENDIENTE_PAGO→ ACTIVA, RECHAZADA
    ACTIVA                 → SUSPENDIDA, CANCELADA, VENCIDA
    SUSPENDIDA             → ACTIVA, CANCELADA
    VENCIDA                → (terminal — solo renovación crea nueva)
    CANCELADA              → (terminal)
    RECHAZADA              → (terminal)

    Al pasar a ACTIVA: genera PDF + envía email al contribuyente
    Al pasar a SUSPENDIDA: envía notificación + registra motivo
    Al pasar a VENCIDA: proceso batch nocturno del 1 de enero
    """
    TRANSICIONES_PERMITIDAS = { ... }

    async def cambiar_estado(self, id_licencia, nuevo_estado, id_usuario, motivo): ...
    async def iniciar_renovacion(self, id_licencia_anterior, id_usuario): ...
```

## [IMPLEMENTAR F8-D] Endpoints REST — Licencias

```
# Catálogos de licencias
GET    /api/v1/licencias/catalogos/tipos
GET    /api/v1/licencias/catalogos/giros
GET    /api/v1/licencias/catalogos/giros?q=&nivel_riesgo=&tipo=
GET    /api/v1/licencias/catalogos/giros/{id}
GET    /api/v1/licencias/catalogos/tarifas?ejercicio=&id_giro=
POST   /api/v1/licencias/catalogos/tarifas        [ADMIN]
PUT    /api/v1/licencias/catalogos/tarifas/{id}   [ADMIN]

# Licencias — CRUD y flujo principal
POST   /api/v1/licencias                           -- nueva solicitud
GET    /api/v1/licencias
GET    /api/v1/licencias/{id}
GET    /api/v1/licencias/folio/{folio}
GET    /api/v1/licencias?estado=&ejercicio=&rfc=&id_predio=&id_contribuyente=
PUT    /api/v1/licencias/{id}

# Flujo de tramitación (máquina de estados)
POST   /api/v1/licencias/{id}/iniciar-revision
GET    /api/v1/licencias/{id}/requisitos
POST   /api/v1/licencias/{id}/verificar-requisitos  -- llama módulos externos
PUT    /api/v1/licencias/{id}/requisitos/{tipo}      -- marcar requisito cumplido manual
POST   /api/v1/licencias/{id}/aprobar
POST   /api/v1/licencias/{id}/rechazar
POST   /api/v1/licencias/{id}/suspender
POST   /api/v1/licencias/{id}/cancelar
POST   /api/v1/licencias/{id}/reactivar
POST   /api/v1/licencias/{id}/renovar

# Pagos
POST   /api/v1/licencias/{id}/pagos
GET    /api/v1/licencias/{id}/pagos

# Documentos
GET    /api/v1/licencias/{id}/pdf
GET    /api/v1/licencias/{id}/constancia-solicitud

# Reportes de licencias
GET    /api/v1/licencias/reportes/dashboard?ejercicio=
GET    /api/v1/licencias/reportes/recaudacion?ejercicio=&mes=
GET    /api/v1/licencias/reportes/vencimientos-proximos?dias=
GET    /api/v1/licencias/reportes/por-giro?ejercicio=
GET    /api/v1/licencias/reportes/exportar?ejercicio=&estado=
```

## [IMPLEMENTAR F8-E] Seed — Catálogo de giros 2026 (mínimo 60 giros)

```python
GIROS_SEED = [
  # ── ALIMENTOS Y BEBIDAS ────────────────────────────────────────────────
  {"clave":"ALB-REST-SA","nombre":"Restaurante sin venta de bebidas alcohólicas",
   "tipo":"LF-GEN","nivel_riesgo":"BAJO","scian":"722511","uma_anual":15.0,
   "requiere_pc":False,"requiere_dsa":False},

  {"clave":"ALB-REST-BA","nombre":"Restaurante con venta de bebidas alcohólicas",
   "tipo":"LF-BAA","nivel_riesgo":"MEDIO","scian":"722512","uma_anual":35.0,
   "requiere_pc":True,"es_bebida_alcoholica":True},

  {"clave":"ALB-BAR","nombre":"Bar / Cantina",
   "tipo":"LF-BAA","nivel_riesgo":"ALTO","scian":"722410","uma_anual":60.0,
   "requiere_pc":True,"es_bebida_alcoholica":True},

  {"clave":"ALB-DISCO","nombre":"Discoteca / Centro Nocturno",
   "tipo":"LF-BAA","nivel_riesgo":"MUY_ALTO","scian":"711320","uma_anual":100.0,
   "requiere_pc":True,"es_bebida_alcoholica":True},

  # ── HOSPEDAJE ──────────────────────────────────────────────────────────
  {"clave":"HOSP-HTL-5E","nombre":"Hotel 5 estrellas / Gran Turismo",
   "tipo":"LF-HOSP","nivel_riesgo":"MEDIO","scian":"721111","uma_anual":200.0,
   "requiere_pc":True,"requiere_dsa":True,"requiere_zofemat":True},

  {"clave":"HOSP-HTL-4E","nombre":"Hotel 4 estrellas",
   "tipo":"LF-HOSP","nivel_riesgo":"MEDIO","scian":"721112","uma_anual":150.0,
   "requiere_pc":True,"requiere_dsa":True},

  {"clave":"HOSP-HTL-3E","nombre":"Hotel 3 estrellas",
   "tipo":"LF-HOSP","nivel_riesgo":"MEDIO","scian":"721113","uma_anual":120.0,
   "requiere_pc":True,"requiere_dsa":True},

  {"clave":"HOSP-HOSTAL","nombre":"Hostal / Casa de huéspedes",
   "tipo":"LF-HOSP","nivel_riesgo":"BAJO","scian":"721191","uma_anual":40.0,
   "requiere_pc":False,"requiere_dsa":True},

  {"clave":"HOSP-GLAMPING","nombre":"Glamping / Hospedaje ecológico",
   "tipo":"LF-HOSP","nivel_riesgo":"BAJO","scian":"721199","uma_anual":50.0,
   "requiere_pc":False,"requiere_dsa":True,"requiere_zofemat":True},

  # ── COMERCIO AL POR MENOR ──────────────────────────────────────────────
  {"clave":"COM-ABARR","nombre":"Tienda de abarrotes / Miscelánea",
   "tipo":"LF-GEN","nivel_riesgo":"BAJO","scian":"461110","uma_anual":10.0},

  {"clave":"COM-SUPER","nombre":"Supermercado / Minisuper",
   "tipo":"LF-GEN","nivel_riesgo":"BAJO","scian":"462111","uma_anual":30.0},

  {"clave":"COM-FARMA","nombre":"Farmacia",
   "tipo":"LF-GEN","nivel_riesgo":"BAJO","scian":"464111","uma_anual":15.0},

  {"clave":"COM-ROPA","nombre":"Tienda de ropa y calzado",
   "tipo":"LF-GEN","nivel_riesgo":"BAJO","scian":"461311","uma_anual":12.0},

  {"clave":"COM-ARTESANIA","nombre":"Artesanías / Souvenirs",
   "tipo":"LF-GEN","nivel_riesgo":"BAJO","scian":"461390","uma_anual":10.0},

  # ... (continuar hasta mínimo 60 giros cubriendo:
  #  Servicios profesionales, Salud y Belleza, Entretenimiento,
  #  Transporte y Turismo, Construcción, Educación, Deportes,
  #  Tecnología, Servicios Ambientales, Ambulante/Semifijo)
]
```

## [IMPLEMENTAR F8-F] Tests — Casos de prueba obligatorios

```python
class TestLicencias:

    async def test_nueva_licencia_restaurante_sin_alcohol(self):
        """Solicitud → Revisión → Requisitos OK → Pago → Activa. Solo requiere predial."""
        pass

    async def test_nueva_licencia_bar_con_alcohol(self):
        """Verifica que SIN dictamen de Protección Civil el sistema bloquea la emisión."""
        pass

    async def test_nueva_licencia_hotel_zona_costera(self):
        """Flujo completo: Predial + PC + DSA + ZOFEMAT en paralelo."""
        pass

    async def test_calculo_tarifa_proporcional_julio(self):
        """Licencia solicitada en julio 2026 = cobra 6/12 del monto anual."""
        pass

    async def test_bloqueo_por_adeudo_predial(self):
        """Predio con adeudo → estado queda en REQUISITOS_PENDIENTES. HTTP 422."""
        pass

    async def test_renovacion_licencia_anterior(self):
        """Crea nueva licencia vinculada a la anterior con es_nueva=False."""
        pass

    async def test_transicion_estado_invalida(self):
        """ACTIVA → SOLICITUD debe retornar HTTP 400."""
        pass

    async def test_batch_vencimiento_nocturno(self):
        """Proceso del 1 de enero marca todas las licencias del año anterior como VENCIDA."""
        pass
```

---

# ══════════════════════════════════════════════════════
# FASE 9 — AUDITORÍA CENTRALIZADA (Schema: auditoria)
# ══════════════════════════════════════════════════════

## [IMPLEMENTAR F9] DDL + Middleware de Auditoría

```sql
auditoria.log_operacion
  id_log                BIGINT IDENTITY PK
  id_usuario            INT FK -> core.usuario NULL
  username              VARCHAR(50)
  ip_origen             VARCHAR(45)
  user_agent            VARCHAR(500)
  modulo                VARCHAR(50) NOT NULL    -- CORE/CAJA/PREDIAL/LICENCIAS
  entidad               VARCHAR(100) NOT NULL   -- nombre de la tabla afectada
  id_entidad            VARCHAR(50)
  operacion             VARCHAR(20) NOT NULL    -- INSERT/UPDATE/DELETE/LOGIN
                                                -- PAGO/EMISION/CANCELACION
  datos_anteriores      NVARCHAR(MAX)           -- JSON del estado previo
  datos_nuevos          NVARCHAR(MAX)           -- JSON del estado nuevo
  campos_modificados    NVARCHAR(MAX)           -- JSON array de campos modificados
  descripcion           VARCHAR(500)
  resultado             VARCHAR(20) DEFAULT 'OK'
  mensaje_error         VARCHAR(1000)
  fecha_operacion       DATETIME2 DEFAULT GETDATE()
  duracion_ms           INT

-- Índices
CREATE INDEX IX_log_usuario    ON auditoria.log_operacion (id_usuario, fecha_operacion DESC)
CREATE INDEX IX_log_modulo     ON auditoria.log_operacion (modulo, entidad, id_entidad)
CREATE INDEX IX_log_fecha      ON auditoria.log_operacion (fecha_operacion DESC)
```

```python
class AuditoriaMiddleware:
    """
    Middleware global de FastAPI.
    - Intercepta todos los POST/PUT/DELETE y operaciones sensibles
    - Inserta en auditoria.log_operacion de forma ASYNC (background task)
    - Excluye: GET de catálogos, health check, docs
    - Para escrituras: captura datos_anteriores y datos_nuevos automáticamente
    """
    pass
```

---

# ══════════════════════════════════════════════════════
# FASE 10 — FRONTEND REACT (plantilla existente del usuario)
# ══════════════════════════════════════════════════════

## [IMPLEMENTAR F10] Estructura y pantallas mínimas

> Adaptar a la plantilla existente del usuario manteniendo
> la estructura de componentes ya definida.

```
src/
├── features/
│   ├── auth/              -- Login, cambio de contraseña obligatorio (primer login)
│   ├── usuarios/          -- CRUD usuarios, asignación de roles
│   ├── contribuyentes/    -- Padrón: búsqueda, ficha, estado de cuenta, documentos
│   ├── catalogos/         -- UMA, INPC, recargos, fuentes de ingreso, parámetros
│   ├── catastro/          -- Búsqueda y ficha de predios
│   ├── cri/               -- Solicitud, vista previa y descarga de CRI
│   ├── caja/              -- Apertura, cobro, pases pendientes, cierre, corte
│   ├── licencias/         -- Wizard de solicitud + bandeja de revisión + consulta
│   └── admin-ingresos/    -- Dashboard ejecutivo + reportes + configuración
│
├── components/common/
│   ├── DataTable/         -- tabla con paginación, filtros, exportar a Excel
│   ├── StatusBadge/       -- badge de estados con colores por módulo
│   └── VerificadorRequisitos/ -- componente clave para el wizard de licencias
│
└── store/
    ├── authStore.ts       -- usuario, token, permisos efectivos
    └── cajaStore.ts       -- caja activa, sesión actual del cajero
```

### Pantallas obligatorias

```
1. LOGIN — formulario, bloqueo por intentos, cambio de contraseña forzado

2. DASHBOARD PRINCIPAL — métricas del día por rol del usuario

3. CONTRIBUYENTES — búsqueda + ficha + estado de cuenta consolidado + CRI

4. CATÁLOGOS — UMA / INPC / recargos / fuentes de ingreso / parámetros

5. CATASTRO — búsqueda de predios + ficha con mapa

6. CRI — formulario de solicitud → verificación en tiempo real → PDF
         Pantalla pública /verificar/{folio} (sin login)

7. CAJA — apertura → bandeja de pases → modal de cobro → cierre con conteo físico

8. LICENCIAS — wizard 5 pasos:
   Paso 1: Buscar/registrar contribuyente
   Paso 2: Seleccionar predio
   Paso 3: Seleccionar giro + tipo de licencia
   Paso 4: Verificación de requisitos (spinner por módulo, en paralelo)
   Paso 5: Resumen + generar pase de caja

9. ADMIN DE INGRESOS — gráfica recaudación 30 días + tabla por fuente +
                       alertas de vencimientos + exportar póliza

10. USUARIOS — CRUD + asignación de roles con checkboxes
```

---

# ══════════════════════════════════════════════════════
# ESTRUCTURA DEL PROYECTO PYTHON
# ══════════════════════════════════════════════════════

```
siim_backend/
├── app/
│   ├── main.py                   -- FastAPI app, routers, lifespan, middleware
│   ├── config.py                 -- Settings (pydantic-settings, lee el .env)
│   ├── database.py               -- Engine SQL Server, sesión async, get_db
│   │
│   ├── core/                     -- Módulo Core
│   │   ├── models/               -- SQLAlchemy ORM
│   │   ├── schemas/              -- Pydantic v2
│   │   ├── routers/              -- FastAPI routers
│   │   ├── services/             -- Lógica de negocio
│   │   └── dependencies.py      -- require_permission, get_current_user
│   │
│   ├── caja/                     -- Módulo Caja
│   ├── catalogos/                -- Módulo Catálogos
│   ├── predial/                  -- Módulo Predial/Catastro
│   ├── licencias/                -- Módulo Licencias
│   │   ├── integrations/         -- Clientes HTTP a PC, DU, DSA, ZOFEMAT
│   │   └── workers/              -- Celery: vencimientos, renovaciones batch
│   │
│   └── auditoria/                -- Middleware + modelos de log
│
├── migrations/                   -- Alembic
│   └── versions/
├── tests/
├── scripts/
│   ├── init_db.sql               -- Crea schemas y secuencias
│   └── seed_data.py              -- Carga datos iniciales
├── .env                          -- ← AQUÍ VAN LOS DATOS DE CONEXIÓN
├── alembic.ini
├── pyproject.toml
└── docker-compose.yml
```

---

# ══════════════════════════════════════════════════════
# PDF — DOCUMENTOS OFICIALES
# ══════════════════════════════════════════════════════

## [IMPLEMENTAR] Plantillas PDF con WeasyPrint

### Licencia de Funcionamiento
- Escudo del H. Ayuntamiento de Tulum
- Folio con código QR → `https://tulum.gob.mx/verificar/licencia/{folio}`
- Datos del establecimiento: razón social, nombre comercial, domicilio
- Giro autorizado + código SCIAN
- Vigencia: 1 enero al 31 de diciembre del ejercicio
- Aforo autorizado + metros cuadrados
- Condiciones especiales (si aplica)
- Firma digital del Tesorero Municipal + sello oficial
- Leyenda: "Este documento no exime del cumplimiento de otras disposiciones aplicables"

### Recibo de Pago
- Folio de recibo, fecha y hora, cajero y caja
- Datos del contribuyente + RFC
- Desglose de conceptos, importes y forma de pago
- Código QR de verificación del pago

### CRI (Constancia de Registro de Ingresos)
- Estado por módulo (semáforos: verde/rojo/gris)
- Desglose de adeudos si los hay
- Vigencia de 30 días
- QR → `https://tulum.gob.mx/verificar/cri/{folio}`
- Firma del Tesorero + hash de autenticidad

---

# ══════════════════════════════════════════════════════
# VARIABLES DE ENTORNO — ARCHIVO .env COMPLETO
# ══════════════════════════════════════════════════════

```env
# ════════════════════════════════════════════════════
# BASE DE DATOS — COMPLETAR CON LOS DATOS DE TU BD
# ════════════════════════════════════════════════════
DB_HOST=
DB_PORT=1433
DB_NAME=
DB_USER=
DB_PASSWORD=

# ════════════════════════════════════════════════════
# SEGURIDAD JWT
# ════════════════════════════════════════════════════
JWT_SECRET_KEY=
JWT_ALGORITHM=HS256
JWT_EXPIRE_MINUTES=480
JWT_REFRESH_EXPIRE_DAYS=1

# ════════════════════════════════════════════════════
# REDIS / CELERY
# ════════════════════════════════════════════════════
REDIS_URL=redis://localhost:6379/0

# ════════════════════════════════════════════════════
# ALMACENAMIENTO DE ARCHIVOS
# ════════════════════════════════════════════════════
STORAGE_PATH=./storage
STORAGE_URL=http://localhost:8000/storage

# ════════════════════════════════════════════════════
# EMAIL (notificaciones)
# ════════════════════════════════════════════════════
SMTP_HOST=
SMTP_PORT=587
SMTP_USER=
SMTP_PASSWORD=
EMAIL_FROM=noreply@tulum.gob.mx

# ════════════════════════════════════════════════════
# MICROSERVICIOS EXTERNOS (módulos futuros)
# ════════════════════════════════════════════════════
MS_PROTECCION_CIVIL_URL=http://localhost:8002
MS_DESARROLLO_URBANO_URL=http://localhost:8003
MS_SANEAMIENTO_AMBIENTAL_URL=http://localhost:8004
MS_ZOFEMAT_URL=http://localhost:8005

# ════════════════════════════════════════════════════
# FRONTEND
# ════════════════════════════════════════════════════
VITE_API_BASE_URL=http://localhost:8000/api/v1
VITE_APP_NOMBRE=SIIM Tulum
VITE_APP_VERSION=2.0.0

# ════════════════════════════════════════════════════
# PARÁMETROS MUNICIPALES (usados en PDFs y folios)
# ════════════════════════════════════════════════════
MUNICIPIO_NOMBRE=Tulum
MUNICIPIO_ESTADO=Quintana Roo
EJERCICIO_FISCAL_ACTIVO=2026
UMA_2026_DIARIO=113.14
```

---

# ══════════════════════════════════════════════════════
# NOTAS TÉCNICAS CRÍTICAS
# ══════════════════════════════════════════════════════

1. **Cadena de conexión SQL Server desde Python:**
   `mssql+pyodbc://{user}:{pass}@{host}:{port}/{db}?driver=ODBC+Driver+18+for+SQL+Server&TrustServerCertificate=yes`
   Requiere: `pip install sqlalchemy pyodbc` + ODBC Driver 18 instalado en el servidor.

2. **Atomicidad en generación de folios:**
   Usar `NEXT VALUE FOR caja.seq_*` o `UPDATE serie_folio SET consecutivo_actual += 1 OUTPUT INSERTED.*`
   para garantizar unicidad bajo alta concurrencia. NUNCA usar MAX(id)+1.

3. **Verificación de requisitos en paralelo:**
   Usar `asyncio.gather(*tareas, return_exceptions=True)` para llamar a todos los
   módulos externos al mismo tiempo. Reduce el tiempo de ~5s a ~1.5s.

4. **Cálculo UMA fijado al momento de solicitud:**
   El monto se calcula con el valor UMA vigente en la fecha de solicitud y NO cambia
   retroactivamente aunque la UMA se actualice durante el ejercicio.

5. **Pase de caja como capa de cobro universal:**
   Ningún módulo cobra directamente. Todos generan un pase de caja en `caja.pase_caja`
   y el cajero lo cobra desde su módulo de caja. Esto garantiza control centralizado
   de la recaudación.

6. **Soft delete universal:**
   Ningún registro se elimina físicamente. Todos tienen campo `activo BIT DEFAULT 1`.
   Las eliminaciones son lógicas (activo = 0) con registro en auditoría.

7. **BD nueva desde cero:**
   El script `scripts/init_db.sql` crea todos los schemas y secuencias.
   Las migraciones Alembic crean todas las tablas.
   El script `scripts/seed_data.py` carga los datos iniciales (roles, módulos,
   permisos, UMA 2026, ejercicio fiscal, giros, series de folios, cajas, parámetros).

---

# ══════════════════════════════════════════════════════
# ORDEN DE IMPLEMENTACIÓN — SPRINTS RECOMENDADOS
# ══════════════════════════════════════════════════════

```
SPRINT 1 — Infraestructura base (2 semanas)
  F0: init_db.sql (schemas + secuencias) + .env con datos de conexión
  F1: Usuarios, roles, RBAC, JWT
  Frontend: Login + sidebar con permisos dinámicos

SPRINT 2 — Padrón y catálogos (2 semanas)
  F2: Contribuyentes
  F3: UMA, INPC, recargos, fuentes de ingreso, parámetros
  Frontend: Contribuyentes + Catálogos

SPRINT 3 — Catastro y CRI (2 semanas)
  F4: Catastro (predios)
  F5: CRI — generación, PDF, QR, verificación pública
  Frontend: Catastro + CRI

SPRINT 4 — Caja y cobros (2 semanas)
  F6: Cajas, series, pases de caja, cortes
  F7: Dashboard Administrador de Ingresos
  Frontend: Módulo de caja completo

SPRINT 5 — Licencias (3 semanas)
  F8: Licencias de Funcionamiento completo
  Frontend: Wizard de solicitud + bandeja de revisión

SPRINT 6+ — Escalamiento
  Predial + ISABI → Tránsito + Multas → Registro Civil → ZOFEMAT + Saneamiento
```

---

# ══════════════════════════════════════════════════════
# ENTREGABLES TOTALES DEL SISTEMA
# ══════════════════════════════════════════════════════

```
✅ scripts/init_db.sql          — schemas, secuencias, tipos
✅ migrations/                  — Alembic: todas las tablas, índices, constraints
✅ scripts/seed_data.py         — datos iniciales completos
✅ app/core/                    — usuarios, RBAC, contribuyentes, CRI
✅ app/caja/                    — cajas, series, pases, cortes
✅ app/catalogos/               — UMA, INPC, recargos, fuentes, parámetros
✅ app/predial/                 — catastro, predios
✅ app/licencias/               — licencias, giros, tarifas, máquina de estados
✅ app/auditoria/               — middleware + log centralizado
✅ stored_procedures/           — SPs de dashboard y reportes
✅ templates/pdf/               — plantillas WeasyPrint: recibo, licencia, CRI
✅ tests/                       — suite completa de pruebas por módulo
✅ src/ (React)                 — frontend completo adaptado a la plantilla
✅ docker-compose.yml           — entorno completo levantable en un comando
✅ .env.example                 — plantilla de variables con espacios para llenar
```

---

*PROMPT MAESTRO SIIM v2.0 — Unificado*
*H. Ayuntamiento del Municipio de Tulum, Quintana Roo*
*Marco Legal: Ley de Hacienda Municipal POE 10-12-2025 | Ley de Ingresos 2026 Decreto 162*
*Base de datos: NUEVA — todos los objetos se crean desde cero*
