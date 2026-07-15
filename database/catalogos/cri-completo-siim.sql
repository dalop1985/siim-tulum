-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  SIIM — CATÁLOGO POR RUBROS DE INGRESOS (CRI)                           ║
-- ║  Basado en: Acuerdo CONAC, DOF 09-12-2009 y reformas posteriores         ║
-- ║  Última reforma aplicada: DOF 09-08-2023 (obligatoria desde 01-01-2024)  ║
-- ║  Fundamento: Art. 6 y 9 fracc. I Ley General de Contabilidad             ║
-- ║              Gubernamental (LGCG, DOF 31-12-2008)                         ║
-- ║                                                                            ║
-- ║  Estructura del CRI:                                                       ║
-- ║    RUBRO    (1 dígito)   → 10 categorías principales                      ║
-- ║    TIPO     (2 dígitos)  → subgrupos obligatorios                          ║
-- ║    CLASE    (3 dígitos)  → desagregación opcional por ente público         ║
-- ║    CONCEPTO (4 dígitos)  → desagregación adicional opcional                ║
-- ║    GENÉRICA (5+ dígitos) → mayor detalle según necesidades locales         ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

SET NOCOUNT ON;
GO

-- ══════════════════════════════════════════════════════════════════
-- SECCIÓN 1: TABLAS DEL CRI
-- ══════════════════════════════════════════════════════════════════

-- ── 1A. cat_cri_rubro — Nivel 1 ──────────────────────────────────
CREATE TABLE catalogos.cat_cri_rubro (
  id_rubro           TINYINT       NOT NULL,    -- 1,2,3,4,5,6,7,8,9,0
  codigo_rubro       CHAR(1)       NOT NULL,    -- '1','2','3','4','5','6','7','8','9','0'
  nombre             VARCHAR(200)  NOT NULL,
  descripcion        NVARCHAR(MAX) NULL,
  aplica_municipios  BIT           NOT NULL CONSTRAINT DF_rubro_aplica DEFAULT 1,
  activo             BIT           NOT NULL CONSTRAINT DF_rubro_activo DEFAULT 1,
  fecha_creacion     DATETIME2(0)  NOT NULL CONSTRAINT DF_rubro_fcreac DEFAULT GETDATE(),
  CONSTRAINT PK_cat_cri_rubro  PRIMARY KEY (id_rubro),
  CONSTRAINT UQ_rubro_codigo   UNIQUE (codigo_rubro)
);
GO

-- ── 1B. cat_cri_tipo — Nivel 2 ───────────────────────────────────
CREATE TABLE catalogos.cat_cri_tipo (
  id_tipo            SMALLINT      NOT NULL,    -- 11,12,13...19, 21...25, etc.
  id_rubro           TINYINT       NOT NULL,
  codigo_tipo        CHAR(2)       NOT NULL,    -- '11','12','41','43', etc.
  nombre             VARCHAR(300)  NOT NULL,
  descripcion        NVARCHAR(MAX) NULL,
  derogado           BIT           NOT NULL CONSTRAINT DF_tipo_derog   DEFAULT 0,
  fecha_derogacion   DATE          NULL,
  aplica_municipios  BIT           NOT NULL CONSTRAINT DF_tipo_aplica  DEFAULT 1,
  cuenta_contable    VARCHAR(10)   NULL,        -- Cuenta del Plan CONAC asociada
  activo             BIT           NOT NULL CONSTRAINT DF_tipo_activo  DEFAULT 1,
  fecha_creacion     DATETIME2(0)  NOT NULL CONSTRAINT DF_tipo_fcreac  DEFAULT GETDATE(),
  CONSTRAINT PK_cat_cri_tipo   PRIMARY KEY (id_tipo),
  CONSTRAINT UQ_tipo_codigo    UNIQUE (codigo_tipo),
  CONSTRAINT FK_tipo_rubro     FOREIGN KEY (id_rubro) REFERENCES catalogos.cat_cri_rubro(id_rubro)
);
GO

-- ── 1C. cat_cri_clase — Nivel 3 (desagregación municipal) ────────
CREATE TABLE catalogos.cat_cri_clase (
  id_clase           INT           IDENTITY(1,1) NOT NULL,
  id_tipo            SMALLINT      NOT NULL,
  codigo_clase       CHAR(3)       NOT NULL,    -- '411','412','413','431'...
  nombre             VARCHAR(300)  NOT NULL,
  descripcion        NVARCHAR(MAX) NULL,
  activo             BIT           NOT NULL CONSTRAINT DF_clase_activo DEFAULT 1,
  fecha_creacion     DATETIME2(0)  NOT NULL CONSTRAINT DF_clase_fcreac DEFAULT GETDATE(),
  CONSTRAINT PK_cat_cri_clase   PRIMARY KEY (id_clase),
  CONSTRAINT UQ_clase_codigo    UNIQUE (codigo_clase),
  CONSTRAINT FK_clase_tipo      FOREIGN KEY (id_tipo) REFERENCES catalogos.cat_cri_tipo(id_tipo)
);
GO

-- ── 1D. cat_cri_concepto — Nivel 4 ───────────────────────────────
-- Nivel de mayor detalle para el SIIM de Tulum
-- Aquí se asocia cada fuente de ingreso de Tulum a su CRI
CREATE TABLE catalogos.cat_cri_concepto (
  id_concepto        INT           IDENTITY(1,1) NOT NULL,
  id_clase           INT           NOT NULL,
  codigo_cri         VARCHAR(10)   NOT NULL,    -- '1.2.1.1', '4.3.7.1' etc.
  nombre             VARCHAR(400)  NOT NULL,
  descripcion        NVARCHAR(MAX) NULL,
  -- Mapping al SIIM
  modulo_siim        VARCHAR(50)   NULL,        -- PREDIAL/LICENCIAS/ISABI/DSA/ZOFEMAT/...
  fuente_ingreso_id  INT           NULL,        -- FK futura a catalogos.fuente_ingreso
  activo             BIT           NOT NULL CONSTRAINT DF_conc_activo  DEFAULT 1,
  fecha_creacion     DATETIME2(0)  NOT NULL CONSTRAINT DF_conc_fcreac  DEFAULT GETDATE(),
  CONSTRAINT PK_cat_cri_concepto  PRIMARY KEY (id_concepto),
  CONSTRAINT UQ_concepto_codigo   UNIQUE (codigo_cri),
  CONSTRAINT FK_concepto_clase    FOREIGN KEY (id_clase) REFERENCES catalogos.cat_cri_clase(id_clase)
);
GO

CREATE INDEX IX_cri_rubro_activo    ON catalogos.cat_cri_rubro   (activo);
CREATE INDEX IX_cri_tipo_rubro      ON catalogos.cat_cri_tipo    (id_rubro, activo);
CREATE INDEX IX_cri_clase_tipo      ON catalogos.cat_cri_clase   (id_tipo, activo);
CREATE INDEX IX_cri_concepto_clase  ON catalogos.cat_cri_concepto (id_clase, activo);
GO

-- ══════════════════════════════════════════════════════════════════
-- SECCIÓN 2: SEED — NIVEL 1: RUBROS
-- ══════════════════════════════════════════════════════════════════
INSERT INTO catalogos.cat_cri_rubro
  (id_rubro, codigo_rubro, nombre, descripcion, aplica_municipios)
VALUES
-- ─── RUBRO 1 ──────────────────────────────────────────────────────────────
(1, '1', 'Impuestos',
 'Son las contribuciones establecidas en Ley que deben pagar las personas físicas y morales '
+'que se encuentran en la situación jurídica o de hecho prevista por la misma y que sean '
+'distintas de las aportaciones de seguridad social, contribuciones de mejoras y derechos.',
 1),
-- ─── RUBRO 2 ──────────────────────────────────────────────────────────────
(2, '2', 'Cuotas y Aportaciones de Seguridad Social',
 'Son las contribuciones establecidas en Ley a cargo de personas que son sustituidas por el '
+'Estado en el cumplimiento de obligaciones fijadas por la Ley en materia de seguridad social '
+'o a las personas que se beneficien en forma especial por servicios de seguridad social '
+'proporcionados por el mismo Estado. No aplica para municipios sin organismos de seguridad social.',
 0),  -- Los municipios raramente tienen este rubro
-- ─── RUBRO 3 ──────────────────────────────────────────────────────────────
(3, '3', 'Contribuciones de Mejoras',
 'Son las establecidas en Ley a cargo de las personas físicas y morales que se beneficien '
+'de manera directa por obras públicas realizadas por el municipio.',
 1),
-- ─── RUBRO 4 ──────────────────────────────────────────────────────────────
(4, '4', 'Derechos',
 'Son las contribuciones establecidas en Ley por el uso o aprovechamiento de los bienes del '
+'dominio público, así como por recibir servicios que presta el Estado en sus funciones de '
+'derecho público, excepto cuando se presten por organismos descentralizados u órganos '
+'desconcentrados cuando en este último caso, se trate de contraprestaciones que no se '
+'encuentren previstas en las leyes correspondientes. También son derechos las contribuciones '
+'a cargo de los organismos públicos descentralizados por prestar servicios exclusivos del Estado.',
 1),
-- ─── RUBRO 5 ──────────────────────────────────────────────────────────────
(5, '5', 'Productos',
 'Son los ingresos por contraprestaciones por los servicios que preste el Estado en sus '
+'funciones de derecho privado, tales como los intereses que generan las cuentas bancarias '
+'de los entes públicos, entre otros. (Rubro reformado DOF 09-08-2023, vigente desde 2024)',
 1),
-- ─── RUBRO 6 ──────────────────────────────────────────────────────────────
(6, '6', 'Aprovechamientos',
 'Son los ingresos que percibe el Estado por funciones de derecho público distintos de: las '
+'contribuciones, los ingresos derivados de financiamientos y de los que obtengan los '
+'organismos descentralizados y las empresas de participación estatal y municipal.',
 1),
-- ─── RUBRO 7 ──────────────────────────────────────────────────────────────
(7, '7', 'Ingresos por Venta de Bienes, Prestación de Servicios y Otros Ingresos',
 'Son los ingresos propios obtenidos por las Instituciones Públicas de Seguridad Social, las '
+'Empresas Productivas del Estado, las entidades de la administración pública paraestatal y '
+'paramunicipal, los poderes legislativo y judicial, y los órganos autónomos federales y '
+'estatales, por sus actividades de producción, comercialización o prestación de servicios; '
+'así como otros ingresos por sus actividades diversas no inherentes a su operación, que generen recursos.',
 0),  -- Aplica para administración paramunicipal, no para el municipio directamente
-- ─── RUBRO 8 ──────────────────────────────────────────────────────────────
(8, '8', 'Participaciones, Aportaciones, Convenios, Incentivos Derivados de la Colaboración Fiscal y Fondos Distintos de Aportaciones',
 'Son los recursos que reciben las Entidades Federativas y los Municipios por concepto de '
+'participaciones, aportaciones, convenios, incentivos derivados de la colaboración fiscal y '
+'fondos distintos de aportaciones. Es el rubro de mayor monto para municipios pequeños y medianos.',
 1),
-- ─── RUBRO 9 ──────────────────────────────────────────────────────────────
(9, '9', 'Transferencias, Asignaciones, Subsidios y Subvenciones, y Pensiones y Jubilaciones',
 'Son los recursos que reciben en forma directa o indirecta los entes públicos como parte de '
+'su política económica y social, de acuerdo a las estrategias y prioridades de desarrollo '
+'para el sostenimiento y desempeño de sus actividades.',
 1),
-- ─── RUBRO 0 ──────────────────────────────────────────────────────────────
(0, '0', 'Ingresos Derivados de Financiamientos',
 'Son los ingresos obtenidos por la celebración de empréstitos internos o externos, a corto '
+'o largo plazo, aprobados en términos de la legislación correspondiente. Los créditos que '
+'se obtienen son por: emisiones de instrumentos en mercados nacionales e internacionales '
+'de capital, organismos financieros internacionales, créditos bilaterales y otras fuentes. '
+'Para municipios, aplica solo el tipo 03 (Financiamiento Interno).',
 1);
GO

-- ══════════════════════════════════════════════════════════════════
-- SECCIÓN 3: SEED — NIVEL 2: TIPOS
-- ══════════════════════════════════════════════════════════════════

-- ════════════════════════════════════════════
-- RUBRO 1 — IMPUESTOS (8 tipos + 1 rezagos)
-- ════════════════════════════════════════════
INSERT INTO catalogos.cat_cri_tipo
  (id_tipo, id_rubro, codigo_tipo, nombre, descripcion, derogado, aplica_municipios, cuenta_contable)
VALUES
-- ── 1.1 ──────────────────────────────────────────────────────────
(11, 1, '11', 'Impuestos Sobre los Ingresos',
 'Son las contribuciones derivadas de las imposiciones fiscales que en forma unilateral y obligatoria '
+'se fijan sobre los ingresos de las personas físicas y/o morales, de conformidad con la legislación '
+'aplicable en la materia. En Tulum: Impuesto sobre Diversiones, Videojuegos, Cines y Espectáculos '
+'Públicos; Impuesto sobre Juegos Permitidos, Rifas y Loterías; Impuesto a Músicos y Cancioneros.',
 0, 1, '4111'),
-- ── 1.2 ──────────────────────────────────────────────────────────
(12, 1, '12', 'Impuestos Sobre el Patrimonio',
 'Son las contribuciones derivadas de las imposiciones fiscales que en forma unilateral y obligatoria '
+'se fijan sobre los bienes propiedad de las personas físicas y/o morales, de conformidad con la '
+'legislación aplicable en la materia. En Tulum: Impuesto Predial y Tenencia de Vehículos sin gasolina.',
 0, 1, '4112'),
-- ── 1.3 ──────────────────────────────────────────────────────────
(13, 1, '13', 'Impuestos Sobre la Producción, el Consumo y las Transacciones',
 'Son las contribuciones derivadas de las imposiciones fiscales que en forma unilateral y obligatoria '
+'se fijan sobre la actividad económica relacionada con la producción, el consumo y las transacciones '
+'que realizan las personas físicas y/o morales. En Tulum: ISABI (Impuesto Sobre Adquisición de '
+'Bienes Inmuebles — el más importante de este tipo para el municipio).',
 0, 1, '4113'),
-- ── 1.4 ──────────────────────────────────────────────────────────
(14, 1, '14', 'Impuestos al Comercio Exterior',
 'Son las contribuciones derivadas de las imposiciones fiscales que en forma unilateral y obligatoria '
+'se fijan sobre las actividades de importación y exportación. NO aplica para municipios (es exclusivo '
+'de la Federación). Los municipios lo incluyen con valor cero en su Ley de Ingresos.',
 0, 0, '4114'),
-- ── 1.5 ──────────────────────────────────────────────────────────
(15, 1, '15', 'Impuestos Sobre Nóminas y Asimilables',
 'Son las contribuciones derivadas de las imposiciones fiscales que en forma unilateral y obligatoria '
+'se fijan sobre la base gravable de las remuneraciones al trabajo personal subordinado. En Quintana Roo '
+'este impuesto es estatal, no municipal. Los municipios lo reportan en cero.',
 0, 0, '4115'),
-- ── 1.6 ──────────────────────────────────────────────────────────
(16, 1, '16', 'Impuestos Ecológicos',
 'Son las contribuciones derivadas de las imposiciones fiscales que en forma unilateral y obligatoria '
+'se fijan a las personas físicas y/o morales por la afectación preventiva o correctiva que se '
+'ocasione en flora, fauna, medio ambiente o todo aquello relacionado a la ecología. Actualmente '
+'sin aplicación en Tulum (Ley de Ingresos 2026 = $0).',
 0, 1, '4116'),
-- ── 1.7 ──────────────────────────────────────────────────────────
(17, 1, '17', 'Accesorios de Impuestos',
 'Son los ingresos que se perciben por concepto de recargos, sanciones, gastos de ejecución, '
+'indemnizaciones, entre otros, asociados a los impuestos, cuando éstos no se cubran oportunamente, '
+'de conformidad con la legislación aplicable en la materia.',
 0, 1, '4117'),
-- ── 1.8 ──────────────────────────────────────────────────────────
(18, 1, '18', 'Otros Impuestos',
 'Son los ingresos que se perciben por conceptos de impuestos no incluidos en los tipos anteriores, '
+'de conformidad con la legislación aplicable en la materia.',
 0, 1, '4118'),
-- ── 1.9 ──────────────────────────────────────────────────────────
(19, 1, '19', 'Impuestos no Comprendidos en la Ley de Ingresos Vigente, Causados en Ejercicios Fiscales Anteriores Pendientes de Liquidación o Pago',
 'Son los ingresos que se recaudan en el ejercicio corriente, por impuestos pendientes de '
+'liquidación o pago causados en ejercicios fiscales anteriores, no incluidos en la Ley de '
+'Ingresos vigente del ejercicio.',
 0, 1, '4119');

-- ════════════════════════════════════════════
-- RUBRO 2 — CUOTAS Y APORTACIONES (5 tipos)
-- ════════════════════════════════════════════
INSERT INTO catalogos.cat_cri_tipo
  (id_tipo, id_rubro, codigo_tipo, nombre, descripcion, derogado, aplica_municipios, cuenta_contable)
VALUES
(21, 2, '21', 'Aportaciones para Fondos de Vivienda',
 'Son los ingresos que reciben los entes públicos que prestan los servicios de seguridad social, '
+'para cubrir las obligaciones relativas a los fondos de vivienda (INFONAVIT, FOVISSSTE). '
+'En municipios: solo aplica si tienen organismo municipal de seguridad social.',
 0, 0, '4121'),
(22, 2, '22', 'Cuotas para la Seguridad Social',
 'Son los ingresos que reciben los entes públicos que prestan los servicios de seguridad social, '
+'para cubrir las obligaciones relativas a la previsión social (IMSS, ISSSTE, ISSTE QRoo). '
+'En municipios: solo aplica si tienen régimen propio de seguridad social.',
 0, 0, '4122'),
(23, 2, '23', 'Cuotas de Ahorro para el Retiro',
 'Son los ingresos que reciben los entes públicos que prestan los servicios de seguridad social, '
+'para cubrir las obligaciones relativas a fondos del ahorro para el retiro (AFORE). No aplica municipios.',
 0, 0, '4123'),
(24, 2, '24', 'Otras Cuotas y Aportaciones para la Seguridad Social',
 'Son los ingresos que reciben los entes públicos que prestan los servicios de seguridad social, '
+'por conceptos no incluidos en los tipos anteriores.',
 0, 0, '4124'),
(25, 2, '25', 'Accesorios de Cuotas y Aportaciones de Seguridad Social',
 'Son los ingresos que se perciben por concepto de recargos, sanciones, gastos de ejecución, '
+'indemnizaciones, entre otros, asociados a las cuotas y aportaciones de seguridad social, '
+'cuando éstas no se cubran oportunamente.',
 0, 0, '4125');

-- ════════════════════════════════════════════
-- RUBRO 3 — CONTRIBUCIONES DE MEJORAS (2 tipos)
-- ════════════════════════════════════════════
INSERT INTO catalogos.cat_cri_tipo
  (id_tipo, id_rubro, codigo_tipo, nombre, descripcion, derogado, aplica_municipios, cuenta_contable)
VALUES
(31, 3, '31', 'Contribuciones de Mejoras por Obras Públicas',
 'Son las contribuciones derivadas de los beneficios diferenciales particulares por la realización '
+'de obras públicas, a cargo de las personas físicas y/o morales, independientemente de la '
+'utilidad general colectiva, de conformidad con la legislación aplicable en la materia. '
+'En Tulum: Cooperación para pavimentación, banquetas, alumbrado, agua potable (Art. 47-56 Ley Hac.).',
 0, 1, '4131'),
(39, 3, '39', 'Contribuciones de Mejoras no Comprendidas en la Ley de Ingresos Vigente, Causadas en Ejercicios Fiscales Anteriores Pendientes de Liquidación o Pago',
 'Son los ingresos que se recaudan en el ejercicio corriente, por contribuciones de mejoras '
+'pendientes de liquidación o pago causadas en ejercicios fiscales anteriores, no incluidas '
+'en la Ley de Ingresos vigente.',
 0, 1, '4139');

-- ════════════════════════════════════════════
-- RUBRO 4 — DERECHOS (6 tipos activos + 1 derogado)
-- El rubro MÁS IMPORTANTE para municipios turísticos como Tulum
-- ════════════════════════════════════════════
INSERT INTO catalogos.cat_cri_tipo
  (id_tipo, id_rubro, codigo_tipo, nombre, descripcion, derogado, fecha_derogacion, aplica_municipios, cuenta_contable)
VALUES
(41, 4, '41', 'Derechos por el Uso, Goce, Aprovechamiento o Explotación de Bienes de Dominio Público',
 'Son las contribuciones derivadas de la contraprestación del uso, goce, aprovechamiento o '
+'explotación de bienes de dominio público, de conformidad con la legislación aplicable en la materia. '
+'En Tulum: Derechos de cooperación para obras públicas (Art. 47), Uso de vía pública, ZOFEMAT.',
 0, NULL, 1, '4141'),
(42, 4, '42', 'Derechos a los Hidrocarburos (DEROGADO)',
 'Tipo derogado del CRI. No aplica para municipios. Era aplicable a Pemex como empresa productiva del Estado.',
 1, '2018-06-11', 0, NULL),
(43, 4, '43', 'Derechos por Prestación de Servicios',
 'Son las contribuciones derivadas por la contraprestación de servicios exclusivos del Estado, '
+'de conformidad con la legislación aplicable en la materia. '
+'En Tulum: TODOS los servicios municipales: Tránsito, Registro Civil, Desarrollo Urbano, '
+'Catastro, Panteones, Licencias de Funcionamiento, Anuncios, Recolección de Basura, '
+'Ecología, Protección Civil, DSA, Alumbrado Público.',
 0, NULL, 1, '4143'),
(44, 4, '44', 'Otros Derechos',
 'Son las contribuciones derivadas por contraprestaciones no incluidas en los tipos anteriores, '
+'de conformidad con la legislación aplicable en la materia.',
 0, NULL, 1, '4144'),
(45, 4, '45', 'Accesorios de Derechos',
 'Son los ingresos que se perciben por concepto de recargos, sanciones, gastos de ejecución, '
+'indemnizaciones, entre otros, asociados a los derechos, cuando éstos no se cubran oportunamente.',
 0, NULL, 1, '4145'),
(49, 4, '49', 'Derechos no Comprendidos en la Ley de Ingresos Vigente, Causados en Ejercicios Fiscales Anteriores Pendientes de Liquidación o Pago',
 'Son las contribuciones que se recaudan en el ejercicio corriente, por derechos pendientes '
+'de liquidación o pago causados en ejercicios fiscales anteriores, no incluidos en la Ley '
+'de Ingresos vigente.',
 0, NULL, 1, '4149');

-- ════════════════════════════════════════════
-- RUBRO 5 — PRODUCTOS (2 tipos activos + 1 derogado)
-- Reformado por Acuerdo DOF 09-08-2023, vigente desde 01-01-2024
-- ════════════════════════════════════════════
INSERT INTO catalogos.cat_cri_tipo
  (id_tipo, id_rubro, codigo_tipo, nombre, descripcion, derogado, fecha_derogacion, aplica_municipios, cuenta_contable)
VALUES
(51, 5, '51', 'Productos',
 'Son los ingresos por concepto de servicios otorgados por funciones de derecho privado, '
+'tales como los intereses que generan las cuentas bancarias de los entes públicos, entre '
+'otros, de conformidad con la legislación aplicable en la materia. '
+'NOTA: Tipo reformado por Acuerdo CONAC DOF 09-08-2023. La nueva descripción amplía el alcance '
+'para incluir explícitamente los intereses bancarios como ingresos de este tipo. '
+'En Tulum: Productos diversos, intereses en cuentas de inversión.',
 0, NULL, 1, '4151'),
(52, 5, '52', 'Productos de Capital (DEROGADO)',
 'Tipo derogado del CRI. Era para ingresos por venta de activos fijos. Fue derogado al reformarse '
+'el rubro 6 Aprovechamientos para incluir los Aprovechamientos Patrimoniales (tipo 62).',
 1, '2013-01-02', 1, NULL),
(59, 5, '59', 'Productos no Comprendidos en la Ley de Ingresos Vigente, Causados en Ejercicios Fiscales Anteriores Pendientes de Liquidación o Pago',
 'Son los ingresos que se recaudan en el ejercicio corriente, por productos pendientes de '
+'liquidación o pago causados en ejercicios fiscales anteriores, no incluidos en la Ley '
+'de Ingresos vigente.',
 0, NULL, 1, '4159');

-- ════════════════════════════════════════════
-- RUBRO 6 — APROVECHAMIENTOS (4 tipos)
-- Tipo 62 reformado por Acuerdo DOF 09-08-2023
-- ════════════════════════════════════════════
INSERT INTO catalogos.cat_cri_tipo
  (id_tipo, id_rubro, codigo_tipo, nombre, descripcion, derogado, aplica_municipios, cuenta_contable)
VALUES
(61, 6, '61', 'Aprovechamientos',
 'Son los ingresos que se perciben por funciones de derecho público, cuyos elementos pueden '
+'no estar previstos en una Ley sino en una disposición administrativa de carácter general, '
+'provenientes de multas e indemnizaciones no fiscales, reintegros, juegos y sorteos, '
+'donativos, entre otros. En Tulum: Multas administrativas, rezagos, otros aprovechamientos.',
 0, 1, '4161'),
(62, 6, '62', 'Aprovechamientos Patrimoniales',
 'Son los ingresos que se perciben por uso o enajenación de bienes muebles, inmuebles e '
+'intangibles, por recuperaciones de capital o en su caso patrimonio invertido, de '
+'conformidad con la legislación aplicable en la materia. '
+'NOTA: Tipo reformado por Acuerdo CONAC DOF 09-08-2023. Amplía la descripción original '
+'para incluir específicamente recuperaciones de capital e intangibles.',
 0, 1, '4162'),
(63, 6, '63', 'Accesorios de Aprovechamientos',
 'Son los ingresos que se perciben por concepto de recargos, sanciones, gastos de ejecución '
+'e indemnizaciones, entre otros, asociados a los aprovechamientos, cuando éstos no se '
+'cubran oportunamente de conformidad con la legislación aplicable en la materia.',
 0, 1, '4163'),
(69, 6, '69', 'Aprovechamientos no Comprendidos en la Ley de Ingresos Vigente, Causados en Ejercicios Fiscales Anteriores Pendientes de Liquidación o Pago',
 'Son los ingresos que se recaudan en el ejercicio corriente, por aprovechamientos pendientes '
+'de liquidación o pago causados en ejercicios fiscales anteriores, no incluidos en la Ley '
+'de Ingresos vigente.',
 0, 1, '4169');

-- ════════════════════════════════════════════
-- RUBRO 7 — INGRESOS POR VENTA DE BIENES Y PRESTACIÓN DE SERVICIOS (9 tipos)
-- No aplica directamente para el municipio central, sí para organismos paramuncipales
-- ════════════════════════════════════════════
INSERT INTO catalogos.cat_cri_tipo
  (id_tipo, id_rubro, codigo_tipo, nombre, descripcion, derogado, aplica_municipios, cuenta_contable)
VALUES
(71, 7, '71', 'Ingresos por Venta de Bienes y Prestación de Servicios de Instituciones Públicas de Seguridad Social',
 'Son los ingresos propios obtenidos por las Instituciones Públicas de Seguridad Social '
+'por sus actividades de producción, comercialización o prestación de servicios.',
 0, 0, '4171'),
(72, 7, '72', 'Ingresos por Venta de Bienes y Prestación de Servicios de Empresas Productivas del Estado',
 'Son los ingresos propios obtenidos por las Empresas Productivas del Estado (Pemex, CFE) '
+'por sus actividades de producción, comercialización o prestación de servicios. No aplica municipios.',
 0, 0, '4172'),
(73, 7, '73', 'Ingresos por Venta de Bienes y Prestación de Servicios de Entidades Paraestatales y Fideicomisos No Empresariales y No Financieros',
 'Son los ingresos propios obtenidos por las Entidades Paraestatales y Fideicomisos No '
+'Empresariales y No Financieros por sus actividades de producción, comercialización o '
+'prestación de servicios.',
 0, 0, '4173'),
(74, 7, '74', 'Ingresos por Venta de Bienes y Prestación de Servicios de Entidades Paraestatales Empresariales No Financieras con Participación Estatal Mayoritaria',
 'Son los ingresos propios obtenidos por las Entidades Paraestatales Empresariales No Financieras '
+'con Participación Estatal Mayoritaria por sus actividades de producción, comercialización o prestación de servicios.',
 0, 0, '4174'),
(75, 7, '75', 'Ingresos por Venta de Bienes y Prestación de Servicios de Entidades Paraestatales Empresariales Financieras Monetarias con Participación Estatal Mayoritaria',
 'Son los ingresos propios obtenidos por las Entidades Paraestatales Empresariales Financieras '
+'Monetarias con Participación Estatal Mayoritaria (ej. bancos de desarrollo).',
 0, 0, '4175'),
(76, 7, '76', 'Ingresos por Venta de Bienes y Prestación de Servicios de Entidades Paraestatales Empresariales Financieras No Monetarias con Participación Estatal Mayoritaria',
 'Son los ingresos propios obtenidos por las Entidades Paraestatales Empresariales Financieras '
+'No Monetarias con Participación Estatal Mayoritaria.',
 0, 0, '4176'),
(77, 7, '77', 'Ingresos por Venta de Bienes y Prestación de Servicios de Fideicomisos Financieros Públicos con Participación Estatal Mayoritaria',
 'Son los ingresos propios obtenidos por los Fideicomisos Financieros Públicos con '
+'Participación Estatal Mayoritaria por sus actividades de producción, comercialización o prestación de servicios.',
 0, 0, '4177'),
(78, 7, '78', 'Ingresos por Venta de Bienes y Prestación de Servicios de los Poderes Legislativo y Judicial, y de los Órganos Autónomos',
 'Son los ingresos propios obtenidos por los Poderes Legislativo y Judicial, y los Órganos '
+'Autónomos por sus actividades de producción, comercialización o prestación de servicios.',
 0, 0, '4178'),
(79, 7, '79', 'Otros Ingresos',
 'Son los ingresos propios obtenidos por los Poderes Legislativo y Judicial, los Órganos '
+'Autónomos y las entidades de la administración pública paraestatal y paramunicipal por '
+'sus actividades diversas no inherentes a su operación que generan recursos y que no sean '
+'ingresos por venta de bienes o prestación de servicios, tales como donativos, entre otros.',
 0, 0, '4179');

-- ════════════════════════════════════════════
-- RUBRO 8 — PARTICIPACIONES, APORTACIONES, CONVENIOS... (5 tipos)
-- EL RUBRO MÁS CUANTIOSO PARA TULUM JUNTO CON EL RUBRO 1
-- En Tulum 2026: ~$435 millones del total de $1,408 millones
-- ════════════════════════════════════════════
INSERT INTO catalogos.cat_cri_tipo
  (id_tipo, id_rubro, codigo_tipo, nombre, descripcion, derogado, aplica_municipios, cuenta_contable)
VALUES
(81, 8, '81', 'Participaciones',
 'Son los ingresos que reciben las Entidades Federativas y Municipios que se derivan de la '
+'adhesión al Sistema Nacional de Coordinación Fiscal (SNCF), así como las que correspondan '
+'a sistemas estatales de coordinación fiscal, determinados por las leyes correspondientes. '
+'Incluye: Fondo General de Participaciones (FGP), Fondo de Fomento Municipal (FFM), '
+'Fondo de Fiscalización y Recaudación, IEPS, ISAN, gasolina/diésel, FISR, bebidas alcohólicas. '
+'Tulum 2026: $250.6 millones estimados.',
 0, 1, '4181'),
(82, 8, '82', 'Aportaciones',
 'Son los ingresos que reciben las Entidades Federativas y Municipios previstos en la Ley '
+'de Coordinación Fiscal (LCF), cuyo gasto está condicionado a la consecución y cumplimiento '
+'de los objetivos que para cada tipo de aportación establece la legislación aplicable. '
+'Incluye: FAIS Municipal (infraestructura social), FORTAMUN (fortalecimiento municipal). '
+'Tulum 2026: $105.9 millones estimados. Son recursos etiquetados (no de libre disposición).',
 0, 1, '4182'),
(83, 8, '83', 'Convenios',
 'Son los ingresos que reciben las Entidades Federativas y Municipios derivados de convenios '
+'de coordinación, colaboración, reasignación o descentralización según corresponda, los '
+'cuales se acuerdan entre la Federación, las Entidades Federativas y/o los Municipios. '
+'Incluye: ZOFEMAT (Fondo vigilancia), DUZA (museos y zonas arqueológicas), '
+'Fondo infraestructura, Licencias de conducir, Brigadas protección fuego. '
+'Tulum 2026: $35.3 millones estimados.',
 0, 1, '4183'),
(84, 8, '84', 'Incentivos Derivados de la Colaboración Fiscal',
 'Son los ingresos que reciben las Entidades Federativas y Municipios derivados del ejercicio '
+'de facultades delegadas por la Federación mediante la celebración de convenios de '
+'colaboración administrativa en materia fiscal; que comprenden las funciones de recaudación, '
+'fiscalización y administración de ingresos federales y por las que a cambio reciben '
+'incentivos económicos que implican la retribución de su colaboración. '
+'Incluye: Incentivos ZOFEMAT (cobro del Art. 232-C LFD), ISRBI (enajenación inmuebles), '
+'ISAN, Tenencia vehicular, multas administrativas federales. '
+'Tulum 2026: $44.0 millones estimados (ZOFEMAT $35.7M + otros $8.3M).',
 0, 1, '4184'),
(85, 8, '85', 'Fondos Distintos de Aportaciones',
 'Son los ingresos que reciben las Entidades Federativas y Municipios derivados de fondos '
+'distintos de aportaciones y previstos en disposiciones específicas, tales como: Fondo para '
+'Entidades Federativas y Municipios Productores de Hidrocarburos, Fondo para el Desarrollo '
+'Regional Sustentable de Estados y Municipios Mineros (Fondo Minero), entre otros. '
+'Tulum 2026: $0 (no aplica por no ser municipio productor de hidrocarburos ni minero).',
 0, 1, '4185');

-- ════════════════════════════════════════════
-- RUBRO 9 — TRANSFERENCIAS, ASIGNACIONES, SUBSIDIOS... (5 tipos activos + 2 derogados)
-- ════════════════════════════════════════════
INSERT INTO catalogos.cat_cri_tipo
  (id_tipo, id_rubro, codigo_tipo, nombre, descripcion, derogado, fecha_derogacion, aplica_municipios, cuenta_contable)
VALUES
(91, 9, '91', 'Transferencias y Asignaciones',
 'Son los ingresos que reciben los entes públicos con el objeto de sufragar gastos inherentes '
+'a sus atribuciones. Recursos directos del Gobierno Federal o Estatal sin carácter de '
+'aportaciones etiquetadas.',
 0, NULL, 1, '4191'),
(92, 9, '92', 'Transferencias al Resto del Sector Público (DEROGADO)',
 'Tipo derogado del CRI. Ya no aplica para ningún ente público.',
 1, '2013-01-02', 0, NULL),
(93, 9, '93', 'Subsidios y Subvenciones',
 'Son los ingresos destinados para el desarrollo de actividades prioritarias de interés general, '
+'que reciben los entes públicos mediante asignación directa de recursos, con el fin de '
+'favorecer a los diferentes sectores de la sociedad para: apoyar en sus operaciones, mantener '
+'los niveles en los precios, apoyar el consumo, la distribución y comercialización de bienes, '
+'motivar la inversión, cubrir impactos financieros, promover la innovación tecnológica, y '
+'para el fomento de las actividades agropecuarias, industriales o de servicios.',
 0, NULL, 1, '4193'),
(94, 9, '94', 'Ayudas Sociales (DEROGADO)',
 'Tipo derogado del CRI. Las ayudas sociales se reclasificaron en otros tipos.',
 1, '2013-01-02', 0, NULL),
(95, 9, '95', 'Pensiones y Jubilaciones',
 'Son los ingresos que reciben los entes públicos de seguridad social, que cubre el Gobierno '
+'Federal, Estatal o Municipal según corresponda, por el pago de pensiones y jubilaciones. '
+'Para municipios: solo aplica si tienen régimen propio de pensiones.',
 0, NULL, 0, '4195'),
(96, 9, '96', 'Transferencias a Fideicomisos, Mandatos y Análogos (DEROGADO)',
 'Tipo derogado del CRI.',
 1, '2013-01-02', 0, NULL),
(97, 9, '97', 'Transferencias del Fondo Mexicano del Petróleo para la Estabilización y el Desarrollo',
 'Son los ingresos que reciben los entes públicos por transferencias del Fondo Mexicano del '
+'Petróleo para la Estabilización y el Desarrollo. No aplica para municipios.',
 0, NULL, 0, '4197');

-- ════════════════════════════════════════════
-- RUBRO 0 — INGRESOS DERIVADOS DE FINANCIAMIENTOS (3 tipos)
-- ════════════════════════════════════════════
INSERT INTO catalogos.cat_cri_tipo
  (id_tipo, id_rubro, codigo_tipo, nombre, descripcion, derogado, aplica_municipios, cuenta_contable)
VALUES
(1, 0, '01', 'Endeudamiento Interno',
 'Financiamiento derivado del resultado positivo neto de los recursos que provienen de '
+'obligaciones contraídas por los entes públicos federales con acreedores nacionales y '
+'pagaderos en el interior del país en moneda nacional. Para gobierno federal únicamente.',
 0, 0, '4201'),
(2, 0, '02', 'Endeudamiento Externo',
 'Financiamiento derivado del resultado positivo neto de los recursos que provienen de '
+'obligaciones contraídas por los entes públicos federales con acreedores extranjeros y '
+'pagaderos en el exterior del país en moneda extranjera. Para gobierno federal únicamente.',
 0, 0, '4202'),
(3, 0, '03', 'Financiamiento Interno',
 'Son los recursos que provienen de obligaciones contraídas por las Entidades Federativas, '
+'los Municipios y en su caso, las entidades del sector paraestatal o paramunicipal, a corto '
+'o largo plazo, con acreedores nacionales y pagaderos en el interior del país en moneda '
+'nacional, considerando lo previsto en la legislación aplicable. '
+'ESTE ES EL ÚNICO TIPO DEL RUBRO 0 QUE APLICA PARA MUNICIPIOS. Tulum 2026: $0.',
 0, 1, '4203');
GO

-- ══════════════════════════════════════════════════════════════════
-- SECCIÓN 4: SEED — NIVEL 3: CLASES
-- Desagregación de los tipos más relevantes para Tulum
-- ══════════════════════════════════════════════════════════════════

-- ── Clase 4.1.x — Bienes de Dominio Público ──────────────────────
INSERT INTO catalogos.cat_cri_clase (id_tipo, codigo_clase, nombre)
VALUES
(41, '411', 'Cooperación para Obras Públicas que realice el Municipio'),
(41, '412', 'Del Uso de la Vía Pública o de Otros Bienes de Uso Común');

-- ── Clase 4.3.x — Derechos por Prestación de Servicios ──────────
-- Estas clases corresponden exactamente a la numeración de la Ley de Ingresos de Tulum
INSERT INTO catalogos.cat_cri_clase (id_tipo, codigo_clase, nombre)
VALUES
(43, '431', 'Del Servicio de Tránsito'),
(43, '432', 'Del Registro Civil Municipal'),
(43, '433', 'De los Servicios en Materia de Desarrollo Urbano'),
(43, '434', 'De las Certificaciones'),
(43, '435', 'De los Panteones'),
(43, '436', 'De los Alineamientos de Predios, Factibilidad de Uso de Suelo, Constancia del Uso del Suelo, Número Oficial, Medición de Solares del Fundo Legal y Servicios Catastrales'),
(43, '437', 'De la Expedición y Renovación de la Licencia de Funcionamiento Comercial, Industrial y de Prestación de Servicios e Inversión de Capitales'),
(43, '438', 'De las Licencias para Funcionamiento de Establecimientos Mercantiles en Horas Extraordinarias'),
(43, '439', 'Del Rastro e Inspección Sanitaria'),
(43, '4310','De los Anuncios'),
(43, '4314','De los Servicios de Recolección, Traslado, Tratamiento y Disposición Final de Residuos Sólidos (Art. 118/129)'),
(43, '4322','De los Servicios en Materia de Ecología y Protección al Ambiente'),
(43, '4323','De los Servicios en Materia de Protección Civil'),
(43, '4325','De los Derechos de Saneamiento Ambiental que Realice el Municipio (DSA — Arts. 139-143)'),
(43, '4326','Del Derecho de Servicio y Mantenimiento de Alumbrado Público');

-- ── Clase 8.1.x — Participaciones ────────────────────────────────
INSERT INTO catalogos.cat_cri_clase (id_tipo, codigo_clase, nombre)
VALUES
(81, '811', 'Fondo General de Participaciones'),
(81, '812', 'Fondo de Fomento Municipal'),
(81, '813', 'Fondo de Fiscalización y Recaudación'),
(81, '814', 'Impuesto Especial Sobre Producción y Servicios (IEPS)'),
(81, '815', 'Participaciones de Gasolina y Diésel'),
(81, '816', 'Fondo de Impuesto Sobre la Renta (FISR)'),
(81, '817', 'Del Impuesto a la Venta Final de Bebidas con Contenido Alcohólico en Envase Cerrado');

-- ── Clase 8.2.x — Aportaciones ───────────────────────────────────
INSERT INTO catalogos.cat_cri_clase (id_tipo, codigo_clase, nombre)
VALUES
(82, '821', 'Fondo de Aportaciones para la Infraestructura Social Municipal (FAIS-M)'),
(82, '822', 'Fondo de Aportaciones para el Fortalecimiento de los Municipios (FORTAMUN)');

-- ── Clase 8.3.x — Convenios ──────────────────────────────────────
INSERT INTO catalogos.cat_cri_clase (id_tipo, codigo_clase, nombre)
VALUES
(83, '831', 'Fondo para la Recuperación, Conservación y Mantenimiento de Playas'),
(83, '832', 'Fondo para la Vigilancia, Administración, Mantenimiento, Preservación y Limpieza de la Zona Federal Marítimo Terrestre (ZOFEMAT)'),
(83, '833', 'Derecho por Acceso a Museos, Monumentos y Zonas Arqueológicas (DUZA)'),
(83, '834', 'Fondo para el Fortalecimiento de la Infraestructura Estatal y Municipal'),
(83, '835', 'Brigadas de Protección de Manejo del Fuego'),
(83, '836', 'De la Expedición de Licencias y Permisos para Conducir');

-- ── Clase 8.4.x — Incentivos Colaboración Fiscal ─────────────────
INSERT INTO catalogos.cat_cri_clase (id_tipo, codigo_clase, nombre)
VALUES
(84, '841', 'Impuesto Sobre Tenencia o Uso de Vehículos'),
(84, '842', 'Fondo de Compensación del ISAN'),
(84, '843', 'Impuesto Sobre Automóviles Nuevos (ISAN)'),
(84, '844', 'Incentivos ZOFEMAT (Cobro Art. 232-C Ley Federal de Derechos)'),
(84, '845', 'ISR de Enajenación de Bienes Inmuebles'),
(84, '846', 'Incentivos por Inspección y Vigilancia (Multas Administrativas Federales no Fiscales)');

-- ── Clases de Impuestos (Rubro 1) ────────────────────────────────
INSERT INTO catalogos.cat_cri_clase (id_tipo, codigo_clase, nombre)
VALUES
-- 1.1.x
(11, '111', 'Del Impuesto sobre Diversiones, Video Juegos, Cines y Espectáculos Públicos'),
(11, '112', 'Del Impuesto sobre Juegos Permitidos, Rifas y Loterías'),
(11, '113', 'Del Impuesto a Músicos y Cancioneros Profesionales'),
-- 1.2.x
(12, '121', 'Del Impuesto Predial'),
(12, '122', 'Del Impuesto sobre el Uso o Tenencia de Vehículos que no Consuman Gasolina ni Otro Derivado del Petróleo'),
-- 1.3.x
(13, '131', 'Del Impuesto sobre Adquisición de Bienes Inmuebles (ISABI)'),
-- 1.7.x
(17, '171', 'Recargos de Impuestos'),
(17, '172', 'Sanciones por Impuestos'),
(17, '173', 'Gastos de Ejecución de Impuestos'),
(17, '174', 'Indemnizaciones de Impuestos');
GO

-- ══════════════════════════════════════════════════════════════════
-- SECCIÓN 5: VISTA OPERATIVA
-- ══════════════════════════════════════════════════════════════════

CREATE VIEW catalogos.v_cri_completo AS
SELECT
  r.codigo_rubro,
  r.nombre              AS nombre_rubro,
  t.codigo_tipo,
  t.nombre              AS nombre_tipo,
  t.derogado,
  t.aplica_municipios,
  t.cuenta_contable,
  c.codigo_clase,
  c.nombre              AS nombre_clase
FROM catalogos.cat_cri_rubro r
JOIN catalogos.cat_cri_tipo  t ON t.id_rubro = r.id_rubro
LEFT JOIN catalogos.cat_cri_clase c ON c.id_tipo  = t.id_tipo
WHERE r.activo = 1 AND t.activo = 1
GO

CREATE VIEW catalogos.v_cri_municipios AS
SELECT
  r.codigo_rubro,
  r.nombre              AS nombre_rubro,
  t.codigo_tipo,
  t.nombre              AS nombre_tipo,
  t.derogado,
  t.cuenta_contable
FROM catalogos.cat_cri_rubro r
JOIN catalogos.cat_cri_tipo  t ON t.id_rubro = r.id_rubro
WHERE r.activo = 1
  AND t.activo = 1
  AND t.derogado = 0
  AND t.aplica_municipios = 1
GO

-- ══════════════════════════════════════════════════════════════════
-- SECCIÓN 6: MAPPING CRI ↔ LEY DE INGRESOS TULUM 2026
-- Equivalencia exacta entre la estructura de la Ley de Ingresos
-- de Tulum 2026 y los códigos CRI del CONAC
-- ══════════════════════════════════════════════════════════════════
/*
╔══════════════════════════════════════════════════════════════════════════════════╗
║  TULUM 2026 — Equivalencia Ley de Ingresos ↔ CRI CONAC                         ║
╠══════════╦══════════╦═════════════════════════════════════╦════════════════════╣
║  Ley     ║  CRI     ║  Concepto                           ║  Estimado 2026     ║
╠══════════╬══════════╬═════════════════════════════════════╬════════════════════╣
║  1.1.1   ║  1.1.x   ║  Diversiones / Cines / Espectáculos ║    $437,424        ║
║  1.1.2   ║  1.1.x   ║  Juegos permitidos, rifas y loterías║          $1        ║
║  1.1.3   ║  1.1.x   ║  Músicos y cancioneros              ║          $1        ║
║  1.2.1   ║  1.2.1   ║  Impuesto Predial                   ║$211,672,452        ║
║  1.3.1   ║  1.3.1   ║  ISABI                              ║$320,085,400        ║
║  1.7.1   ║  1.7.1   ║  Recargos                           ║ $11,182,595        ║
║  1.7.2   ║  1.7.2   ║  Sanciones                          ║  $1,716,957        ║
║  4.1.1   ║  4.1.1   ║  Cooperación obras públicas         ║ $21,394,103        ║
║  4.1.2   ║  4.1.2   ║  Uso de vía pública y bienes comunes║  $2,844,553        ║
║  4.3.1   ║  4.3.1   ║  Servicio de Tránsito               ║    $388,934        ║
║  4.3.2   ║  4.3.2   ║  Registro Civil Municipal           ║  $1,642,105        ║
║  4.3.3   ║  4.3.3   ║  Desarrollo Urbano                  ║$103,980,705        ║
║  4.3.4   ║  4.3.4   ║  Certificaciones                    ║  $1,934,150        ║
║  4.3.5   ║  4.3.5   ║  Panteones                          ║    $699,901        ║
║  4.3.6   ║  4.3.6   ║  Alineamientos/Catastro             ║ $40,685,827        ║
║  4.3.7   ║  4.3.7   ║  Licencias de Funcionamiento        ║ $14,943,922        ║
║  4.3.8   ║  4.3.8   ║  Lic. Horas Extraordinarias         ║  $4,134,295        ║
║  4.3.14  ║  4.3.10  ║  Anuncios                           ║  $6,235,742        ║
║  4.3.19  ║  4.3.14  ║  Recolección de Residuos Sólidos    ║ $27,359,300        ║
║  4.3.22  ║  4.3.22  ║  Ecología y Protección al Ambiente  ║ $17,689,053        ║
║  4.3.23  ║  4.3.23  ║  Protección Civil                   ║ $20,578,636        ║
║  4.3.25  ║  4.3.25  ║  DERECHO DE SANEAMIENTO AMBIENTAL   ║ $95,610,643        ║
║  4.3.26  ║  4.3.26  ║  Alumbrado Público                  ║ $36,395,275        ║
║  8.1.1   ║  8.1.1   ║  Fondo General de Participaciones   ║$155,042,945        ║
║  8.1.2   ║  8.1.2   ║  Fondo de Fomento Municipal         ║ $36,282,448        ║
║  8.1.3   ║  8.1.3   ║  Fiscalización y Recaudación        ║ $20,762,992        ║
║  8.2.1   ║  8.2.1   ║  FAIS Municipal                     ║ $56,392,992        ║
║  8.2.2   ║  8.2.2   ║  FORTAMUN                           ║ $49,536,128        ║
║  8.3.2   ║  8.3.2   ║  Fondo Vigilancia ZOFEMAT           ║ $15,329,022        ║
║  8.3.3   ║  8.3.3   ║  Zonas Arqueológicas (DUZA)         ║  $4,273,057        ║
║  8.4.4   ║  8.4.4   ║  Incentivos ZOFEMAT                 ║ $35,767,717        ║
╚══════════╩══════════╩═════════════════════════════════════╩════════════════════╝

TOTAL INGRESOS TULUM 2026: $1,408,647,182
*/

-- ══════════════════════════════════════════════════════════════════
-- SECCIÓN 7: HISTORIAL DE REFORMAS DEL CRI
-- ══════════════════════════════════════════════════════════════════
/*
╔════════════════════════════════════════════════════════════════════════════╗
║  HISTORIAL LEGISLATIVO DEL CRI                                            ║
╠══════════════╦════════════════════════════════════════════════════════════╣
║  Fecha DOF   ║  Evento                                                    ║
╠══════════════╬════════════════════════════════════════════════════════════╣
║  31-12-2008  ║  Publicación de la Ley General de Contabilidad             ║
║              ║  Gubernamental (LGCG). Obliga a todos los entes públicos   ║
║              ║  a adoptar el CRI                                          ║
╠══════════════╬════════════════════════════════════════════════════════════╣
║  09-12-2009  ║  Acuerdo CONAC: se EMITE el CRI por primera vez           ║
║              ║  DOF: Acuerdo original. Plazo adopción municipal:          ║
║              ║  31 de diciembre de 2010                                   ║
╠══════════════╬════════════════════════════════════════════════════════════╣
║  02-01-2013  ║  "Mejoras a los documentos aprobados por el CONAC"        ║
║              ║  Se DEROGAN tipos: 52 Productos de Capital,               ║
║              ║  92 Transferencias, 94 Ayudas Sociales,                   ║
║              ║  96 Transferencias a Fideicomisos                          ║
╠══════════════╬════════════════════════════════════════════════════════════╣
║  11-06-2018  ║  Acuerdo por el que se REFORMA Y ADICIONA el CRI          ║
║              ║  Primera reforma sustantiva. Actualiza descripciones       ║
║              ║  y aclara alcances de varios tipos                         ║
╠══════════════╬════════════════════════════════════════════════════════════╣
║  27-09-2018  ║  Segundo acuerdo de reforma del CRI                       ║
║              ║  Ajustes adicionales a tipos del Rubro 8                   ║
╠══════════════╬════════════════════════════════════════════════════════════╣
║  09-08-2023  ║  Acuerdo de reforma más reciente (aplicación 01-01-2024)  ║
║              ║  REFORMA: Rubro 5 Productos / Tipo 51                     ║
║              ║  REFORMA: Rubro 6 / Tipo 62 Aprovechamientos Patrimoniales║
║              ║  DEROGAN: párrafos de aspectos generales y transitorio 3  ║
╠══════════════╬════════════════════════════════════════════════════════════╣
║  04-07-2024  ║  Reforma al Manual de Contabilidad Gubernamental          ║
║              ║  El Estado Analítico de Ingresos usa explícitamente       ║
║              ║  la estructura del CRI como base de presentación          ║
╚══════════════╩════════════════════════════════════════════════════════════╝

FUENTES LEGALES DIRECTAS:
  · Ley General de Contabilidad Gubernamental (LGCG), DOF 31-12-2008
    Arts. 6 (obligatoriedad), 7 (entidades obligadas), 9 fracc. I (CONAC)
  · Acuerdo CONAC original CRI, DOF 09-12-2009
  · Mejoras CONAC, DOF 02-01-2013
  · Acuerdo reforma CRI, DOF 11-06-2018
  · Acuerdo reforma CRI, DOF 27-09-2018
  · Acuerdo reforma CRI (vigente 2024), DOF 09-08-2023
  · Reforma Manual Contabilidad, DOF 04-07-2024
  · NOR_01_02_001 — Norma CRI, conac.gob.mx
  · NOR_01_09_001 — Estado Analítico de Ingresos, conac.gob.mx
*/

-- ══════════════════════════════════════════════════════════════════
-- ENDPOINTS REST — Referencia FastAPI
-- ══════════════════════════════════════════════════════════════════
/*
GET  /api/v1/cri/rubros                          → todos los rubros
GET  /api/v1/cri/rubros/{codigo}/tipos           → tipos de un rubro
GET  /api/v1/cri/rubros/{codigo}/tipos/{tipo}/clases  → clases de un tipo
GET  /api/v1/cri/completo                        → árbol jerárquico completo
GET  /api/v1/cri/municipios                      → solo los que aplican a municipios
GET  /api/v1/cri/buscar?q=predial                → búsqueda por texto
GET  /api/v1/cri/tulum/mapping                   → mapping Tulum 2026 ↔ CRI
*/
