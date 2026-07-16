-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  SIIM — SCHEMA core — USUARIOS, ROLES Y SEGURIDAD (RBAC)                  ║
-- ║  H. Ayuntamiento del Municipio de Tulum, Quintana Roo                    ║
-- ║  Motor: PostgreSQL 14+                                                    ║
-- ║  Requiere: 00-init-schemas-y-convenciones.sql ejecutado antes.           ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- ══════════════════════════════════════════════════════════════════
-- SECCIÓN 1: DEPENDENCIAS Y ÁREAS ORGANIZACIONALES
-- ══════════════════════════════════════════════════════════════════
CREATE TABLE core.cat_dependencia (
    id_dependencia          INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    clave                   VARCHAR(20)   NOT NULL UNIQUE,   -- TES, CAT, PC, DU, RC
    nombre                  VARCHAR(200)  NOT NULL,
    nombre_corto            VARCHAR(50),
    responsable             VARCHAR(200),
    activo                  BOOLEAN       NOT NULL DEFAULT true,
    fecha_creacion          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    fecha_modificacion      TIMESTAMPTZ,
    id_usuario_creacion     INT,
    id_usuario_modificacion INT
);

CREATE TABLE core.cat_area (
    id_area                 INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_dependencia          INT           NOT NULL REFERENCES core.cat_dependencia (id_dependencia),
    clave                   VARCHAR(20)   NOT NULL,
    nombre                  VARCHAR(200)  NOT NULL,
    activo                  BOOLEAN       NOT NULL DEFAULT true,
    fecha_creacion          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    fecha_modificacion      TIMESTAMPTZ,
    id_usuario_creacion     INT,
    id_usuario_modificacion INT
);

-- ══════════════════════════════════════════════════════════════════
-- SECCIÓN 2: USUARIOS
-- ══════════════════════════════════════════════════════════════════
CREATE TABLE core.usuario (
    id_usuario              INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_area                 INT           REFERENCES core.cat_area (id_area),
    username                VARCHAR(50)   NOT NULL UNIQUE,
    email                   VARCHAR(200)  NOT NULL UNIQUE,
    password_hash           VARCHAR(255)  NOT NULL,          -- bcrypt
    nombre                  VARCHAR(100)  NOT NULL,
    apellido_paterno        VARCHAR(100)  NOT NULL,
    apellido_materno        VARCHAR(100),
    nombre_completo         TEXT GENERATED ALWAYS AS (
                                TRIM(nombre || ' ' || apellido_paterno || ' ' || COALESCE(apellido_materno, ''))
                            ) STORED,
    telefono                VARCHAR(20),
    extension               VARCHAR(10),
    curp                    VARCHAR(20),
    rfc_usuario             VARCHAR(15),
    foto_url                VARCHAR(500),
    ultimo_login            TIMESTAMPTZ,
    intentos_fallidos       SMALLINT      NOT NULL DEFAULT 0,
    bloqueado               BOOLEAN       NOT NULL DEFAULT false,
    fecha_bloqueo           TIMESTAMPTZ,
    motivo_bloqueo          VARCHAR(300),
    fecha_alta              DATE          NOT NULL DEFAULT CURRENT_DATE,
    fecha_baja              DATE,
    activo                  BOOLEAN       NOT NULL DEFAULT true,
    debe_cambiar_password   BOOLEAN       NOT NULL DEFAULT true,
    fecha_ultimo_password   TIMESTAMPTZ,
    fecha_creacion          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    fecha_modificacion      TIMESTAMPTZ,
    id_usuario_creacion     INT,
    id_usuario_modificacion INT
);

-- ══════════════════════════════════════════════════════════════════
-- SECCIÓN 3: RBAC — MÓDULOS, PERMISOS, ROLES
-- ══════════════════════════════════════════════════════════════════
CREATE TABLE core.cat_modulo (
    id_modulo               INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    clave                   VARCHAR(50)   NOT NULL UNIQUE,   -- CORE, CAJA, PREDIAL, LICENCIAS
    nombre                  VARCHAR(200)  NOT NULL,
    descripcion             VARCHAR(500),
    icono                   VARCHAR(100),
    ruta_base               VARCHAR(200),
    orden_menu              INT           NOT NULL DEFAULT 0,
    activo                  BOOLEAN       NOT NULL DEFAULT true
);

CREATE TABLE core.cat_permiso (
    id_permiso              INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_modulo               INT           NOT NULL REFERENCES core.cat_modulo (id_modulo),
    clave                   VARCHAR(100)  NOT NULL UNIQUE,   -- PREDIAL:CONSULTAR, CAJA:COBRAR
    nombre                  VARCHAR(200)  NOT NULL,
    descripcion             VARCHAR(500),
    activo                  BOOLEAN       NOT NULL DEFAULT true
);

CREATE TABLE core.cat_rol (
    id_rol                  INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    clave                   VARCHAR(50)   NOT NULL UNIQUE,
    nombre                  VARCHAR(200)  NOT NULL,
    descripcion             VARCHAR(500),
    es_rol_sistema          BOOLEAN       NOT NULL DEFAULT false,   -- no eliminable
    activo                  BOOLEAN       NOT NULL DEFAULT true,
    fecha_creacion          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    fecha_modificacion      TIMESTAMPTZ,
    id_usuario_creacion     INT,
    id_usuario_modificacion INT
);

CREATE TABLE core.rol_permiso (
    id_rol_permiso          INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_rol                  INT           NOT NULL REFERENCES core.cat_rol (id_rol),
    id_permiso              INT           NOT NULL REFERENCES core.cat_permiso (id_permiso),
    UNIQUE (id_rol, id_permiso)
);

CREATE TABLE core.usuario_rol (
    id_usuario_rol          INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_usuario              INT           NOT NULL REFERENCES core.usuario (id_usuario),
    id_rol                  INT           NOT NULL REFERENCES core.cat_rol (id_rol),
    fecha_asignacion        DATE          NOT NULL DEFAULT CURRENT_DATE,
    fecha_expiracion        DATE,
    id_usuario_asigna       INT           REFERENCES core.usuario (id_usuario),
    activo                  BOOLEAN       NOT NULL DEFAULT true,
    UNIQUE (id_usuario, id_rol)
);

-- ══════════════════════════════════════════════════════════════════
-- SECCIÓN 4: SESIONES Y LOG DE ACCESO
-- ══════════════════════════════════════════════════════════════════
CREATE TABLE core.sesion_usuario (
    id_sesion               BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_usuario              INT           NOT NULL REFERENCES core.usuario (id_usuario),
    token_jti               VARCHAR(100)  NOT NULL UNIQUE,   -- JWT ID único
    ip_origen               VARCHAR(45),
    user_agent              VARCHAR(500),
    fecha_inicio            TIMESTAMPTZ   NOT NULL DEFAULT now(),
    fecha_expiracion        TIMESTAMPTZ   NOT NULL,
    revocado                BOOLEAN       NOT NULL DEFAULT false,
    fecha_revocacion        TIMESTAMPTZ
);

CREATE TABLE core.log_acceso (
    id_log                  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_usuario              INT           REFERENCES core.usuario (id_usuario),  -- NULL si login fallido
    username_intento        VARCHAR(50),
    tipo_evento             VARCHAR(30)   NOT NULL,   -- LOGIN_OK/LOGIN_FAIL/LOGOUT/BLOQUEO/CAMBIO_PASSWORD
    ip_origen               VARCHAR(45),
    user_agent              VARCHAR(500),
    detalle                 VARCHAR(500),
    fecha_evento            TIMESTAMPTZ   NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS ix_logacceso_usuario_fecha ON core.log_acceso (id_usuario, fecha_evento DESC);

-- ══════════════════════════════════════════════════════════════════
-- SECCIÓN 5: PARÁMETROS DEL SISTEMA
-- ══════════════════════════════════════════════════════════════════
CREATE TABLE core.parametro_sistema (
    id_parametro            INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    clave                   VARCHAR(100)  NOT NULL UNIQUE,
    valor                   TEXT          NOT NULL,
    tipo_dato               VARCHAR(20),   -- STRING/INT/DECIMAL/BOOL/JSON/DATE
    descripcion             VARCHAR(500),
    modulo                  VARCHAR(50),
    es_sensible             BOOLEAN       NOT NULL DEFAULT false,
    modificable_en_ui       BOOLEAN       NOT NULL DEFAULT true,
    fecha_creacion          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    fecha_modificacion      TIMESTAMPTZ
);

-- ══════════════════════════════════════════════════════════════════
-- SECCIÓN 6: SEED — ROLES, MÓDULOS Y PARÁMETROS
-- ══════════════════════════════════════════════════════════════════
INSERT INTO core.cat_rol (clave, nombre, descripcion, es_rol_sistema) VALUES
 ('SUPER_ADMIN',    'Super Administrador',       'Acceso total al sistema, solo IT',                    true),
 ('ADMIN_INGRESOS', 'Administrador de Ingresos', 'Administra cajas, tarifas y reportes',                true),
 ('JEFE_CAJA',      'Jefe de Caja',              'Supervisa cajeros y realiza cortes',                  true),
 ('CAJERO',         'Cajero',                    'Cobra trámites y ve sus propios movimientos',         true),
 ('CAPTURISTA',     'Capturista',                'Captura trámites y genera pase de caja (no cobra)',   true),
 ('REVISOR',        'Revisor',                   'Aprueba/rechaza trámites (no cobra)',                 true),
 ('CONSULTA',       'Consulta',                  'Solo lectura en los módulos asignados',               true),
 ('AUDITOR',        'Auditor',                   'Acceso solo-lectura a logs y auditoría',              true);

INSERT INTO core.cat_modulo (clave, nombre, descripcion, ruta_base, orden_menu) VALUES
 ('CORE',      'Administración',     'Usuarios, roles y configuración', '/admin',      1),
 ('CAJA',      'Caja',               'Cajas, pases y cortes',           '/caja',       2),
 ('PREDIAL',   'Predial y Catastro', 'Padrón de predios y predial',     '/predial',    3),
 ('LICENCIAS', 'Licencias',          'Licencias de funcionamiento',     '/licencias',  4),
 ('ISABI',     'ISABI',              'Impuesto adquisición inmuebles',  '/isabi',      5),
 ('AUDITORIA', 'Auditoría',          'Bitácora del sistema',            '/auditoria',  99);

INSERT INTO core.parametro_sistema (clave, valor, tipo_dato, descripcion, modulo) VALUES
 ('EJERCICIO_FISCAL_ACTIVO',        '2026',           'INT',     'Ejercicio fiscal en curso',            'CORE'),
 ('NOMBRE_MUNICIPIO',               'Tulum',          'STRING',  'Nombre del municipio',                 'CORE'),
 ('NOMBRE_ESTADO',                  'Quintana Roo',   'STRING',  'Nombre del estado',                    'CORE'),
 ('RFC_MUNICIPIO',                  '',               'STRING',  'RFC del ayuntamiento',                 'CORE'),
 ('LOGO_MUNICIPIO_URL',             '',               'STRING',  'URL del logo institucional',           'CORE'),
 ('UMA_VALOR_DIARIO_2026',          '113.14',         'DECIMAL', 'Valor diario de la UMA 2026 (MXN)',    'CATALOGOS'),
 ('DIAS_VIGENCIA_PASE_CAJA',        '5',              'INT',     'Vigencia del pase de caja (dias)',     'CAJA'),
 ('DIAS_VIGENCIA_CRI',              '30',             'INT',     'Vigencia del CRI (dias)',              'CORE'),
 ('PERMITE_PAGO_PARCIAL',           'false',          'BOOL',    'Permite pagos parciales',              'CAJA'),
 ('DIAS_AVISO_VENCIMIENTO_LICENCIA','30',             'INT',     'Dias de aviso previo a vencimiento',   'LICENCIAS');

-- ══════════════════════════════════════════════════════════════════
-- SECCIÓN 7: SEED — USUARIO SUPER_ADMIN INICIAL
-- El password_hash debe reemplazarse por un bcrypt real generado en la app.
-- Contraseña temporal sugerida: 'Tulum2026!' (debe_cambiar_password = true).
-- ══════════════════════════════════════════════════════════════════
DO $do$
DECLARE
    v_id_admin INT;
    v_id_rol   INT;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM core.usuario WHERE username = 'admin') THEN
        INSERT INTO core.usuario (username, email, password_hash, nombre, apellido_paterno, debe_cambiar_password)
        VALUES ('admin', 'sistemas.tulum@gmail.com',
                '$2b$12$uzKDjdCCOwYx8BUIeeiWcOGPvXH0VUz/t6Q62mXP5p7uNQXYMcC.G',
                'Administrador', 'del Sistema', true)
        RETURNING id_usuario INTO v_id_admin;

        SELECT id_rol INTO v_id_rol FROM core.cat_rol WHERE clave = 'SUPER_ADMIN';
        INSERT INTO core.usuario_rol (id_usuario, id_rol) VALUES (v_id_admin, v_id_rol);
    END IF;
END $do$;

DO $$ BEGIN
    RAISE NOTICE '>> Schema core (usuarios/RBAC) creado y sembrado correctamente.';
    RAISE NOTICE '>> Usuario inicial: admin | Rol: SUPER_ADMIN | Cambiar contrasena en primer login.';
END $$;
