-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  SIIM — MÓDULO ISABI — ARCHIVO COMPLETO                                 ║
-- ║  H. Ayuntamiento del Municipio de Tulum, Quintana Roo                   ║
-- ║                                                                          ║
-- ║  Contenido:                                                              ║
-- ║  1. isabi.cat_tipo_operacion  — 25 tipos de traslado de dominio         ║
-- ║  2. isabi.cat_tasa_historica  — Historial de tasas Tulum 2000-2026      ║
-- ║  3. isabi.sp_calcular_isabi   — Cálculo automático integrado            ║
-- ║  4. isabi.v_tipos_operacion_activos — Vista operativa                   ║
-- ║  5. isabi.v_selector_tipo_operacion — Vista para formulario frontend    ║
-- ║                                                                          ║
-- ║  Fundamento legal:                                                       ║
-- ║  · Ley ISABI Municipios QRoo — POE 03-10-2011, última ref. 30-10-2012  ║
-- ║  · Ley de Hacienda Municipio Tulum — POE 27-12-2019 Decreto 023        ║
-- ║  · Ley de Hacienda Municipio Tulum — POE 09-12-2024 (tasa 4% vigente)  ║
-- ║  · Ley de Hacienda Municipios QRoo — Arts. 29-34 (2000-2011)           ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

SET NOCOUNT ON;
GO

-- ══════════════════════════════════════════════════════════════════
-- SCHEMA
-- ══════════════════════════════════════════════════════════════════
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'isabi')
    EXEC('CREATE SCHEMA isabi');
GO

-- ══════════════════════════════════════════════════════════════════
-- SECCIÓN 1: cat_tipo_operacion
-- ══════════════════════════════════════════════════════════════════
CREATE TABLE isabi.cat_tipo_operacion (
  id_tipo_operacion            INT           IDENTITY(1,1) NOT NULL,
  clave                        VARCHAR(60)   NOT NULL,
  nombre                       VARCHAR(300)  NOT NULL,
  nombre_corto                 VARCHAR(100)  NOT NULL,
  descripcion                  NVARCHAR(MAX) NULL,
  fundamento_legal             VARCHAR(500)  NULL,
  articulo_ley                 VARCHAR(100)  NULL,
  -- Fiscal
  genera_isabi                 BIT           NOT NULL CONSTRAINT DF_to_isabi   DEFAULT 1,
  genera_adicional_turismo     BIT           NOT NULL CONSTRAINT DF_to_tur     DEFAULT 1,
  -- Base de cálculo
  base_calculo                 VARCHAR(50)   NULL,
  aplica_factor_50pct          BIT           NOT NULL CONSTRAINT DF_to_50pct   DEFAULT 0,
  -- Época de pago
  dias_pago_habiles            TINYINT       NOT NULL CONSTRAINT DF_to_dias    DEFAULT 15,
  momento_causacion            VARCHAR(200)  NULL,
  -- Documentación requerida
  requiere_escritura_publica   BIT           NOT NULL CONSTRAINT DF_to_escr    DEFAULT 1,
  requiere_avaluo              BIT           NOT NULL CONSTRAINT DF_to_aval    DEFAULT 1,
  requiere_predial_vigente     BIT           NOT NULL CONSTRAINT DF_to_pred    DEFAULT 1,
  requiere_acta_defuncion      BIT           NOT NULL CONSTRAINT DF_to_def     DEFAULT 0,
  requiere_declaratoria_hered  BIT           NOT NULL CONSTRAINT DF_to_her     DEFAULT 0,
  requiere_const_zofemat       BIT           NOT NULL CONSTRAINT DF_to_zof     DEFAULT 0,
  requiere_resolucion_judicial BIT           NOT NULL CONSTRAINT DF_to_jud     DEFAULT 0,
  requiere_acta_asamblea       BIT           NOT NULL CONSTRAINT DF_to_asm     DEFAULT 0,
  requiere_contrato_fideicom   BIT           NOT NULL CONSTRAINT DF_to_fid     DEFAULT 0,
  documentacion_adicional      NVARCHAR(MAX) NULL,
  -- Exenciones
  puede_ser_exento             BIT           NOT NULL CONSTRAINT DF_to_exen    DEFAULT 0,
  condicion_exencion           NVARCHAR(MAX) NULL,
  exento_por_ley               BIT           NOT NULL CONSTRAINT DF_to_exley   DEFAULT 0,
  -- Catastro
  actualiza_propietario_catastro BIT         NOT NULL CONSTRAINT DF_to_cat     DEFAULT 1,
  genera_historial_propietario   BIT         NOT NULL CONSTRAINT DF_to_hist    DEFAULT 1,
  -- Partes
  nombre_parte_transmite       VARCHAR(100)  NULL,
  nombre_parte_adquiere        VARCHAR(100)  NULL,
  -- Clasificación
  grupo                        VARCHAR(50)   NULL,
  es_onerosa                   BIT           NOT NULL CONSTRAINT DF_to_oner    DEFAULT 1,
  es_modalidad_de              INT           NULL REFERENCES isabi.cat_tipo_operacion(id_tipo_operacion),
  -- Meta
  activo                       BIT           NOT NULL CONSTRAINT DF_to_activo  DEFAULT 1,
  orden_display                INT           NULL,
  notas_internas               VARCHAR(1000) NULL,
  fecha_creacion               DATETIME2(0)  NOT NULL CONSTRAINT DF_to_fcreac  DEFAULT GETDATE(),
  fecha_modificacion           DATETIME2(0)  NULL,
  id_usuario_creacion          INT           NULL,
  id_usuario_modificacion      INT           NULL,
  CONSTRAINT PK_cat_tipo_operacion  PRIMARY KEY (id_tipo_operacion),
  CONSTRAINT UQ_tipo_op_clave       UNIQUE (clave),
  CONSTRAINT CK_tipo_op_base        CHECK (base_calculo IN (
    'VALOR_MAS_ALTO','PRECIO_OPERACION','AVALUO_COMERCIAL',
    'CINCUENTA_PCT_VALOR','SIN_BASE', NULL))
);
GO
CREATE INDEX IX_tipo_op_grupo ON isabi.cat_tipo_operacion (grupo, activo);
CREATE INDEX IX_tipo_op_isabi ON isabi.cat_tipo_operacion (genera_isabi, activo);
GO

-- ══════════════════════════════════════════════════════════════════
-- SECCIÓN 2: cat_tasa_historica
-- ══════════════════════════════════════════════════════════════════
CREATE TABLE isabi.cat_tasa_historica (
  id_tasa                  INT           IDENTITY(1,1) NOT NULL,
  -- Ámbito
  clave_municipio          VARCHAR(10)   NOT NULL,   -- 'TULUM' / 'BJ' / 'SOLIDARIDAD' / 'OTROS_QRoo'
  nombre_municipio         VARCHAR(200)  NOT NULL,
  clave_estado             CHAR(2)       NOT NULL CONSTRAINT DF_th_estado DEFAULT '23',
  -- Vigencia del período
  ejercicio_fiscal_inicio  INT           NOT NULL,   -- año de inicio del período
  ejercicio_fiscal_fin     INT           NULL,        -- NULL = vigente / sin fecha de término
  fecha_inicio_exacta      DATE          NOT NULL,   -- fecha exacta de entrada en vigor
  fecha_fin_exacta         DATE          NULL,        -- NULL = vigente
  -- Tasas
  tasa_isabi_pct           DECIMAL(6,4)  NOT NULL,   -- 2.0000 / 3.0000 / 4.0000
  tasa_adicional_pct       DECIMAL(6,4)  NOT NULL CONSTRAINT DF_th_adic DEFAULT 0,  -- 10.0000 = 10%
  tasa_efectiva_pct        AS (tasa_isabi_pct + (tasa_isabi_pct * tasa_adicional_pct / 100.0)) PERSISTED,
  -- Instrumento legal
  nombre_ley               VARCHAR(300)  NOT NULL,
  articulo_tasa            VARCHAR(100)  NULL,       -- 'Art. 9' / 'Art. 46 Quinquies' / 'Art. 50'
  numero_decreto           VARCHAR(100)  NULL,
  poe_publicacion          VARCHAR(100)  NULL,       -- 'POE 03-10-2011'
  legislatura              VARCHAR(100)  NULL,       -- 'XVI Legislatura'
  fecha_publicacion_poe    DATE          NULL,
  -- Notas
  nota_cambio              NVARCHAR(MAX) NULL,
  es_vigente               AS (CASE WHEN fecha_fin_exacta IS NULL OR fecha_fin_exacta >= CAST(GETDATE() AS DATE)
                               THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END) PERSISTED,
  -- Auditoría
  activo                   BIT           NOT NULL CONSTRAINT DF_th_activo DEFAULT 1,
  fecha_creacion           DATETIME2(0)  NOT NULL CONSTRAINT DF_th_fcreac DEFAULT GETDATE(),
  fecha_modificacion       DATETIME2(0)  NULL,
  id_usuario_creacion      INT           NULL,
  id_usuario_modificacion  INT           NULL,
  CONSTRAINT PK_cat_tasa_historica PRIMARY KEY (id_tasa),
  CONSTRAINT UQ_tasa_municipio_inicio UNIQUE (clave_municipio, ejercicio_fiscal_inicio)
);
GO
CREATE INDEX IX_tasa_municipio_vigente ON isabi.cat_tasa_historica (clave_municipio, es_vigente, ejercicio_fiscal_inicio DESC);
CREATE INDEX IX_tasa_ejercicio        ON isabi.cat_tasa_historica (ejercicio_fiscal_inicio, clave_municipio);
GO

-- ══════════════════════════════════════════════════════════════════
-- SECCIÓN 3: SEED — cat_tasa_historica (Tulum + referencia QRoo)
-- ══════════════════════════════════════════════════════════════════

-- ────────────────────────────────────────────────────────────────
-- TULUM — Período 1: 2000-2019 (2.00% sin adicional)
-- Fundamento: Ley de Hacienda Municipios QRoo Arts. 29-34 hasta
--             oct. 2011, luego Ley ISABI QRoo Art. 9
-- ────────────────────────────────────────────────────────────────
INSERT INTO isabi.cat_tasa_historica (
  clave_municipio, nombre_municipio, clave_estado,
  ejercicio_fiscal_inicio, ejercicio_fiscal_fin,
  fecha_inicio_exacta, fecha_fin_exacta,
  tasa_isabi_pct, tasa_adicional_pct,
  nombre_ley, articulo_tasa, numero_decreto, poe_publicacion,
  legislatura, fecha_publicacion_poe,
  nota_cambio
) VALUES (
  'TULUM', 'Municipio de Tulum', '23',
  2000, 2019,
  '2000-01-01', '2019-12-31',
  2.0000, 0.0000,
  'Ley de Hacienda de los Municipios del Estado de QRoo (Arts. 29-34) '
  + '/ Ley del ISABI de los Municipios del Estado de Quintana Roo',
  'Art. 29-34 (hasta 2011) / Art. 9 (2011-2019)',
  'Decreto 024 (Ley ISABI) / Decreto 148 (reforma)',
  'POE 15-12-1997 (original) / POE 03-10-2011 / POE 30-10-2012',
  'XIV Legislatura',
  '2011-10-03',
  'Tulum quedaba sujeto a la Ley ISABI estatal. No contaba con '
  + 'capítulo propio en su Ley de Hacienda. Tasa fija 2% para todos '
  + 'los municipios de QRoo. Sin impuesto adicional de fomento turístico.'
);

-- ────────────────────────────────────────────────────────────────
-- TULUM — Período 2: 2020-2024 (3.00% + 10% adicional = 3.30% efectivo)
-- Fundamento: Ley de Hacienda del Municipio de Tulum,
--             Cap. VI Arts. 46 Bis a 46 Undécies
-- ────────────────────────────────────────────────────────────────
INSERT INTO isabi.cat_tasa_historica (
  clave_municipio, nombre_municipio, clave_estado,
  ejercicio_fiscal_inicio, ejercicio_fiscal_fin,
  fecha_inicio_exacta, fecha_fin_exacta,
  tasa_isabi_pct, tasa_adicional_pct,
  nombre_ley, articulo_tasa, numero_decreto, poe_publicacion,
  legislatura, fecha_publicacion_poe,
  nota_cambio
) VALUES (
  'TULUM', 'Municipio de Tulum', '23',
  2020, 2024,
  '2020-01-01', '2024-12-31',
  3.0000, 10.0000,
  'Ley de Hacienda del Municipio de Tulum, Capítulo VI '
  + '"Del Impuesto Sobre Adquisición de Bienes Inmuebles"',
  'Art. 46 Quinquies (tasa 3%) / Art. 46 Undécies (adicional 10%)',
  'Decreto 023',
  'POE 27-12-2019',
  'XVI Legislatura',
  '2019-12-27',
  'Tulum crea su propio capítulo ISABI dentro de su Ley de Hacienda '
  + '(Arts. 46 Bis al 46 Undécies), dejando de quedar sujeto a la Ley '
  + 'ISABI estatal. Se aprueba en la misma sesión que Solidaridad '
  + '(Decreto 034). Se introduce el 10%% adicional para fomento '
  + 'turístico, DIF, desarrollo social y cultura. '
  + 'Tasa efectiva total: 3.30%% sobre la base gravable.'
);

-- ────────────────────────────────────────────────────────────────
-- TULUM — Período 3: 2025-VIGENTE (4.00% + 10% adicional = 4.40% efectivo)
-- Fundamento: Ley de Hacienda del Municipio de Tulum, Art. 50
-- ────────────────────────────────────────────────────────────────
INSERT INTO isabi.cat_tasa_historica (
  clave_municipio, nombre_municipio, clave_estado,
  ejercicio_fiscal_inicio, ejercicio_fiscal_fin,
  fecha_inicio_exacta, fecha_fin_exacta,
  tasa_isabi_pct, tasa_adicional_pct,
  nombre_ley, articulo_tasa, numero_decreto, poe_publicacion,
  legislatura, fecha_publicacion_poe,
  nota_cambio
) VALUES (
  'TULUM', 'Municipio de Tulum', '23',
  2025, NULL,         -- NULL = vigente sin fecha de término conocida
  '2025-01-01', NULL,
  4.0000, 10.0000,
  'Ley de Hacienda del Municipio de Tulum',
  'Art. 50',
  NULL,
  'POE 09-12-2024',
  'XVIII Legislatura',
  '2024-12-09',
  'Tulum sube de 3%% a 4%%, siendo la tasa más alta de la Riviera Maya '
  + 'junto con Playa del Carmen (que alcanzó el 4%% el 10-dic-2025). '
  + 'El adicional turístico del 10%% sobre el ISABI se mantiene. '
  + 'Tasa efectiva total: 4.40%% sobre la base gravable. '
  + 'Es la tasa VIGENTE para el ejercicio fiscal 2026.'
);

-- ────────────────────────────────────────────────────────────────
-- REFERENCIA: Benito Juárez (Cancún) — para comparativo y SIIM
-- ────────────────────────────────────────────────────────────────
INSERT INTO isabi.cat_tasa_historica (
  clave_municipio, nombre_municipio, clave_estado,
  ejercicio_fiscal_inicio, ejercicio_fiscal_fin,
  fecha_inicio_exacta, fecha_fin_exacta,
  tasa_isabi_pct, tasa_adicional_pct,
  nombre_ley, articulo_tasa, poe_publicacion,
  legislatura, fecha_publicacion_poe, nota_cambio
) VALUES
('BJ', 'Benito Juárez (Cancún)', '23',
  2000, 2016, '2000-01-01', '2016-12-31',
  2.0000, 0.0000,
  'Ley ISABI Municipios QRoo, Art. 9',
  'Art. 9', 'POE 03-10-2011', 'XIV Legislatura', '2011-10-03',
  'Tasa base 2%% bajo Ley ISABI estatal. Sin adicional turístico.'),

('BJ', 'Benito Juárez (Cancún)', '23',
  2017, NULL, '2017-01-01', NULL,
  3.0000, 10.0000,
  'Ley de Hacienda del Municipio de Benito Juárez, Cap. I BIS',
  'Art. 23 Quinquies', 'POE 21-12-2016', 'XV Legislatura', '2016-12-21',
  'Primer municipio QRoo en subir a 3%%. '
  + 'Se introduce el 10%% adicional turístico (Art. 46-BIS). '
  + 'Vigente desde 01-ene-2017 a la fecha (no ha subido a 4%% aún).');

-- ────────────────────────────────────────────────────────────────
-- REFERENCIA: Solidaridad / Playa del Carmen
-- ────────────────────────────────────────────────────────────────
INSERT INTO isabi.cat_tasa_historica (
  clave_municipio, nombre_municipio, clave_estado,
  ejercicio_fiscal_inicio, ejercicio_fiscal_fin,
  fecha_inicio_exacta, fecha_fin_exacta,
  tasa_isabi_pct, tasa_adicional_pct,
  nombre_ley, articulo_tasa, numero_decreto, poe_publicacion,
  legislatura, fecha_publicacion_poe, nota_cambio
) VALUES
('SOLIDARIDAD', 'Solidaridad / Playa del Carmen', '23',
  2000, 2019, '2000-01-01', '2019-12-31',
  2.0000, 0.0000,
  'Ley ISABI Municipios QRoo, Art. 9',
  'Art. 9', NULL, 'POE 03-10-2011', 'XIV Legislatura', '2011-10-03',
  'Tasa 2%% bajo ley estatal. Sin adicional turístico.'),

('SOLIDARIDAD', 'Solidaridad / Playa del Carmen', '23',
  2020, 2025, '2020-01-01', '2025-12-09',
  3.0000, 10.0000,
  'Ley de Hacienda del Municipio de Solidaridad, Cap. ISABI',
  'Art. 23 Quinquies', 'Decreto 034', 'POE 27-12-2019', 'XVI Legislatura', '2019-12-27',
  'Solidaridad crea su propio capítulo ISABI al 3%% + 10%% adicional, '
  + 'en el mismo decreto legislativo que Tulum.'),

('SOLIDARIDAD', 'Solidaridad / Playa del Carmen', '23',
  2026, NULL, '2025-12-10', NULL,
  4.0000, 10.0000,
  'Ley de Hacienda del Municipio de Playa del Carmen',
  'Art. 23 Quinquies', NULL, 'POE 10-12-2025', 'XVIII Legislatura', '2025-12-10',
  'El municipio cambia de nombre a "Playa del Carmen" y sube a 4%% '
  + '+ 10%% adicional. Tasa efectiva 4.40%%. Vigente desde 10-dic-2025.');

-- ────────────────────────────────────────────────────────────────
-- REFERENCIA: Otros municipios QRoo (Chetumal, Isla Mujeres, etc.)
-- Siguen bajo Ley ISABI estatal, tasa 2% sin adicional
-- ────────────────────────────────────────────────────────────────
INSERT INTO isabi.cat_tasa_historica (
  clave_municipio, nombre_municipio, clave_estado,
  ejercicio_fiscal_inicio, ejercicio_fiscal_fin,
  fecha_inicio_exacta, fecha_fin_exacta,
  tasa_isabi_pct, tasa_adicional_pct,
  nombre_ley, articulo_tasa, poe_publicacion,
  legislatura, fecha_publicacion_poe, nota_cambio
) VALUES
('OTROS_QRoo',
  'Othón P. Blanco / Isla Mujeres / FCP / JMM / Lázaro Cárdenas / Bacalar', '23',
  2000, NULL, '2000-01-01', NULL,
  2.0000, 0.0000,
  'Ley ISABI de los Municipios del Estado de Quintana Roo, Art. 9',
  'Art. 9', 'POE 03-10-2011',
  'XIV Legislatura (Ley) / XVI Leg. (ref. Art.1 incluye Bacalar)',
  '2011-10-03',
  'Estos municipios no cuentan con capítulo propio en su Ley de '
  + 'Hacienda. Se rigen por la Ley ISABI estatal al 2%% sin adicional '
  + 'turístico. Bacalar fue incorporado al Art. 1 mediante reforma '
  + 'aprobada el 15-dic-2021 (XVI Legislatura).');
GO

-- ══════════════════════════════════════════════════════════════════
-- SECCIÓN 4: SEED — cat_tipo_operacion (25 tipos)
-- ══════════════════════════════════════════════════════════════════

-- ── GRUPO 1: ONEROSAS ────────────────────────────────────────────
INSERT INTO isabi.cat_tipo_operacion (
  clave,nombre,nombre_corto,descripcion,fundamento_legal,articulo_ley,
  genera_isabi,genera_adicional_turismo,base_calculo,aplica_factor_50pct,
  dias_pago_habiles,momento_causacion,
  requiere_escritura_publica,requiere_avaluo,requiere_predial_vigente,
  requiere_acta_defuncion,requiere_declaratoria_hered,requiere_const_zofemat,
  puede_ser_exento,condicion_exencion,
  actualiza_propietario_catastro,genera_historial_propietario,
  nombre_parte_transmite,nombre_parte_adquiere,grupo,es_onerosa,orden_display
) VALUES
('COMPRAVENTA','Compraventa de Bien Inmueble','Compraventa',
 'Contrato por el cual el vendedor transmite la propiedad del inmueble al comprador a cambio de un precio cierto en dinero. Acto traslativo más frecuente en Tulum.',
 'Art. 5-a Ley ISABI QRoo; Art. 11 Ley ISABI QRoo; Arts. 46 Bis Ley Hac. Tulum','Art. 5-a',
 1,1,'VALOR_MAS_ALTO',0,15,
 'A los 15 días hábiles siguientes a la firma de escritura pública.',
 1,1,1,0,0,0,0,NULL,1,1,
 'Vendedor / Enajenante','Comprador / Adquiriente','ONEROSA',1,10),

('COMPRAVENTA_RESERVA_DOMINIO','Compraventa con Reserva de Dominio o Sujeta a Condición','CV Reserva Dominio',
 'Compraventa en que el vendedor conserva la propiedad hasta que el comprador cumpla condiciones (generalmente el pago total). El ISABI se causa desde la celebración del contrato. Muy frecuente en preventas turísticas en Tulum.',
 'Art. 5-b Ley ISABI QRoo; Art. 11-VI','Art. 5-b',
 1,1,'VALOR_MAS_ALTO',0,15,
 'A los 15 días hábiles desde la celebración del contrato, aunque no se haya elevado a escritura.',
 1,1,1,0,0,0,0,NULL,1,1,
 'Vendedor / Promitente vendedor','Comprador / Promitente comprador','ONEROSA',1,11),

('PERMUTA','Permuta de Bien Inmueble','Permuta',
 'Contrato en que cada parte transmite un bien por otro. No interviene dinero como contraprestación principal. Cada adquiriente paga ISABI sobre el bien inmueble que recibe.',
 'Art. 5-d Ley ISABI QRoo; Arts. 2322-2331 CCF','Art. 5-d',
 1,1,'VALOR_MAS_ALTO',0,15,
 'A los 15 días hábiles desde la firma de escritura pública.',
 1,1,1,0,0,0,0,NULL,1,1,
 'Permutante (transmite)','Permutante (recibe inmueble)','ONEROSA',1,20),

('DACION_EN_PAGO','Adquisición en Dación en Pago','Dación en Pago',
 'El deudor entrega un bien inmueble al acreedor para saldar una obligación. La base es el avalúo comercial practicado a partir de la fecha del convenio, no de la escritura.',
 'Art. 5-j y Art. 10-IV Ley ISABI QRoo; Art. 2095 CCF','Art. 5-j / Art. 10-IV',
 1,1,'AVALUO_COMERCIAL',0,15,
 'A los 15 días hábiles desde la celebración del convenio de dación (no desde la escritura).',
 1,1,1,0,0,0,0,NULL,1,1,
 'Deudor / Dador','Acreedor','ONEROSA',1,30),

('CESION_DERECHOS_CONTRATO','Cesión de Derechos de Contrato de Promesa / Contrato Privado','Cesión de Derechos',
 'Transmisión de derechos sobre inmueble derivados de promesa o contrato privado. Muy común en preventa de desarrollos en Tulum. El fraccionador debe remitir copia a Tesorería en 30 días.',
 'Art. 13 Ley ISABI QRoo; Art. 5-a','Art. 13',
 1,1,'VALOR_MAS_ALTO',0,15,
 'Al elevarse a escritura pública o al inscribirse en el RPP.',
 0,1,1,0,0,0,0,NULL,0,0,
 'Cedente (promitente comprador original)','Cesionario','ONEROSA',1,35);

-- ── GRUPO 2: GRATUITAS ────────────────────────────────────────────
INSERT INTO isabi.cat_tipo_operacion (
  clave,nombre,nombre_corto,descripcion,fundamento_legal,articulo_ley,
  genera_isabi,genera_adicional_turismo,base_calculo,aplica_factor_50pct,
  dias_pago_habiles,momento_causacion,
  requiere_escritura_publica,requiere_avaluo,requiere_predial_vigente,
  requiere_acta_defuncion,requiere_declaratoria_hered,requiere_const_zofemat,
  puede_ser_exento,condicion_exencion,
  actualiza_propietario_catastro,genera_historial_propietario,
  nombre_parte_transmite,nombre_parte_adquiere,grupo,es_onerosa,orden_display
) VALUES
('DONACION','Donación de Bien Inmueble','Donación',
 'El donante transmite gratuitamente el inmueble al donatario. Aunque es gratuita, causa ISABI igual que compraventa. El donatario paga sobre el valor del bien.',
 'Art. 5-a Ley ISABI QRoo (adquisición general); Arts. 2332-2360 CCF','Art. 5-a',
 1,1,'VALOR_MAS_ALTO',0,15,
 'A los 15 días hábiles desde la firma de la escritura pública de donación.',
 1,1,1,0,0,0,
 1,'Donaciones entre cónyuge, concubino/a o descendientes en primer grado pueden beneficiarse de condiciones especiales conforme al Código Civil de QRoo.',
 1,1,'Donante','Donatario','GRATUITA',0,40),

('HERENCIA','Transmisión por Herencia Testamentaria','Herencia',
 'Transmisión de la propiedad a través de sucesión testamentaria. El impuesto se causa al momento de la adjudicación formal o a los 3 años del fallecimiento si no hay adjudicación.',
 'Art. 5-h y Art. 10-II Ley ISABI QRoo; Arts. 1281 et seq. CCF','Art. 5-h / Art. 10-II',
 1,1,'VALOR_MAS_ALTO',0,15,
 'A los 15 días hábiles desde la adjudicación escriturada, o a 3 años del fallecimiento si no se escrituró.',
 1,1,1,1,1,0,0,NULL,1,1,
 'De Cujus / Causante (fallecido)','Heredero / Legatario','GRATUITA',0,50),

('LEGADO','Transmisión por Legado','Legado',
 'El testador dispone que un bien específico pase a una persona determinada (legatario), independientemente de los herederos universales.',
 'Art. 5-h y Art. 10-II Ley ISABI QRoo; Arts. 1391 et seq. CCF','Art. 5-h',
 1,1,'VALOR_MAS_ALTO',0,15,
 'A los 15 días hábiles desde la adjudicación formal del legado protocolizada ante notario.',
 1,1,1,1,1,0,0,NULL,1,1,
 'De Cujus / Testador (fallecido)','Legatario','GRATUITA',0,51),

('CESION_DERECHOS_HEREDITARIOS','Cesión de Derechos Hereditarios','Cesión Hereditaria',
 'Heredero transmite sus derechos sobre la herencia a un tercero antes de la adjudicación formal. Genera dos hechos imponibles: el del heredero-cedente y el del cesionario.',
 'Art. 10-II párrafo 2 Ley ISABI QRoo','Art. 10-II (párrafo 2)',
 1,1,'VALOR_MAS_ALTO',0,15,
 'A los 15 días hábiles desde la cesión. Se causan DOS impuestos: cedente y cesionario.',
 1,1,1,1,1,0,0,NULL,1,1,
 'Heredero cedente','Cesionario (adquiriente de derechos hereditarios)','ONEROSA',1,52);

-- ── GRUPO 3: JUDICIALES ──────────────────────────────────────────
INSERT INTO isabi.cat_tipo_operacion (
  clave,nombre,nombre_corto,descripcion,fundamento_legal,articulo_ley,
  genera_isabi,genera_adicional_turismo,base_calculo,aplica_factor_50pct,
  dias_pago_habiles,momento_causacion,
  requiere_escritura_publica,requiere_avaluo,requiere_predial_vigente,
  requiere_acta_defuncion,requiere_declaratoria_hered,requiere_const_zofemat,
  requiere_resolucion_judicial,
  puede_ser_exento,condicion_exencion,
  actualiza_propietario_catastro,genera_historial_propietario,
  nombre_parte_transmite,nombre_parte_adquiere,grupo,es_onerosa,orden_display
) VALUES
('REMATE_JUDICIAL','Adquisición por Remate Judicial','Remate Judicial',
 'Adquisición en subasta pública ordenada por un juez derivada de proceso judicial (ejecutivo, hipotecario, mercantil, familiar). Se causa al inscribirse en el RPP.',
 'Art. 5-c y Art. 10-V Ley ISABI QRoo','Art. 5-c / Art. 10-V',
 1,1,'VALOR_MAS_ALTO',0,15,
 'A los 15 días hábiles desde la inscripción del remate en el RPP.',
 1,1,1,0,0,0,1,0,NULL,1,1,
 'Ejecutado / Deudor hipotecario','Postor ganador / Rematante','JUDICIAL',1,60),

('REMATE_ADMINISTRATIVO','Adquisición por Remate Administrativo','Remate Administrativo',
 'Adquisición en subasta derivada de procedimiento administrativo de ejecución fiscal (SAT, IMSS, municipio u otra autoridad).',
 'Art. 5-c y Art. 10-V Ley ISABI QRoo','Art. 5-c / Art. 10-V',
 1,1,'VALOR_MAS_ALTO',0,15,
 'A los 15 días hábiles desde la inscripción en el RPP.',
 1,1,1,0,0,0,1,0,NULL,1,1,
 'Deudor fiscal / Ejecutado','Postor ganador','JUDICIAL',1,61),

('ADJUDICACION_SUCESORIA','Adjudicación por Remate en Sucesión','Adjudicación Sucesoria',
 'Adquisición de bienes en proceso sucesorio intestamentario o testamentario en que un juzgado declara herederos y adjudica bienes.',
 'Art. 5-c y Art. 10-II Ley ISABI QRoo','Art. 5-c / Art. 10-II',
 1,1,'VALOR_MAS_ALTO',0,15,
 'A los 15 días hábiles desde la adjudicación o a 3 años del fallecimiento.',
 1,1,1,1,1,0,1,0,NULL,1,1,
 'De Cujus / Causante','Heredero declarado judicialmente','JUDICIAL',0,62),

('PRESCRIPCION_POSITIVA','Adquisición por Prescripción Positiva (Usucapión)','Usucapión',
 'Adquisición del dominio por posesión continua, pacífica, pública y de buena fe durante el tiempo señalado en ley. Requiere sentencia judicial.',
 'Art. 10-V Ley ISABI QRoo; Arts. 1135 et seq. CCF','Art. 10-V',
 1,1,'AVALUO_COMERCIAL',0,15,
 'A los 15 días hábiles desde la inscripción de la sentencia en el RPP.',
 1,1,1,0,0,0,1,0,NULL,1,1,
 'Propietario registral (pierde el bien)','Poseedor / Usucapiente','JUDICIAL',0,63);

-- ── GRUPO 4: FIDEICOMISO ─────────────────────────────────────────
INSERT INTO isabi.cat_tipo_operacion (
  clave,nombre,nombre_corto,descripcion,fundamento_legal,articulo_ley,
  genera_isabi,genera_adicional_turismo,base_calculo,aplica_factor_50pct,
  dias_pago_habiles,momento_causacion,
  requiere_escritura_publica,requiere_avaluo,requiere_predial_vigente,
  requiere_acta_defuncion,requiere_declaratoria_hered,requiere_const_zofemat,
  requiere_contrato_fideicom,
  puede_ser_exento,condicion_exencion,
  actualiza_propietario_catastro,genera_historial_propietario,
  nombre_parte_transmite,nombre_parte_adquiere,grupo,es_onerosa,orden_display,
  notas_internas
) VALUES
('FIDEICOMISO_CONSTITUCION','Constitución de Fideicomiso Traslativo de Dominio','Fideicomiso Constitución',
 'Transmisión del inmueble que realiza el fideicomitente a la institución fiduciaria al constituirse el fideicomiso. Mecanismo obligatorio para que extranjeros adquieran propiedades en la zona costera restringida (50 km de la costa). Es el acto MÁS FRECUENTE en Tulum para compradores extranjeros.',
 'Art. 5-e y Art. 10-III Ley ISABI QRoo; Art. 27 CPEUM; Ley de Inversión Extranjera Art. 11','Art. 5-e / Art. 10-III',
 1,1,'VALOR_MAS_ALTO',0,15,
 'Cuando se realicen los supuestos de enajenación en términos del Código Fiscal Municipal de QRoo.',
 1,1,1,0,0,0,1,0,NULL,1,1,
 'Fideicomitente (aporta el inmueble)','Institución Fiduciaria (Banco)','FIDEICOMISO',1,70,
 'Requiere autorización de la SRE. Bancos habituales en Tulum: BBVA, Scotiabank, Citibanamex, HSBC, Banorte. Vigencia 50 años renovables.'),

('FIDEICOMISO_CUMPLIMIENTO','Transmisión por la Fiduciaria en Cumplimiento del Fideicomiso','Fideicomiso Cumplimiento',
 'La institución fiduciaria transmite la propiedad al fideicomisario o a un tercero en cumplimiento de los fines del fideicomiso.',
 'Art. 5-f y Art. 10-III Ley ISABI QRoo','Art. 5-f / Art. 10-III',
 1,1,'VALOR_MAS_ALTO',0,15,
 'Cuando se realicen los supuestos de enajenación conforme al Código Fiscal Municipal.',
 1,1,1,0,0,0,1,0,NULL,1,1,
 'Institución Fiduciaria (Banco)','Fideicomisario / Tercero designado','FIDEICOMISO',1,71,NULL),

('CESION_DERECHOS_FIDEICOMISO','Cesión de Derechos de Fideicomisarios (Sustitución)','Cesión Fideicomisaria',
 'Sustitución de un fideicomitente o fideicomisario por cualquier motivo. Es el mecanismo habitual para vender una propiedad que está en fideicomiso sin extinguirlo. Muy común en Tulum para venta de propiedades de extranjeros.',
 'Art. 5-g Ley ISABI QRoo (reformado POE 30-10-2012)','Art. 5-g',
 1,1,'VALOR_MAS_ALTO',0,15,
 'A los 15 días hábiles desde la formalización de la sustitución ante la fiduciaria.',
 1,1,1,0,0,0,1,0,NULL,1,1,
 'Fideicomisario original (cedente)','Nuevo Fideicomisario (cesionario)','FIDEICOMISO',1,72,
 'No se extingue ni reconstituye el fideicomiso. El banco continúa como fiduciaria.');

-- ── GRUPO 5: ESPECIALES (Usufructo, Nuda propiedad, Leasing) ─────
INSERT INTO isabi.cat_tipo_operacion (
  clave,nombre,nombre_corto,descripcion,fundamento_legal,articulo_ley,
  genera_isabi,genera_adicional_turismo,base_calculo,aplica_factor_50pct,
  dias_pago_habiles,momento_causacion,
  requiere_escritura_publica,requiere_avaluo,requiere_predial_vigente,
  puede_ser_exento,condicion_exencion,
  actualiza_propietario_catastro,genera_historial_propietario,
  nombre_parte_transmite,nombre_parte_adquiere,grupo,es_onerosa,orden_display
) VALUES
('USUFRUCTO','Constitución o Adquisición de Usufructo','Usufructo',
 'Derecho real que otorga usar y disfrutar un inmueble ajeno. La base del ISABI es el 50%% del valor pleno. Si es temporal, también se paga al extinguirse.',
 'Art. 10-I y Art. 8 párrafo 4 Ley ISABI QRoo; Arts. 980 et seq. CCF','Art. 10-I / Art. 8',
 1,1,'CINCUENTA_PCT_VALOR',1,15,
 'A los 15 días hábiles desde la constitución. Si es temporal, también al extinguirse.',
 1,1,1,0,NULL,0,1,
 'Nudo propietario / Constituyente','Usufructuario','ESPECIAL',1,80),

('NUDA_PROPIEDAD','Adquisición de Nuda Propiedad','Nuda Propiedad',
 'Titularidad del inmueble sin el derecho de uso y disfrute. Base del ISABI: 50%% del valor pleno.',
 'Art. 8 párrafo 4 Ley ISABI QRoo; Arts. 980 et seq. CCF','Art. 8',
 1,1,'CINCUENTA_PCT_VALOR',1,15,
 'A los 15 días hábiles desde la escritura de transmisión de la nuda propiedad.',
 1,1,1,0,NULL,1,1,
 'Propietario pleno','Adquiriente de nuda propiedad','ESPECIAL',1,81),

('ARRENDAMIENTO_FINANCIERO_CESION','Cesión de Derechos de Arrendamiento Financiero sobre Inmueble','Leasing Inmobiliario',
 'Cesión de derechos derivados de contrato de arrendamiento financiero (leasing) o adquisición del bien por persona distinta al arrendatario original.',
 'Art. 5-i Ley ISABI QRoo; Arts. 408 et seq. LGTOC','Art. 5-i',
 1,1,'VALOR_MAS_ALTO',0,15,
 'A los 15 días hábiles desde la formalización de la cesión.',
 1,1,1,0,NULL,1,1,
 'Arrendatario cedente / Arrendador financiero','Cesionario / Nuevo adquiriente','ESPECIAL',1,90);

-- ── GRUPO 6: CORPORATIVAS ────────────────────────────────────────
INSERT INTO isabi.cat_tipo_operacion (
  clave,nombre,nombre_corto,descripcion,fundamento_legal,articulo_ley,
  genera_isabi,genera_adicional_turismo,base_calculo,aplica_factor_50pct,
  dias_pago_habiles,momento_causacion,
  requiere_escritura_publica,requiere_avaluo,requiere_predial_vigente,
  requiere_acta_defuncion,requiere_declaratoria_hered,requiere_const_zofemat,
  requiere_acta_asamblea,
  puede_ser_exento,condicion_exencion,
  actualiza_propietario_catastro,genera_historial_propietario,
  nombre_parte_transmite,nombre_parte_adquiere,grupo,es_onerosa,orden_display
) VALUES
('APORTACION_PERSONA_MORAL','Aportación de Bien Inmueble a Persona Moral','Aportación a Sociedad',
 'Un socio aporta un bien inmueble al patrimonio de una sociedad a cambio de acciones o partes sociales.',
 'Art. 5-a Ley ISABI QRoo; LGSM Arts. 11, 89','Art. 5-a',
 1,1,'VALOR_MAS_ALTO',0,15,
 'A los 15 días hábiles desde la escritura pública de constitución o aumento de capital.',
 1,1,1,0,0,0,1,0,NULL,1,1,
 'Socio aportante','Sociedad adquiriente','CORPORATIVA',1,100),

('FUSION_ESCISION','Transmisión por Fusión o Escisión de Sociedades','Fusión / Escisión',
 'Transmisión de inmuebles como consecuencia de fusión o escisión de personas morales.',
 'Art. 5-a Ley ISABI QRoo; LGSM Arts. 222 et seq. y 228 BIS','Art. 5-a',
 1,1,'VALOR_MAS_ALTO',0,15,
 'A los 15 días hábiles desde la inscripción de la fusión/escisión en el RPP.',
 1,1,1,0,0,0,1,
 1,'Posible exención bajo Art. 14-B CFF si se cumplen requisitos de reestructura corporativa.',
 1,1,'Sociedad fusionada / Escindente','Sociedad fusionante / Escindida','CORPORATIVA',1,101);

-- ── GRUPO 7: EXENTAS ─────────────────────────────────────────────
INSERT INTO isabi.cat_tipo_operacion (
  clave,nombre,nombre_corto,descripcion,fundamento_legal,articulo_ley,
  genera_isabi,genera_adicional_turismo,base_calculo,aplica_factor_50pct,
  dias_pago_habiles,momento_causacion,
  requiere_escritura_publica,requiere_avaluo,requiere_predial_vigente,
  puede_ser_exento,condicion_exencion,exento_por_ley,
  actualiza_propietario_catastro,genera_historial_propietario,
  nombre_parte_transmite,nombre_parte_adquiere,grupo,es_onerosa,orden_display
) VALUES
('EXENTO_ORGANISMO_VIVIENDA','Adquisición por Organismo de Vivienda Estatal/Municipal (Exento)','Organismo Vivienda',
 'Adquisición por dependencias/entidades u organismos estatales o municipales para programas de vivienda. También cuando el beneficiario no sea propietario de otro inmueble y destine el bien a casa habitación.',
 'Art. 7 Ley ISABI QRoo','Art. 7',
 0,0,'SIN_BASE',0,0,'No aplica — operación exenta.',
 1,1,1,
 1,'Solo aplica cuando adquiere: (a) dependencia/entidad para programas de vivienda; O (b) beneficiario sin otro inmueble que lo destine a casa habitación.',
 1,1,1,'Diversas fuentes','Organismo de vivienda / Beneficiario programa','EXENTA',0,110),

('VIVIENDA_INTERES_SOCIAL','Compraventa de Vivienda de Interés Social o Popular (con deducible)','VIS / VIP',
 'Compraventa cuyo valor no excede los topes de la ley. Zona C (Tulum): deducible de 10-25 días de SMG × 365 antes de calcular la base del ISABI.',
 'Art. 12 Ley ISABI QRoo; Art. 4-BIS Ley Hac. Municipios QRoo','Art. 12',
 1,1,'VALOR_MAS_ALTO',0,15,
 'A los 15 días hábiles desde la escritura. Base reducida por el deducible de la Zona C.',
 1,1,1,
 1,'VIP Zona C: deducible = 25 × SMG diario QRoo × 365. VIS Zona C: 15 × SMG × 365. Si base − deducible ≤ 0, no se paga.',
 0,1,1,'Desarrollador / Vendedor','Comprador persona física','ESPECIAL',1,120);

-- ── GRUPO 8: ESPECIALES TULUM / ZOFEMAT ──────────────────────────
INSERT INTO isabi.cat_tipo_operacion (
  clave,nombre,nombre_corto,descripcion,fundamento_legal,articulo_ley,
  genera_isabi,genera_adicional_turismo,base_calculo,aplica_factor_50pct,
  dias_pago_habiles,momento_causacion,
  requiere_escritura_publica,requiere_avaluo,requiere_predial_vigente,
  requiere_acta_defuncion,requiere_declaratoria_hered,requiere_const_zofemat,
  requiere_contrato_fideicom,
  puede_ser_exento,condicion_exencion,
  actualiza_propietario_catastro,genera_historial_propietario,
  nombre_parte_transmite,nombre_parte_adquiere,grupo,es_onerosa,orden_display,
  notas_internas,documentacion_adicional
) VALUES
('COMPRAVENTA_COLINDANTE_ZOFEMAT','Compraventa Colindante con la Zona Federal Marítimo Terrestre','CV Colindante ZOFEMAT',
 'Compraventa de inmueble que colinda con la ZOFEMAT (franja de 20 m desde la línea de marea máxima) o que usa y goza de ella. Requiere documentación especial antes de escriturar. Muy frecuente en Tulum dada su costa caribeña.',
 'Art. 11-VII Ley ISABI QRoo; Ley Federal del Mar; LGBN Art. 119','Art. 11-VII',
 1,1,'VALOR_MAS_ALTO',0,15,
 'A los 15 días hábiles desde la escritura. No puede escriturarse sin documentación ZOFEMAT.',
 1,1,1,0,0,1,0,0,NULL,1,1,
 'Vendedor / Propietario costero','Comprador','ESPECIAL_TULUM',1,130,
 'Documentación adicional obligatoria: (1) Constancia uso o no uso de concesión ZOFEMAT (SEMARNAT/SEMAR). (2) Si tiene concesión: constancia no adeudo derechos ZOFEMAT. (3) Copia recibo pago Tesorería Municipal Art. 121 Ley Hac. Municipios QRoo.',
 '{"requiere_constancia_uso_zofemat":true,"requiere_constancia_no_adeudo_zofemat":true,"requiere_recibo_pago_zofemat":true}'),

('FIDEICOMISO_EXTRANJERO_ZONA_RESTRINGIDA','Fideicomiso Bancario por Persona Extranjera en Zona Restringida','Fideicomiso Extranjero',
 'Adquisición de derechos sobre inmueble en zona restringida (50 km costa o 100 km frontera) por persona extranjera a través de fideicomiso bancario. El banco es titular registral; el extranjero es fideicomisario con todos los derechos de uso y goce. Es el tipo MÁS FRECUENTE en Tulum para compradores internacionales.',
 'Art. 27 CPEUM fracc. I; Ley Inversión Extranjera Art. 11; Art. 5-e, 5-f Ley ISABI QRoo; Art. 11-VII si colinda ZOFEMAT',
 'Art. 5-e / Art. 27 CPEUM / LIE Art. 11',
 1,1,'VALOR_MAS_ALTO',0,15,
 'A los 15 días hábiles desde la escritura de constitución del fideicomiso.',
 1,1,1,0,0,1,1,0,NULL,1,1,
 'Vendedor / Fideicomitente (puede ser mexicano o extranjero)','Banco fiduciario (titular registral) / Fideicomisario (extranjero beneficiario)',
 'ESPECIAL_TULUM',1,131,
 'Requiere permiso SRE. Vigencia fideicomiso: 50 años renovables. Bancos habituales en Tulum: BBVA, Scotiabank, Citibanamex, HSBC, Banorte.',
 '{"requiere_permiso_sre":true,"vigencia_fideicomiso_anios":50,"renovable":true,"requiere_zofemat_si_colinda_costa":true}');
GO

-- ══════════════════════════════════════════════════════════════════
-- SECCIÓN 5: SP PRINCIPAL — sp_calcular_isabi
-- Integra cat_tipo_operacion + cat_tasa_historica
-- ══════════════════════════════════════════════════════════════════
CREATE PROCEDURE isabi.sp_calcular_isabi
  @id_tipo_operacion   INT,
  @clave_municipio     VARCHAR(10)    = 'TULUM',
  @ejercicio_fiscal    INT            = NULL,    -- NULL = año en curso
  @valor_operacion     DECIMAL(14,2)  = NULL,
  @valor_catastral     DECIMAL(14,2)  = NULL,
  @valor_avaluo        DECIMAL(14,2)  = NULL
AS
BEGIN
  SET NOCOUNT ON;

  -- Año de la operación
  DECLARE @anio INT = ISNULL(@ejercicio_fiscal, YEAR(GETDATE()));

  -- ── Obtener tipo de operación ──────────────────────────────────
  DECLARE
    @genera_isabi     BIT,
    @exento_por_ley   BIT,
    @aplica_50pct     BIT,
    @base_calculo_tp  VARCHAR(50),
    @nombre_tipo      VARCHAR(300),
    @clave_tipo       VARCHAR(60);

  SELECT
    @genera_isabi    = genera_isabi,
    @exento_por_ley  = exento_por_ley,
    @aplica_50pct    = aplica_factor_50pct,
    @base_calculo_tp = base_calculo,
    @nombre_tipo     = nombre,
    @clave_tipo      = clave
  FROM isabi.cat_tipo_operacion
  WHERE id_tipo_operacion = @id_tipo_operacion AND activo = 1;

  IF @clave_tipo IS NULL
  BEGIN
    RAISERROR('Tipo de operación no encontrado o inactivo.', 16, 1);
    RETURN;
  END

  -- ── Operación exenta ──────────────────────────────────────────
  IF @genera_isabi = 0 OR @exento_por_ley = 1
  BEGIN
    SELECT
      @anio               AS ejercicio_fiscal,
      @clave_municipio    AS municipio,
      @nombre_tipo        AS tipo_operacion,
      0                   AS base_gravable,
      0                   AS tasa_isabi_pct,
      0                   AS monto_isabi,
      0                   AS tasa_adicional_pct,
      0                   AS monto_adicional_turismo,
      0                   AS total_impuesto,
      'EXENTO'            AS resultado,
      'Operación exenta conforme Art. 7 Ley ISABI QRoo' AS observacion,
      NULL                AS ley_aplicable,
      NULL                AS decreto;
    RETURN;
  END

  -- ── Obtener tasa histórica vigente para el año ─────────────────
  DECLARE
    @tasa_isabi      DECIMAL(6,4),
    @tasa_adicional  DECIMAL(6,4),
    @nombre_ley      VARCHAR(300),
    @articulo_tasa   VARCHAR(100),
    @decreto         VARCHAR(100),
    @poe             VARCHAR(100);

  SELECT TOP 1
    @tasa_isabi     = tasa_isabi_pct,
    @tasa_adicional = tasa_adicional_pct,
    @nombre_ley     = nombre_ley,
    @articulo_tasa  = articulo_tasa,
    @decreto        = numero_decreto,
    @poe            = poe_publicacion
  FROM isabi.cat_tasa_historica
  WHERE clave_municipio        = @clave_municipio
    AND ejercicio_fiscal_inicio <= @anio
    AND (ejercicio_fiscal_fin    >= @anio OR ejercicio_fiscal_fin IS NULL)
    AND activo = 1
  ORDER BY ejercicio_fiscal_inicio DESC;

  IF @tasa_isabi IS NULL
  BEGIN
    RAISERROR('No se encontró tasa ISABI para el municipio y año indicados.', 16, 1);
    RETURN;
  END

  -- ── Determinar base gravable ───────────────────────────────────
  DECLARE @base_gravable DECIMAL(14,2);

  -- Para usufructo/nuda propiedad usar el mayor de los 3, luego × 50%
  SET @base_gravable = (
    SELECT MAX(v) FROM (VALUES
      (ISNULL(@valor_operacion, 0)),
      (ISNULL(@valor_catastral, 0)),
      (ISNULL(@valor_avaluo,    0))
    ) AS t(v)
  );

  DECLARE @fuente_base VARCHAR(30) =
    CASE
      WHEN @base_gravable = ISNULL(@valor_operacion, 0) THEN 'precio_pactado'
      WHEN @base_gravable = ISNULL(@valor_avaluo,    0) THEN 'avaluo_bancario'
      ELSE 'valor_catastral'
    END;

  -- Para Dación en Pago, base solo es avalúo comercial
  IF @base_calculo_tp = 'AVALUO_COMERCIAL'
    SET @base_gravable = ISNULL(@valor_avaluo, @base_gravable);

  -- Factor 50% para usufructo / nuda propiedad
  IF @aplica_50pct = 1
    SET @base_gravable = @base_gravable * 0.5;

  -- ── Calcular importes ─────────────────────────────────────────
  DECLARE @monto_isabi     DECIMAL(14,2) = ROUND(@base_gravable * @tasa_isabi / 100.0, 2);
  DECLARE @monto_adicional DECIMAL(14,2) = ROUND(@monto_isabi   * @tasa_adicional / 100.0, 2);
  DECLARE @total           DECIMAL(14,2) = @monto_isabi + @monto_adicional;
  DECLARE @tasa_ef         DECIMAL(8,4)  = ROUND(@total * 100.0 / NULLIF(@base_gravable, 0), 4);

  -- ── Resultado ─────────────────────────────────────────────────
  SELECT
    @anio                     AS ejercicio_fiscal,
    @clave_municipio          AS municipio,
    @nombre_tipo              AS tipo_operacion,
    @base_gravable            AS base_gravable,
    @fuente_base              AS fuente_base_gravable,
    CASE WHEN @aplica_50pct=1 THEN 'Sí — 50%% del valor pleno' ELSE 'No' END AS factor_50pct,
    @tasa_isabi               AS tasa_isabi_pct,
    @monto_isabi              AS monto_isabi,
    @tasa_adicional           AS tasa_adicional_pct,
    @monto_adicional          AS monto_adicional_turismo,
    @total                    AS total_impuesto,
    @tasa_ef                  AS tasa_efectiva_pct,
    'CALCULADO'               AS resultado,
    @nombre_ley               AS ley_aplicable,
    ISNULL(@articulo_tasa,'') AS articulo,
    ISNULL(@decreto,'')       AS decreto,
    @poe                      AS poe_publicacion;
END;
GO

-- SP auxiliar: obtener tasa vigente de un municipio en un año
CREATE PROCEDURE isabi.sp_tasa_vigente
  @clave_municipio  VARCHAR(10),
  @ejercicio_fiscal INT = NULL
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @anio INT = ISNULL(@ejercicio_fiscal, YEAR(GETDATE()));

  SELECT TOP 1
    clave_municipio, nombre_municipio,
    ejercicio_fiscal_inicio, ejercicio_fiscal_fin,
    fecha_inicio_exacta, fecha_fin_exacta,
    tasa_isabi_pct, tasa_adicional_pct, tasa_efectiva_pct,
    nombre_ley, articulo_tasa, numero_decreto, poe_publicacion,
    es_vigente
  FROM isabi.cat_tasa_historica
  WHERE clave_municipio        = @clave_municipio
    AND ejercicio_fiscal_inicio <= @anio
    AND (ejercicio_fiscal_fin    >= @anio OR ejercicio_fiscal_fin IS NULL)
    AND activo = 1
  ORDER BY ejercicio_fiscal_inicio DESC;
END;
GO

-- SP auxiliar: historial completo de tasas de un municipio
CREATE PROCEDURE isabi.sp_historial_tasas
  @clave_municipio VARCHAR(10) = 'TULUM'
AS
BEGIN
  SET NOCOUNT ON;
  SELECT
    ejercicio_fiscal_inicio, ejercicio_fiscal_fin,
    fecha_inicio_exacta, fecha_fin_exacta,
    tasa_isabi_pct, tasa_adicional_pct, tasa_efectiva_pct,
    nombre_ley, articulo_tasa, numero_decreto, poe_publicacion,
    legislatura, nota_cambio, es_vigente
  FROM isabi.cat_tasa_historica
  WHERE clave_municipio = @clave_municipio AND activo = 1
  ORDER BY ejercicio_fiscal_inicio ASC;
END;
GO

-- ══════════════════════════════════════════════════════════════════
-- SECCIÓN 6: VISTAS
-- ══════════════════════════════════════════════════════════════════

-- Vista operativa con todos los tipos activos
CREATE VIEW isabi.v_tipos_operacion_activos AS
SELECT
  id_tipo_operacion, clave, nombre, nombre_corto, grupo, es_onerosa,
  genera_isabi, genera_adicional_turismo, aplica_factor_50pct,
  base_calculo, dias_pago_habiles, puede_ser_exento, exento_por_ley,
  requiere_avaluo, requiere_acta_defuncion, requiere_declaratoria_hered,
  requiere_const_zofemat, requiere_contrato_fideicom,
  requiere_resolucion_judicial, requiere_acta_asamblea,
  nombre_parte_transmite, nombre_parte_adquiere, momento_causacion,
  orden_display
FROM isabi.cat_tipo_operacion
WHERE activo = 1;
GO

-- Vista selector para frontend (formulario ISABI)
CREATE VIEW isabi.v_selector_tipo_operacion AS
SELECT
  id_tipo_operacion,
  clave,
  nombre_corto                              AS label,
  nombre                                    AS label_completo,
  grupo,
  genera_isabi,
  aplica_factor_50pct,
  requiere_avaluo,
  requiere_const_zofemat,
  requiere_acta_defuncion,
  requiere_contrato_fideicom,
  puede_ser_exento,
  exento_por_ley
FROM isabi.cat_tipo_operacion
WHERE activo = 1;
GO

-- Vista de tasas vigentes (todos los municipios)
CREATE VIEW isabi.v_tasas_vigentes AS
SELECT
  clave_municipio,
  nombre_municipio,
  tasa_isabi_pct,
  tasa_adicional_pct,
  tasa_efectiva_pct,
  nombre_ley,
  articulo_tasa,
  fecha_inicio_exacta,
  poe_publicacion
FROM isabi.cat_tasa_historica
WHERE es_vigente = 1 AND activo = 1;
GO

-- ══════════════════════════════════════════════════════════════════
-- SECCIÓN 7: ÍNDICES ADICIONALES
-- ══════════════════════════════════════════════════════════════════
CREATE INDEX IX_tasa_hist_vigente ON isabi.cat_tasa_historica (clave_municipio, es_vigente)
  INCLUDE (tasa_isabi_pct, tasa_adicional_pct, tasa_efectiva_pct, nombre_ley, articulo_tasa);
GO

-- ══════════════════════════════════════════════════════════════════
-- SECCIÓN 8: ENDPOINTS REST — Referencia FastAPI
-- ══════════════════════════════════════════════════════════════════
/*
── Tipos de operación ─────────────────────────────────────────────
GET  /api/v1/isabi/tipos-operacion
     → Lista todos los tipos activos (v_selector_tipo_operacion)

GET  /api/v1/isabi/tipos-operacion/{id}
     → Detalle completo: descripción, documentos, momento causación

GET  /api/v1/isabi/tipos-operacion/{id}/requisitos
     → Solo los documentos requeridos del tipo

GET  /api/v1/isabi/tipos-operacion/grupo/{grupo}
     → Filtrar por: ONEROSA / GRATUITA / JUDICIAL / FIDEICOMISO /
                    ESPECIAL / CORPORATIVA / EXENTA / ESPECIAL_TULUM

── Tasas históricas ────────────────────────────────────────────────
GET  /api/v1/isabi/tasas/{clave_municipio}
     → Historial completo de tasas del municipio
     → clave_municipio: TULUM / BJ / SOLIDARIDAD / OTROS_QRoo

GET  /api/v1/isabi/tasas/{clave_municipio}/vigente
     → Solo la tasa actualmente vigente

GET  /api/v1/isabi/tasas/{clave_municipio}/{ejercicio_fiscal}
     → Tasa de un año específico (ej. /tasas/TULUM/2021 → 3%)

GET  /api/v1/isabi/tasas/vigentes
     → Todas las tasas vigentes de todos los municipios QRoo

── Cálculo ─────────────────────────────────────────────────────────
POST /api/v1/isabi/calcular
     Body: {
       id_tipo_operacion: int,
       clave_municipio: "TULUM",
       ejercicio_fiscal: 2026,      (opcional, default: año en curso)
       valor_operacion:  5000000,
       valor_catastral:  2500000,
       valor_avaluo:     4800000
     }
     → Llama sp_calcular_isabi y retorna desglose completo

── Admin ───────────────────────────────────────────────────────────
POST /api/v1/isabi/tipos-operacion          [ADMIN_INGRESOS]
PUT  /api/v1/isabi/tipos-operacion/{id}     [ADMIN_INGRESOS]
POST /api/v1/isabi/tasas                    [SUPER_ADMIN]
PUT  /api/v1/isabi/tasas/{id_tasa}          [SUPER_ADMIN]
*/

-- ══════════════════════════════════════════════════════════════════
-- RESUMEN FINAL
-- ══════════════════════════════════════════════════════════════════
/*
╔═══════════════════════════════════════════════════════════════════╗
║  TASAS ISABI TULUM — VIGENTES 2026                                ║
╠═════════════════════════╦═════════╦══════════╦═══════════════════╣
║  Período                ║  ISABI  ║  Adic.T  ║  Efectiva Total   ║
╠═════════════════════════╬═════════╬══════════╬═══════════════════╣
║  2000 – 2019            ║  2.00%  ║    —     ║       2.00%       ║
║  2020 – 2024            ║  3.00%  ║  10% s/  ║       3.30%       ║
║  2025 – 2026 ● VIGENTE  ║  4.00%  ║  10% s/  ║  ★  4.40%  ★     ║
╚═════════════════════════╩═════════╩══════════╩═══════════════════╝

  Objeto            : 2 tablas + 3 SPs + 3 vistas
  Tipos de operación: 25 registros en cat_tipo_operacion
  Tasas históricas  : 3 períodos Tulum + 4 referencia QRoo
  SP principal      : isabi.sp_calcular_isabi — integra ambas tablas
  Tasa vigente      : 4.40% efectiva sobre la base gravable más alta
*/
