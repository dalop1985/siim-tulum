-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  SIIM — MÓDULO ISABI                                                     ║
-- ║  isabi.cat_tipo_operacion                                                ║
-- ║  Catálogo de Tipos de Operación para el Traslado de Dominio              ║
-- ║                                                                          ║
-- ║  Fundamento legal:                                                       ║
-- ║  · Ley del ISABI de los Municipios del Estado de Quintana Roo            ║
-- ║    (POE 03-10-2011, última reforma 21-12-2016) — Arts. 5, 6, 7, 8, 9, 10║
-- ║  · Ley de Hacienda del Municipio de Tulum — Arts. 46 Bis al 46 Undécies ║
-- ║  · Código Civil Federal — Arts. 2248, 2322, 2332, 2527 y relativos       ║
-- ║  · Ley General de Títulos y Operaciones de Crédito — Art. 381 (fideicom.)║
-- ╚══════════════════════════════════════════════════════════════════════════╝

SET NOCOUNT ON;
GO

-- ══════════════════════════════════════════════════════════════════
-- SECCIÓN 1: DDL — isabi.cat_tipo_operacion
-- ══════════════════════════════════════════════════════════════════
CREATE TABLE isabi.cat_tipo_operacion (
  id_tipo_operacion         INT          IDENTITY(1,1) NOT NULL,
  -- Identificación
  clave                     VARCHAR(60)  NOT NULL,
  nombre                    VARCHAR(300) NOT NULL,
  nombre_corto              VARCHAR(100) NOT NULL,
  descripcion               NVARCHAR(MAX) NULL,
  -- Sustento legal
  fundamento_legal          VARCHAR(500) NULL,   -- "Art. 5, inciso a) Ley ISABI QRoo"
  articulo_ley              VARCHAR(100) NULL,
  -- ─── Comportamiento fiscal ───────────────────────────────────
  genera_isabi              BIT          NOT NULL CONSTRAINT DF_toper_isabi   DEFAULT 1,
  tasa_isabi_pct            DECIMAL(6,4) NULL,   -- 2.0000 = 2% | 0 = exento
  genera_adicional_turismo  BIT          NOT NULL CONSTRAINT DF_toper_tur     DEFAULT 1,
  tasa_adicional_pct        DECIMAL(6,4) NULL,   -- 10.0000 = 10% sobre ISABI
  -- Notas: Adicional turismo = 10% de ISABI (Ley Hac. Tulum Art. 46 Bis y Ley
  --        Hac. Municipios QRoo Art. correspondiente)
  -- ─── Base de cálculo ─────────────────────────────────────────
  base_calculo              VARCHAR(50)  NULL,
  -- VALOR_MAS_ALTO       = MAX(precio_pactado, avalúo_catastral, avalúo_bancario)
  -- PRECIO_OPERACION     = solo el precio pactado (casos especiales)
  -- AVALUO_COMERCIAL     = avalúo practicado por valuador autorizado
  -- CINCUENTA_PCT_VALOR  = usufructo / nuda propiedad = 50% del valor pleno
  -- SIN_BASE             = no causa impuesto
  aplica_factor_50pct       BIT          NOT NULL CONSTRAINT DF_toper_50pct   DEFAULT 0,
  -- ─── Momento de causación (días hábiles) ─────────────────────
  dias_pago_habiles         TINYINT      NOT NULL CONSTRAINT DF_toper_dias    DEFAULT 15,
  momento_causacion         VARCHAR(200) NULL,   -- descripción del momento legal
  -- ─── Documentación requerida ─────────────────────────────────
  requiere_escritura_publica   BIT  NOT NULL CONSTRAINT DF_req_escritura DEFAULT 1,
  requiere_avaluo              BIT  NOT NULL CONSTRAINT DF_req_avaluo    DEFAULT 1,
  requiere_predial_vigente     BIT  NOT NULL CONSTRAINT DF_req_predial   DEFAULT 1,
  requiere_acta_defuncion      BIT  NOT NULL CONSTRAINT DF_req_defuncion DEFAULT 0,
  requiere_declaratoria_hered  BIT  NOT NULL CONSTRAINT DF_req_herederos DEFAULT 0,
  requiere_const_zofemat       BIT  NOT NULL CONSTRAINT DF_req_zofemat   DEFAULT 0,
  requiere_resolucion_judicial BIT  NOT NULL CONSTRAINT DF_req_judicial  DEFAULT 0,
  requiere_acta_asamblea       BIT  NOT NULL CONSTRAINT DF_req_asamblea  DEFAULT 0,
  requiere_contrato_fideicom   BIT  NOT NULL CONSTRAINT DF_req_fideicom  DEFAULT 0,
  documentacion_adicional      NVARCHAR(MAX) NULL,  -- JSON o texto libre
  -- ─── Exenciones ──────────────────────────────────────────────
  puede_ser_exento          BIT          NOT NULL CONSTRAINT DF_toper_exento  DEFAULT 0,
  condicion_exencion        NVARCHAR(MAX) NULL,
  exento_por_ley            BIT          NOT NULL CONSTRAINT DF_toper_ex_ley  DEFAULT 0,
  -- ─── Afecta catastro ─────────────────────────────────────────
  actualiza_propietario_catastro BIT     NOT NULL CONSTRAINT DF_toper_catastro DEFAULT 1,
  genera_historial_propietario   BIT     NOT NULL CONSTRAINT DF_toper_historial DEFAULT 1,
  -- ─── Partes involucradas ─────────────────────────────────────
  nombre_parte_transmite    VARCHAR(100) NULL,   -- ej: "Vendedor / Donante / Fiduciaria"
  nombre_parte_adquiere     VARCHAR(100) NULL,   -- ej: "Comprador / Donatario / Fideicomisario"
  -- ─── Clasificación ───────────────────────────────────────────
  grupo                     VARCHAR(50)  NULL,
  -- ONEROSA / GRATUITA / JUDICIAL / FIDEICOMISO / ESPECIAL / EXENTA
  es_onerosa                BIT          NOT NULL CONSTRAINT DF_toper_onerosa DEFAULT 1,
  es_modalidad_de           INT          NULL FK -- para indicar que es variante de otro tipo
    REFERENCES isabi.cat_tipo_operacion(id_tipo_operacion),
  -- ─── Meta ────────────────────────────────────────────────────
  activo                    BIT          NOT NULL CONSTRAINT DF_toper_activo  DEFAULT 1,
  orden_display             INT          NULL,
  notas_internas            VARCHAR(1000) NULL,
  -- Auditoría estándar
  fecha_creacion            DATETIME2(0) NOT NULL CONSTRAINT DF_toper_fcreac  DEFAULT GETDATE(),
  fecha_modificacion        DATETIME2(0) NULL,
  id_usuario_creacion       INT          NULL,
  id_usuario_modificacion   INT          NULL,
  -- Constraints
  CONSTRAINT PK_cat_tipo_operacion PRIMARY KEY (id_tipo_operacion),
  CONSTRAINT UQ_tipo_operacion_clave UNIQUE (clave),
  CONSTRAINT CK_tipo_op_base CHECK (base_calculo IN (
    'VALOR_MAS_ALTO','PRECIO_OPERACION','AVALUO_COMERCIAL',
    'CINCUENTA_PCT_VALOR','SIN_BASE', NULL))
);
GO

CREATE INDEX IX_tipo_op_grupo  ON isabi.cat_tipo_operacion (grupo, activo);
CREATE INDEX IX_tipo_op_isabi  ON isabi.cat_tipo_operacion (genera_isabi, activo);
GO

-- ══════════════════════════════════════════════════════════════════════════
-- SECCIÓN 2: SEED COMPLETO
-- Los 19 tipos reconocidos + 3 tipos especiales para Tulum/QRoo
-- Ordenados por: grupo y frecuencia de uso
-- ══════════════════════════════════════════════════════════════════════════

-- ════════════════════════════════════════════
-- GRUPO 1: ONEROSAS — Transmisión a título oneroso
-- Fundamento: Art. 5 incisos a), b), d), j) Ley ISABI QRoo
-- ════════════════════════════════════════════

-- ── 01. COMPRAVENTA ───────────────────────────────────────────────────────
INSERT INTO isabi.cat_tipo_operacion (
  clave, nombre, nombre_corto, descripcion, fundamento_legal, articulo_ley,
  genera_isabi, tasa_isabi_pct, genera_adicional_turismo, tasa_adicional_pct,
  base_calculo, aplica_factor_50pct, dias_pago_habiles, momento_causacion,
  requiere_escritura_publica, requiere_avaluo, requiere_predial_vigente,
  requiere_acta_defuncion, requiere_declaratoria_hered, requiere_const_zofemat,
  puede_ser_exento, condicion_exencion,
  actualiza_propietario_catastro, genera_historial_propietario,
  nombre_parte_transmite, nombre_parte_adquiere,
  grupo, es_onerosa, orden_display
) VALUES (
  'COMPRAVENTA',
  'Compraventa de Bien Inmueble',
  'Compraventa',
  'Contrato por el cual el vendedor transmite la propiedad del inmueble al comprador a cambio de un precio cierto y determinado en dinero. Es el acto traslativo más frecuente. El comprador es el sujeto del impuesto.',
  'Art. 5 inciso a) Ley ISABI Municipios QRoo; Art. 2248 Código Civil Federal; Art. 11 Ley ISABI QRoo',
  'Art. 5-a',
  1, 2.0000, 1, 10.0000,
  'VALOR_MAS_ALTO', 0, 15,
  'A los 15 días hábiles siguientes a la firma de la escritura pública o, si no requiere escritura, desde que se adquiere el dominio conforme a las leyes.',
  1, 1, 1, 0, 0, 0,
  0, NULL,
  1, 1,
  'Vendedor / Enajenante', 'Comprador / Adquiriente',
  'ONEROSA', 1, 10
);

-- ── 02. COMPRAVENTA CON RESERVA DE DOMINIO ───────────────────────────────
INSERT INTO isabi.cat_tipo_operacion (
  clave, nombre, nombre_corto, descripcion, fundamento_legal, articulo_ley,
  genera_isabi, tasa_isabi_pct, genera_adicional_turismo, tasa_adicional_pct,
  base_calculo, dias_pago_habiles, momento_causacion,
  requiere_escritura_publica, requiere_avaluo, requiere_predial_vigente,
  puede_ser_exento, condicion_exencion,
  actualiza_propietario_catastro, genera_historial_propietario,
  nombre_parte_transmite, nombre_parte_adquiere,
  grupo, es_onerosa, orden_display, notas_internas,
  es_modalidad_de
) VALUES (
  'COMPRAVENTA_RESERVA_DOMINIO',
  'Compraventa con Reserva de Dominio o Sujeta a Condición',
  'CV Reserva Dominio',
  'Contrato de compraventa en el que el vendedor conserva la propiedad del inmueble hasta que el comprador cumpla determinadas condiciones (generalmente el pago total del precio). El ISABI se causa desde la celebración del contrato, aunque la propiedad aún no se haya transmitido formalmente.',
  'Art. 5 inciso b) Ley ISABI Municipios QRoo; Art. 11-VI Ley ISABI QRoo',
  'Art. 5-b',
  1, 2.0000, 1, 10.0000,
  'VALOR_MAS_ALTO', 15,
  'A los 15 días hábiles desde la celebración del contrato, aunque no se haya elevado a escritura pública.',
  1, 1, 1,
  0, NULL,
  1, 1,
  'Vendedor / Promitente vendedor', 'Comprador / Promitente comprador',
  'ONEROSA', 1, 11, 'Muy frecuente en desarrollos inmobiliarios y preventas turísticas en Tulum.',
  NULL -- se asignará a COMPRAVENTA si se desea marcar como variante
);

-- ── 03. PERMUTA ──────────────────────────────────────────────────────────
INSERT INTO isabi.cat_tipo_operacion (
  clave, nombre, nombre_corto, descripcion, fundamento_legal, articulo_ley,
  genera_isabi, tasa_isabi_pct, genera_adicional_turismo, tasa_adicional_pct,
  base_calculo, dias_pago_habiles, momento_causacion,
  requiere_escritura_publica, requiere_avaluo, requiere_predial_vigente,
  puede_ser_exento, condicion_exencion,
  actualiza_propietario_catastro, genera_historial_propietario,
  nombre_parte_transmite, nombre_parte_adquiere,
  grupo, es_onerosa, orden_display, notas_internas
) VALUES (
  'PERMUTA',
  'Permuta de Bien Inmueble',
  'Permuta',
  'Contrato en el que cada una de las partes transmite un bien por otro. No interviene dinero como contraprestación principal. Cuando al menos uno de los bienes permutados es un inmueble, se causa ISABI. Cada adquiriente paga sobre el valor del inmueble que recibe.',
  'Art. 5 inciso d) Ley ISABI Municipios QRoo; Arts. 2322-2331 Código Civil Federal',
  'Art. 5-d',
  1, 2.0000, 1, 10.0000,
  'VALOR_MAS_ALTO', 15,
  'A los 15 días hábiles desde la firma de la escritura pública.',
  1, 1, 1,
  0, NULL,
  1, 1,
  'Permutante (transmite su bien)', 'Permutante (recibe el inmueble)',
  'ONEROSA', 1, 20,
  'Cada permutante es sujeto del impuesto por el bien inmueble que adquiere. Se generan dos operaciones ISABI si ambos bienes son inmuebles.'
);

-- ── 04. DACIÓN EN PAGO ───────────────────────────────────────────────────
INSERT INTO isabi.cat_tipo_operacion (
  clave, nombre, nombre_corto, descripcion, fundamento_legal, articulo_ley,
  genera_isabi, tasa_isabi_pct, genera_adicional_turismo, tasa_adicional_pct,
  base_calculo, dias_pago_habiles, momento_causacion,
  requiere_escritura_publica, requiere_avaluo, requiere_predial_vigente,
  puede_ser_exento, condicion_exencion,
  actualiza_propietario_catastro, genera_historial_propietario,
  nombre_parte_transmite, nombre_parte_adquiere,
  grupo, es_onerosa, orden_display
) VALUES (
  'DACION_EN_PAGO',
  'Adquisición de Inmueble en Dación en Pago',
  'Dación en Pago',
  'El deudor entrega un bien inmueble a su acreedor para saldar una obligación en lugar de pagar en dinero. El ISABI se causa en el momento de la celebración del convenio respectivo. La base es el avalúo comercial practicado por persona autorizada a partir de esa fecha.',
  'Art. 5 inciso j) y Art. 10 fracción IV Ley ISABI Municipios QRoo; Art. 2095 Código Civil Federal',
  'Art. 5-j / Art. 10-IV',
  1, 2.0000, 1, 10.0000,
  'AVALUO_COMERCIAL', 15,
  'A los 15 días hábiles desde la celebración del convenio de dación en pago (no desde la escritura).',
  1, 1, 1,
  0, NULL,
  1, 1,
  'Deudor / Dador', 'Acreedor / Receptor del pago en especie',
  'ONEROSA', 1, 30
);

-- ── 05. CESIÓN DE DERECHOS DE PROMESA / CONTRATO PRIVADO ─────────────────
INSERT INTO isabi.cat_tipo_operacion (
  clave, nombre, nombre_corto, descripcion, fundamento_legal, articulo_ley,
  genera_isabi, tasa_isabi_pct, genera_adicional_turismo, tasa_adicional_pct,
  base_calculo, dias_pago_habiles, momento_causacion,
  requiere_escritura_publica, requiere_avaluo, requiere_predial_vigente,
  puede_ser_exento, condicion_exencion,
  actualiza_propietario_catastro, genera_historial_propietario,
  nombre_parte_transmite, nombre_parte_adquiere,
  grupo, es_onerosa, orden_display, notas_internas
) VALUES (
  'CESION_DERECHOS_CONTRATO',
  'Cesión de Derechos derivados de Contrato de Promesa o Contrato Privado',
  'Cesión de Derechos',
  'Transmisión por parte del promitente comprador o acreedor de sus derechos sobre un inmueble a un tercero, sin llegar aún a la escrituración. Es muy común en preventa de desarrollos inmobiliarios en Tulum. Obliga al fraccionador a remitir copia del contrato a la Tesorería en 30 días.',
  'Art. 13 Ley ISABI QRoo; Art. 5 inciso a) Ley ISABI QRoo',
  'Art. 13',
  1, 2.0000, 1, 10.0000,
  'VALOR_MAS_ALTO', 15,
  'Al elevarse a escritura pública o al inscribirse en el RPP. El fraccionador debe remitir copia del contrato a la Tesorería a más tardar en 30 días naturales de su celebración.',
  0, 1, 1,  -- escritura no requerida al inicio (contrato privado)
  0, NULL,
  0, 0,   -- no actualiza catastro hasta escritura
  'Cedente (promitente comprador original)', 'Cesionario (nuevo adquiriente de derechos)',
  'ONEROSA', 1, 35,
  'Muy frecuente en preventa de condominios turísticos en Tulum. Genera obligación de reporte para el fraccionador/desarrollador.'
);

-- ════════════════════════════════════════════
-- GRUPO 2: GRATUITAS — Transmisión a título gratuito
-- ════════════════════════════════════════════

-- ── 06. DONACIÓN ─────────────────────────────────────────────────────────
INSERT INTO isabi.cat_tipo_operacion (
  clave, nombre, nombre_corto, descripcion, fundamento_legal, articulo_ley,
  genera_isabi, tasa_isabi_pct, genera_adicional_turismo, tasa_adicional_pct,
  base_calculo, dias_pago_habiles, momento_causacion,
  requiere_escritura_publica, requiere_avaluo, requiere_predial_vigente,
  puede_ser_exento, condicion_exencion,
  actualiza_propietario_catastro, genera_historial_propietario,
  nombre_parte_transmite, nombre_parte_adquiere,
  grupo, es_onerosa, orden_display, notas_internas
) VALUES (
  'DONACION',
  'Donación de Bien Inmueble',
  'Donación',
  'Contrato por el cual una persona (donante) transmite gratuitamente una parte o la totalidad de sus bienes presentes a otra persona (donatario). Al ser una adquisición de bien inmueble, causa ISABI incluso siendo gratuita. El donatario paga sobre el valor del bien como si hiciera una compraventa.',
  'Art. 5 inciso a) Ley ISABI QRoo (adquisición general); Arts. 2332-2360 Código Civil Federal; Art. 11 Ley ISABI QRoo',
  'Art. 5-a',
  1, 2.0000, 1, 10.0000,
  'VALOR_MAS_ALTO', 15,
  'A los 15 días hábiles desde la firma de la escritura pública de donación.',
  1, 1, 1,
  1, 'En Quintana Roo, la donación entre cónyuge, concubino/a, descendientes en primer grado puede beneficiarse de condiciones especiales conforme al Código Civil. Verificar legislación local vigente.',
  1, 1,
  'Donante', 'Donatario',
  'GRATUITA', 0, 40,
  'Aunque es gratuita, el ISABI se causa igual que en compraventa. El donatario no puede argumentar que no pagó para evitar el impuesto.'
);

-- ── 07. HERENCIA (Adjudicación por herencia testamentaria) ───────────────
INSERT INTO isabi.cat_tipo_operacion (
  clave, nombre, nombre_corto, descripcion, fundamento_legal, articulo_ley,
  genera_isabi, tasa_isabi_pct, genera_adicional_turismo, tasa_adicional_pct,
  base_calculo, dias_pago_habiles, momento_causacion,
  requiere_escritura_publica, requiere_avaluo, requiere_predial_vigente,
  requiere_acta_defuncion, requiere_declaratoria_hered,
  puede_ser_exento, condicion_exencion,
  actualiza_propietario_catastro, genera_historial_propietario,
  nombre_parte_transmite, nombre_parte_adquiere,
  grupo, es_onerosa, orden_display, notas_internas
) VALUES (
  'HERENCIA',
  'Transmisión de Propiedad por Herencia Testamentaria',
  'Herencia',
  'Transmisión de la propiedad de bienes inmuebles que forma parte de una sucesión testamentaria. El impuesto se causa al momento de la adjudicación formal del bien a nombre del heredero mediante escritura pública. Si no se adjudica en 3 años desde el fallecimiento, el impuesto se causa a los 3 años.',
  'Art. 5 inciso h) y Art. 10 fracción II Ley ISABI QRoo; Arts. 1281 et seq. Código Civil Federal',
  'Art. 5-h / Art. 10-II',
  1, 2.0000, 1, 10.0000,
  'VALOR_MAS_ALTO', 15,
  'A los 15 días hábiles desde la adjudicación escriturada, o a los 3 años del fallecimiento si no se escrituró antes. Si se ceden los derechos hereditarios antes, el impuesto se causa en ese momento.',
  1, 1, 1,
  1, 1,  -- requiere acta de defunción + declaratoria de herederos
  0, NULL,
  1, 1,
  'De Cujus / Causante (fallecido)', 'Heredero / Legatario',
  'GRATUITA', 0, 50,
  'Requiere juicio sucesorio previo o testamento abierto ante notario. La adjudicación debe protocolizarse. Si hay varios herederos, puede haber copropiedad previa a la adjudicación individual.'
);

-- ── 08. LEGADO ────────────────────────────────────────────────────────────
INSERT INTO isabi.cat_tipo_operacion (
  clave, nombre, nombre_corto, descripcion, fundamento_legal, articulo_ley,
  genera_isabi, tasa_isabi_pct, genera_adicional_turismo, tasa_adicional_pct,
  base_calculo, dias_pago_habiles, momento_causacion,
  requiere_escritura_publica, requiere_avaluo, requiere_predial_vigente,
  requiere_acta_defuncion, requiere_declaratoria_hered,
  puede_ser_exento, condicion_exencion,
  actualiza_propietario_catastro, genera_historial_propietario,
  nombre_parte_transmite, nombre_parte_adquiere,
  grupo, es_onerosa, orden_display, es_modalidad_de
) VALUES (
  'LEGADO',
  'Transmisión de Propiedad por Legado',
  'Legado',
  'El testador dispone en su testamento que un bien inmueble específico pase a una persona determinada (legatario), independientemente de quiénes sean los herederos universales. El legatario adquiere el bien directamente sin pasar por la masa hereditaria general.',
  'Art. 5 inciso h) y Art. 10 fracción II Ley ISABI QRoo; Arts. 1391 et seq. Código Civil Federal',
  'Art. 5-h',
  1, 2.0000, 1, 10.0000,
  'VALOR_MAS_ALTO', 15,
  'A los 15 días hábiles desde la adjudicación formal del legado, protocolizada ante notario.',
  1, 1, 1,
  1, 1,
  0, NULL,
  1, 1,
  'De Cujus / Testador (fallecido)', 'Legatario',
  'GRATUITA', 0, 51, NULL
);

-- ── 09. CESIÓN DE DERECHOS HEREDITARIOS ─────────────────────────────────
INSERT INTO isabi.cat_tipo_operacion (
  clave, nombre, nombre_corto, descripcion, fundamento_legal, articulo_ley,
  genera_isabi, tasa_isabi_pct, genera_adicional_turismo, tasa_adicional_pct,
  base_calculo, dias_pago_habiles, momento_causacion,
  requiere_escritura_publica, requiere_avaluo, requiere_predial_vigente,
  requiere_acta_defuncion, requiere_declaratoria_hered,
  puede_ser_exento, condicion_exencion,
  actualiza_propietario_catastro, genera_historial_propietario,
  nombre_parte_transmite, nombre_parte_adquiere,
  grupo, es_onerosa, orden_display, notas_internas
) VALUES (
  'CESION_DERECHOS_HEREDITARIOS',
  'Cesión de Derechos Hereditarios sobre Bien Inmueble',
  'Cesión Hereditaria',
  'Un heredero transmite a un tercero sus derechos sobre la herencia (o sobre un bien específico de la sucesión) antes de la adjudicación formal. Genera dos hechos imponibles: el que corresponde al cedente (por la herencia) y el que corresponde al cesionario (por la cesión), ambos causados en el momento de la cesión.',
  'Art. 10 fracción II párrafo 2 Ley ISABI QRoo',
  'Art. 10-II (párrafo 2)',
  1, 2.0000, 1, 10.0000,
  'VALOR_MAS_ALTO', 15,
  'A los 15 días hábiles desde la cesión. Se causan DOS impuestos: el del heredero-cedente (por herencia) y el del cesionario (por la cesión).',
  1, 1, 1,
  1, 1,
  0, NULL,
  1, 1,
  'Heredero cedente', 'Cesionario (adquiriente de derechos hereditarios)',
  'ONEROSA', 1, 52,
  'Genera doble causación. Muy común en sucesiones donde herederos desean liquidar su parte sin esperar adjudicación formal.'
);

-- ════════════════════════════════════════════
-- GRUPO 3: JUDICIALES Y ADMINISTRATIVAS
-- ════════════════════════════════════════════

-- ── 10. REMATE JUDICIAL ──────────────────────────────────────────────────
INSERT INTO isabi.cat_tipo_operacion (
  clave, nombre, nombre_corto, descripcion, fundamento_legal, articulo_ley,
  genera_isabi, tasa_isabi_pct, genera_adicional_turismo, tasa_adicional_pct,
  base_calculo, dias_pago_habiles, momento_causacion,
  requiere_escritura_publica, requiere_avaluo, requiere_predial_vigente,
  requiere_resolucion_judicial,
  puede_ser_exento, condicion_exencion,
  actualiza_propietario_catastro, genera_historial_propietario,
  nombre_parte_transmite, nombre_parte_adquiere,
  grupo, es_onerosa, orden_display
) VALUES (
  'REMATE_JUDICIAL',
  'Adquisición por Remate Judicial',
  'Remate Judicial',
  'Adquisición de bien inmueble en subasta pública ordenada y supervisada por un juez, derivada de un proceso judicial (juicio ejecutivo, hipotecario, mercantil, familiar, etc.). El ISABI se causa al proporcionarse o inscribirse el remate judicial.',
  'Art. 5 inciso c) y Art. 10 fracción V Ley ISABI QRoo',
  'Art. 5-c / Art. 10-V',
  1, 2.0000, 1, 10.0000,
  'VALOR_MAS_ALTO', 15,
  'A los 15 días hábiles desde la inscripción o reconocimiento del remate judicial en el RPP.',
  1, 1, 1,
  1,   -- resolución judicial
  0, NULL,
  1, 1,
  'Ejecutado / Deudor hipotecario', 'Postor ganador / Rematante',
  'JUDICIAL', 1, 60
);

-- ── 11. REMATE ADMINISTRATIVO ────────────────────────────────────────────
INSERT INTO isabi.cat_tipo_operacion (
  clave, nombre, nombre_corto, descripcion, fundamento_legal, articulo_ley,
  genera_isabi, tasa_isabi_pct, genera_adicional_turismo, tasa_adicional_pct,
  base_calculo, dias_pago_habiles, momento_causacion,
  requiere_escritura_publica, requiere_avaluo, requiere_predial_vigente,
  requiere_resolucion_judicial,
  puede_ser_exento, condicion_exencion,
  actualiza_propietario_catastro, genera_historial_propietario,
  nombre_parte_transmite, nombre_parte_adquiere,
  grupo, es_onerosa, orden_display
) VALUES (
  'REMATE_ADMINISTRATIVO',
  'Adquisición por Remate Administrativo',
  'Remate Administrativo',
  'Adquisición de bien inmueble en subasta pública derivada de un procedimiento administrativo de ejecución fiscal (SAT, IMSS, municipio u otra autoridad fiscal). El inmueble del deudor es rematado para saldar créditos fiscales.',
  'Art. 5 inciso c) y Art. 10 fracción V Ley ISABI QRoo',
  'Art. 5-c / Art. 10-V',
  1, 2.0000, 1, 10.0000,
  'VALOR_MAS_ALTO', 15,
  'A los 15 días hábiles desde la inscripción en el RPP.',
  1, 1, 1,
  1,
  0, NULL,
  1, 1,
  'Deudor fiscal / Ejecutado', 'Postor ganador / Autoridad (si se adjudica)',
  'JUDICIAL', 1, 61
);

-- ── 12. ADJUDICACIÓN SUCESORIA ────────────────────────────────────────────
INSERT INTO isabi.cat_tipo_operacion (
  clave, nombre, nombre_corto, descripcion, fundamento_legal, articulo_ley,
  genera_isabi, tasa_isabi_pct, genera_adicional_turismo, tasa_adicional_pct,
  base_calculo, dias_pago_habiles, momento_causacion,
  requiere_escritura_publica, requiere_avaluo, requiere_predial_vigente,
  requiere_acta_defuncion, requiere_declaratoria_hered,
  puede_ser_exento, condicion_exencion,
  actualiza_propietario_catastro, genera_historial_propietario,
  nombre_parte_transmite, nombre_parte_adquiere,
  grupo, es_onerosa, orden_display, notas_internas
) VALUES (
  'ADJUDICACION_SUCESORIA',
  'Adjudicación por Remate en Sucesión (Adjudicación Sucesoria)',
  'Adjudicación Sucesoria',
  'Adquisición de bienes inmuebles como resultado de un procedimiento sucesorio intestamentario (sin testamento) o testamentario en que un juzgado declara los herederos y adjudica los bienes. Es distinto de la simple herencia porque implica declaratoria judicial.',
  'Art. 5 inciso c) y Art. 10 fracción II Ley ISABI QRoo',
  'Art. 5-c / Art. 10-II',
  1, 2.0000, 1, 10.0000,
  'VALOR_MAS_ALTO', 15,
  'A los 15 días hábiles desde la adjudicación formal o, si pasan 3 años del fallecimiento sin adjudicación, desde esa fecha.',
  1, 1, 1,
  1, 1,
  0, NULL,
  1, 1,
  'De Cujus / Causante (fallecido)', 'Heredero declarado judicialmente',
  'JUDICIAL', 0, 62,
  'Aplica principalmente en sucesiones intestamentarias (sin testamento) tramitadas ante juez de lo familiar.'
);

-- ── 13. PRESCRIPCIÓN POSITIVA (Usucapión) ────────────────────────────────
INSERT INTO isabi.cat_tipo_operacion (
  clave, nombre, nombre_corto, descripcion, fundamento_legal, articulo_ley,
  genera_isabi, tasa_isabi_pct, genera_adicional_turismo, tasa_adicional_pct,
  base_calculo, dias_pago_habiles, momento_causacion,
  requiere_escritura_publica, requiere_avaluo, requiere_predial_vigente,
  requiere_resolucion_judicial,
  puede_ser_exento, condicion_exencion,
  actualiza_propietario_catastro, genera_historial_propietario,
  nombre_parte_transmite, nombre_parte_adquiere,
  grupo, es_onerosa, orden_display
) VALUES (
  'PRESCRIPCION_POSITIVA',
  'Adquisición por Prescripción Positiva (Usucapión)',
  'Usucapión',
  'Adquisición del dominio de un inmueble por posesión continua, pacífica, pública y de buena fe durante el tiempo señalado en la ley. Requiere sentencia judicial que declare la prescripción. El ISABI se causa al inscribirse o reconocerse judicialmente la prescripción.',
  'Art. 10 fracción V Ley ISABI QRoo; Arts. 1135 et seq. Código Civil Federal',
  'Art. 10-V',
  1, 2.0000, 1, 10.0000,
  'AVALUO_COMERCIAL', 15,
  'A los 15 días hábiles desde la inscripción de la sentencia de prescripción en el RPP o desde su reconocimiento judicial.',
  1, 1, 1,
  1,
  0, NULL,
  1, 1,
  'Propietario registral (pierde el bien)', 'Poseedor / Usucapiente',
  'JUDICIAL', 0, 63
);

-- ════════════════════════════════════════════
-- GRUPO 4: FIDEICOMISO
-- Fundamento: Art. 5 incisos e), f), g) y Art. 10 fracción III Ley ISABI QRoo
-- Ley General de Títulos y Operaciones de Crédito (Art. 381 et seq.)
-- ════════════════════════════════════════════

-- ── 14. CONSTITUCIÓN DE FIDEICOMISO TRASLATIVO ────────────────────────────
INSERT INTO isabi.cat_tipo_operacion (
  clave, nombre, nombre_corto, descripcion, fundamento_legal, articulo_ley,
  genera_isabi, tasa_isabi_pct, genera_adicional_turismo, tasa_adicional_pct,
  base_calculo, dias_pago_habiles, momento_causacion,
  requiere_escritura_publica, requiere_avaluo, requiere_predial_vigente,
  requiere_contrato_fideicom,
  puede_ser_exento, condicion_exencion,
  actualiza_propietario_catastro, genera_historial_propietario,
  nombre_parte_transmite, nombre_parte_adquiere,
  grupo, es_onerosa, orden_display, notas_internas
) VALUES (
  'FIDEICOMISO_CONSTITUCION',
  'Constitución de Fideicomiso Traslativo de Dominio (aportación del fideicomitente)',
  'Fideicomiso Constitución',
  'Transmisión de la propiedad del inmueble que realiza el fideicomitente a la institución fiduciaria al constituirse el fideicomiso traslativo de dominio. En Quintana Roo, es extremadamente común para que extranjeros adquieran propiedades en la zona costera restringida (50 km de la costa), conforme a la Ley de Inversión Extranjera.',
  'Art. 5 inciso e) y Art. 10 fracción III Ley ISABI QRoo; Art. 27 CPEUM; Ley de Inversión Extranjera Art. 11',
  'Art. 5-e / Art. 10-III',
  1, 2.0000, 1, 10.0000,
  'VALOR_MAS_ALTO', 15,
  'Cuando se realicen los supuestos de enajenación en términos del Código Fiscal Municipal de Quintana Roo.',
  1, 1, 1,
  1,   -- contrato de fideicomiso
  0, NULL,
  1, 1,
  'Fideicomitente (aporta el inmueble)', 'Institución Fiduciaria (Banco)',
  'FIDEICOMISO', 1, 70,
  'Es EL acto más frecuente en Tulum para adquisición de propiedades por extranjeros. El banco actúa como fiduciario y el extranjero como fideicomisario. Requiere autorización SRE.'
);

-- ── 15. CUMPLIMIENTO DE FIDEICOMISO (fiduciaria transmite al fideicomisario)
INSERT INTO isabi.cat_tipo_operacion (
  clave, nombre, nombre_corto, descripcion, fundamento_legal, articulo_ley,
  genera_isabi, tasa_isabi_pct, genera_adicional_turismo, tasa_adicional_pct,
  base_calculo, dias_pago_habiles, momento_causacion,
  requiere_escritura_publica, requiere_avaluo, requiere_predial_vigente,
  requiere_contrato_fideicom,
  puede_ser_exento, condicion_exencion,
  actualiza_propietario_catastro, genera_historial_propietario,
  nombre_parte_transmite, nombre_parte_adquiere,
  grupo, es_onerosa, orden_display
) VALUES (
  'FIDEICOMISO_CUMPLIMIENTO',
  'Transmisión por la Fiduciaria en Cumplimiento del Fideicomiso',
  'Fideicomiso Cumplimiento',
  'La institución fiduciaria transmite la propiedad del inmueble al fideicomisario o a un tercero en cumplimiento de los fines del fideicomiso. Ocurre cuando el fideicomiso se extingue o cuando se cumplen las condiciones pactadas para la entrega del bien.',
  'Art. 5 inciso f) y Art. 10 fracción III Ley ISABI QRoo',
  'Art. 5-f / Art. 10-III',
  1, 2.0000, 1, 10.0000,
  'VALOR_MAS_ALTO', 15,
  'Cuando se realicen los supuestos de enajenación conforme al Código Fiscal Municipal.',
  1, 1, 1,
  1,
  0, NULL,
  1, 1,
  'Institución Fiduciaria (Banco)', 'Fideicomisario / Tercero designado',
  'FIDEICOMISO', 1, 71
);

-- ── 16. CESIÓN DE DERECHOS FIDEICOMISARIOS / SUSTITUCIÓN ─────────────────
INSERT INTO isabi.cat_tipo_operacion (
  clave, nombre, nombre_corto, descripcion, fundamento_legal, articulo_ley,
  genera_isabi, tasa_isabi_pct, genera_adicional_turismo, tasa_adicional_pct,
  base_calculo, dias_pago_habiles, momento_causacion,
  requiere_escritura_publica, requiere_avaluo, requiere_predial_vigente,
  requiere_contrato_fideicom,
  puede_ser_exento, condicion_exencion,
  actualiza_propietario_catastro, genera_historial_propietario,
  nombre_parte_transmite, nombre_parte_adquiere,
  grupo, es_onerosa, orden_display, notas_internas
) VALUES (
  'CESION_DERECHOS_FIDEICOMISO',
  'Cesión de Derechos de Fideicomitentes o Fideicomisarios (Sustitución)',
  'Cesión Fideicomisaria',
  'Sustitución de un fideicomitente o de un fideicomisario por cualquier motivo (compraventa de derechos fideicomisarios, donación, herencia). La ley considera que hay enajenación cuando existe sustitución. Es el mecanismo habitual para "vender" una propiedad que está en fideicomiso sin extinguir el fideicomiso.',
  'Art. 5 inciso g) Ley ISABI QRoo (reformado POE 30-10-2012)',
  'Art. 5-g',
  1, 2.0000, 1, 10.0000,
  'VALOR_MAS_ALTO', 15,
  'A los 15 días hábiles desde la formalización de la sustitución ante la institución fiduciaria y su inscripción.',
  1, 1, 1,
  1,
  0, NULL,
  1, 1,   -- se actualiza en catastro el beneficiario del fideicomiso
  'Fideicomisario / Fideicomitente original (cedente)', 'Nuevo Fideicomisario / Fideicomitente (cesionario)',
  'FIDEICOMISO', 1, 72,
  'Muy común en Tulum para venta de propiedades de extranjeros que están en fideicomiso bancario. El banco interviene como fiduciaria. No se extingue ni reconstituye el fideicomiso.'
);

-- ════════════════════════════════════════════
-- GRUPO 5: USUFRUCTO Y NUDA PROPIEDAD
-- Fundamento: Art. 10 fracción I + Art. 8 párrafo 4 Ley ISABI QRoo
-- ════════════════════════════════════════════

-- ── 17. USUFRUCTO ────────────────────────────────────────────────────────
INSERT INTO isabi.cat_tipo_operacion (
  clave, nombre, nombre_corto, descripcion, fundamento_legal, articulo_ley,
  genera_isabi, tasa_isabi_pct, genera_adicional_turismo, tasa_adicional_pct,
  base_calculo, aplica_factor_50pct, dias_pago_habiles, momento_causacion,
  requiere_escritura_publica, requiere_avaluo, requiere_predial_vigente,
  puede_ser_exento, condicion_exencion,
  actualiza_propietario_catastro, genera_historial_propietario,
  nombre_parte_transmite, nombre_parte_adquiere,
  grupo, es_onerosa, orden_display, notas_internas
) VALUES (
  'USUFRUCTO',
  'Constitución o Adquisición de Usufructo sobre Bien Inmueble',
  'Usufructo',
  'Derecho real que otorga a su titular (usufructuario) el derecho de usar y disfrutar un bien inmueble ajeno. La base del ISABI es el 50% del valor pleno del inmueble. Si el usufructo es temporal, el impuesto se paga al extinguirse también.',
  'Art. 10 fracción I y Art. 8 párrafo 4 Ley ISABI QRoo; Arts. 980 et seq. Código Civil Federal',
  'Art. 10-I / Art. 8',
  1, 2.0000, 1, 10.0000,
  'CINCUENTA_PCT_VALOR', 1, 15,
  'A los 15 días hábiles desde la constitución o adquisición del usufructo. Si es temporal, también al extinguirse.',
  1, 1, 1,
  0, NULL,
  0, 1,  -- no cambia propietario, pero hay historial
  'Nudo propietario / Constituyente', 'Usufructuario',
  'ESPECIAL', 1, 80,
  'Base = 50% del valor pleno. Cuando se extingue el usufructo temporal, el nudo propietario consolida la propiedad plena y vuelve a causar ISABI sobre el 50% restante.'
);

-- ── 18. NUDA PROPIEDAD ────────────────────────────────────────────────────
INSERT INTO isabi.cat_tipo_operacion (
  clave, nombre, nombre_corto, descripcion, fundamento_legal, articulo_ley,
  genera_isabi, tasa_isabi_pct, genera_adicional_turismo, tasa_adicional_pct,
  base_calculo, aplica_factor_50pct, dias_pago_habiles, momento_causacion,
  requiere_escritura_publica, requiere_avaluo, requiere_predial_vigente,
  puede_ser_exento, condicion_exencion,
  actualiza_propietario_catastro, genera_historial_propietario,
  nombre_parte_transmite, nombre_parte_adquiere,
  grupo, es_onerosa, orden_display
) VALUES (
  'NUDA_PROPIEDAD',
  'Adquisición de Nuda Propiedad de Bien Inmueble',
  'Nuda Propiedad',
  'Adquisición de la titularidad del inmueble sin el derecho de uso y disfrute (que corresponde al usufructuario). La base del ISABI es el 50% del valor pleno del inmueble. Al extinguirse el usufructo, el nudo propietario consolida el pleno dominio.',
  'Art. 8 párrafo 4 Ley ISABI QRoo; Arts. 980 et seq. Código Civil Federal',
  'Art. 8',
  1, 2.0000, 1, 10.0000,
  'CINCUENTA_PCT_VALOR', 1, 15,
  'A los 15 días hábiles desde la escritura pública de transmisión de la nuda propiedad.',
  1, 1, 1,
  0, NULL,
  1, 1,
  'Propietario pleno (transmite nuda)', 'Adquiriente de nuda propiedad',
  'ESPECIAL', 1, 81
);

-- ════════════════════════════════════════════
-- GRUPO 6: ARRENDAMIENTO FINANCIERO (Leasing Inmobiliario)
-- Fundamento: Art. 5 inciso i) Ley ISABI QRoo
-- ════════════════════════════════════════════

-- ── 19. CESIÓN DE DERECHOS DE ARRENDAMIENTO FINANCIERO ──────────────────
INSERT INTO isabi.cat_tipo_operacion (
  clave, nombre, nombre_corto, descripcion, fundamento_legal, articulo_ley,
  genera_isabi, tasa_isabi_pct, genera_adicional_turismo, tasa_adicional_pct,
  base_calculo, dias_pago_habiles, momento_causacion,
  requiere_escritura_publica, requiere_avaluo, requiere_predial_vigente,
  puede_ser_exento, condicion_exencion,
  actualiza_propietario_catastro, genera_historial_propietario,
  nombre_parte_transmite, nombre_parte_adquiere,
  grupo, es_onerosa, orden_display
) VALUES (
  'ARRENDAMIENTO_FINANCIERO_CESION',
  'Cesión de Derechos de Arrendamiento Financiero sobre Inmueble',
  'Leasing Inmobiliario',
  'Cesión de los derechos derivados de un contrato de arrendamiento financiero (leasing) sobre un inmueble, ya sea por el arrendatario a un tercero, o la adquisición directa del bien al ejercer la opción de compra por persona distinta al arrendatario original.',
  'Art. 5 inciso i) Ley ISABI QRoo; Arts. 408 et seq. Ley General de Títulos y Operaciones de Crédito',
  'Art. 5-i',
  1, 2.0000, 1, 10.0000,
  'VALOR_MAS_ALTO', 15,
  'A los 15 días hábiles desde la formalización de la cesión o de la adquisición.',
  1, 1, 1,
  0, NULL,
  1, 1,
  'Arrendatario cedente / Arrendador financiero', 'Cesionario / Nuevo adquiriente',
  'ESPECIAL', 1, 90
);

-- ════════════════════════════════════════════
-- GRUPO 7: CORPORATIVAS (Personas Morales)
-- No están explícitamente en la Ley ISABI QRoo pero
-- son actos traslativos frecuentes cubiertos por Art. 5-a
-- ════════════════════════════════════════════

-- ── 20. APORTACIÓN A PERSONA MORAL ───────────────────────────────────────
INSERT INTO isabi.cat_tipo_operacion (
  clave, nombre, nombre_corto, descripcion, fundamento_legal, articulo_ley,
  genera_isabi, tasa_isabi_pct, genera_adicional_turismo, tasa_adicional_pct,
  base_calculo, dias_pago_habiles, momento_causacion,
  requiere_escritura_publica, requiere_avaluo, requiere_predial_vigente,
  requiere_acta_asamblea,
  puede_ser_exento, condicion_exencion,
  actualiza_propietario_catastro, genera_historial_propietario,
  nombre_parte_transmite, nombre_parte_adquiere,
  grupo, es_onerosa, orden_display, notas_internas
) VALUES (
  'APORTACION_PERSONA_MORAL',
  'Aportación de Bien Inmueble a Persona Moral (Sociedad)',
  'Aportación a Sociedad',
  'Un socio aporta un bien inmueble al patrimonio de una persona moral (sociedad anónima, civil, de responsabilidad limitada, etc.) como parte de su aportación de capital. La sociedad adquiere la propiedad del inmueble y el aportante recibe acciones o partes sociales.',
  'Art. 5 inciso a) Ley ISABI QRoo (adquisición general); Ley General de Sociedades Mercantiles Arts. 11, 89',
  'Art. 5-a',
  1, 2.0000, 1, 10.0000,
  'VALOR_MAS_ALTO', 15,
  'A los 15 días hábiles desde la escritura pública de constitución o aumento de capital con aportación del inmueble.',
  1, 1, 1,
  1,   -- acta de asamblea de la sociedad
  0, NULL,
  1, 1,
  'Socio aportante (persona física o moral)', 'Sociedad adquiriente',
  'CORPORATIVA', 1, 100,
  'Muy común para desarrollo de proyectos inmobiliarios hoteleros en Tulum. Requiere avalúo para determinar valor de la aportación.'
);

-- ── 21. FUSIÓN / ESCISIÓN DE SOCIEDADES ──────────────────────────────────
INSERT INTO isabi.cat_tipo_operacion (
  clave, nombre, nombre_corto, descripcion, fundamento_legal, articulo_ley,
  genera_isabi, tasa_isabi_pct, genera_adicional_turismo, tasa_adicional_pct,
  base_calculo, dias_pago_habiles, momento_causacion,
  requiere_escritura_publica, requiere_avaluo, requiere_predial_vigente,
  requiere_acta_asamblea,
  puede_ser_exento, condicion_exencion,
  actualiza_propietario_catastro, genera_historial_propietario,
  nombre_parte_transmite, nombre_parte_adquiere,
  grupo, es_onerosa, orden_display
) VALUES (
  'FUSION_ESCISION',
  'Transmisión de Inmueble por Fusión o Escisión de Sociedades',
  'Fusión / Escisión',
  'Transmisión de la propiedad de bienes inmuebles que ocurre como consecuencia de una fusión (unión de dos o más sociedades) o escisión (división de una sociedad en varias). La sociedad fusionante o la escindida adquieren los inmuebles de las extintas.',
  'Art. 5 inciso a) Ley ISABI QRoo; LGSM Arts. 222 et seq. y 228 BIS',
  'Art. 5-a',
  1, 2.0000, 1, 10.0000,
  'VALOR_MAS_ALTO', 15,
  'A los 15 días hábiles desde la inscripción de la fusión/escisión en el RPP.',
  1, 1, 1,
  1,
  1, 'Posible exención bajo el artículo 14-B del CFF federal si se cumplen los requisitos de reestructura corporativa. Verificar con el SAT.',
  1, 1,
  'Sociedad fusionada / Escindente', 'Sociedad fusionante / Escindida',
  'CORPORATIVA', 1, 101
);

-- ════════════════════════════════════════════
-- GRUPO 8: EXENTAS — No causan ISABI
-- Fundamento: Art. 7 Ley ISABI QRoo
-- ════════════════════════════════════════════

-- ── 22. ADQUISICIÓN POR ORGANISMOS DE VIVIENDA ───────────────────────────
INSERT INTO isabi.cat_tipo_operacion (
  clave, nombre, nombre_corto, descripcion, fundamento_legal, articulo_ley,
  genera_isabi, tasa_isabi_pct, genera_adicional_turismo, tasa_adicional_pct,
  base_calculo, dias_pago_habiles, momento_causacion,
  requiere_escritura_publica, requiere_avaluo, requiere_predial_vigente,
  puede_ser_exento, exento_por_ley, condicion_exencion,
  actualiza_propietario_catastro, genera_historial_propietario,
  nombre_parte_transmite, nombre_parte_adquiere,
  grupo, es_onerosa, orden_display, notas_internas
) VALUES (
  'EXENTO_ORGANISMO_VIVIENDA',
  'Adquisición por Organismo Estatal o Municipal de Vivienda (Exento)',
  'Organismo Vivienda',
  'Adquisición de inmuebles realizada por dependencias, entidades u organismos estatales o municipales para la realización de acciones o programas de vivienda, su legalización y regularización. También aplica cuando el beneficiario final no es propietario de otro inmueble y destina el bien a casa habitación.',
  'Art. 7 Ley ISABI QRoo',
  'Art. 7',
  0, 0.0000, 0, 0.0000,
  'SIN_BASE', 0, 0,
  'No aplica plazo de pago — operación exenta.',
  1, 1, 1,
  1, 1, 'Solo aplica cuando el adquiriente es: (a) dependencia/entidad u organismo estatal o municipal para programas de vivienda; O (b) el beneficiario no sea propietario de otro inmueble y lo destine a casa habitación.',
  1, 1,
  'Diversas fuentes', 'Organismo de vivienda / Beneficiario de programa',
  'EXENTA', 0, 110,
  'INFONAVIT, FOVISSSTE, SEDATU, ISSTE u organismos equivalentes municipales. Requiere constancia de la entidad que acredite el carácter de la adquisición.'
);

-- ── 23. VIVIENDA DE INTERÉS SOCIAL / POPULAR (Deducible) ─────────────────
INSERT INTO isabi.cat_tipo_operacion (
  clave, nombre, nombre_corto, descripcion, fundamento_legal, articulo_ley,
  genera_isabi, tasa_isabi_pct, genera_adicional_turismo, tasa_adicional_pct,
  base_calculo, dias_pago_habiles, momento_causacion,
  requiere_escritura_publica, requiere_avaluo, requiere_predial_vigente,
  puede_ser_exento, condicion_exencion,
  actualiza_propietario_catastro, genera_historial_propietario,
  nombre_parte_transmite, nombre_parte_adquiere,
  grupo, es_onerosa, orden_display, notas_internas
) VALUES (
  'VIVIENDA_INTERES_SOCIAL',
  'Compraventa de Vivienda de Interés Social o Popular (con deducible)',
  'VIS / VIP',
  'Compraventa de vivienda cuyo valor al término de su edificación no excede los topes de la ley. En la Zona C (Tulum), aplica un deducible de 10 días de SMG elevado al año antes de calcular la base del ISABI. Reduce el impuesto pero no lo elimina salvo que la base sea cero.',
  'Art. 12 Ley ISABI QRoo; Zonas A, B y C del Art. 4 BIS Ley Hacienda Municipios QRoo',
  'Art. 12',
  1, 2.0000, 1, 10.0000,
  'VALOR_MAS_ALTO', 15,
  'A los 15 días hábiles desde la escritura. Base reducida por el deducible de la Zona C.',
  1, 1, 1,
  1, 'Vivienda popular Zona C (Tulum): deducible = 25 × SMG diario QRoo × 365. Vivienda interés social Zona C: deducible = 15 × SMG diario × 365. Si base − deducible ≤ 0, no se paga.',
  1, 1,
  'Desarrollador / Vendedor', 'Comprador persona física',
  'ESPECIAL', 1, 120,
  'Para 2026 en Tulum, el SMG general en QRoo es diferente al UMA. Verificar SMG vigente. Esta modalidad aplica también para INFONAVIT/FOVISSSTE cuando hay precio de venta documentado.'
);

-- ════════════════════════════════════════════
-- GRUPO 9: ESPECIALES TULUM / ZONA COSTERA QRoo
-- Requieren documentación adicional (ZOFEMAT, SRE, etc.)
-- ════════════════════════════════════════════

-- ── 24. COMPRAVENTA COLINDANTE CON ZOFEMAT ───────────────────────────────
INSERT INTO isabi.cat_tipo_operacion (
  clave, nombre, nombre_corto, descripcion, fundamento_legal, articulo_ley,
  genera_isabi, tasa_isabi_pct, genera_adicional_turismo, tasa_adicional_pct,
  base_calculo, dias_pago_habiles, momento_causacion,
  requiere_escritura_publica, requiere_avaluo, requiere_predial_vigente,
  requiere_const_zofemat,
  puede_ser_exento, condicion_exencion,
  actualiza_propietario_catastro, genera_historial_propietario,
  nombre_parte_transmite, nombre_parte_adquiere,
  grupo, es_onerosa, orden_display, notas_internas
) VALUES (
  'COMPRAVENTA_COLINDANTE_ZOFEMAT',
  'Compraventa de Inmueble Colindante con la Zona Federal Marítimo Terrestre',
  'CV Colindante ZOFEMAT',
  'Compraventa de inmueble que colinda con la ZOFEMAT (franja de 20 metros tierra adentro desde la línea de marea máxima) o que usa y goza de ella con o sin concesión. Requiere documentación adicional específica de la ZOFEMAT antes de poder escriturar. Muy frecuente en Tulum dada su costa caribeña.',
  'Art. 11 fracción VII Ley ISABI QRoo; Ley Federal del Mar; Ley General de Bienes Nacionales Art. 119',
  'Art. 11-VII',
  1, 2.0000, 1, 10.0000,
  'VALOR_MAS_ALTO', 15,
  'A los 15 días hábiles desde la escritura pública. No puede escriturarse sin la documentación ZOFEMAT.',
  1, 1, 1,
  1,   -- constancia ZOFEMAT
  0, NULL,
  1, 1,
  'Vendedor / Propietario costero', 'Comprador',
  'ESPECIAL_TULUM', 1, 130,
  'DOCUMENTACIÓN ADICIONAL OBLIGATORIA:
   1. Constancia de uso o no uso de concesión ZOFEMAT (SEMARNAT/SEMAR).
   2. Si tiene concesión: constancia de no adeudo por derechos de uso y goce de la ZOFEMAT.
   3. Copia de la última declaración y recibo de pago de la Tesorería Municipal de derechos ZOFEMAT (Art. 121 Ley Hac. Municipios QRoo).
   Para UPEs en fraccionamientos: constancias por unidad proporcional al pago realizado.'
);

-- ── 25. FIDEICOMISO BANCARIO POR EXTRANJERO EN ZONA RESTRINGIDA ──────────
INSERT INTO isabi.cat_tipo_operacion (
  clave, nombre, nombre_corto, descripcion, fundamento_legal, articulo_ley,
  genera_isabi, tasa_isabi_pct, genera_adicional_turismo, tasa_adicional_pct,
  base_calculo, dias_pago_habiles, momento_causacion,
  requiere_escritura_publica, requiere_avaluo, requiere_predial_vigente,
  requiere_contrato_fideicom, requiere_const_zofemat,
  puede_ser_exento, condicion_exencion,
  actualiza_propietario_catastro, genera_historial_propietario,
  nombre_parte_transmite, nombre_parte_adquiere,
  grupo, es_onerosa, orden_display, notas_internas,
  documentacion_adicional
) VALUES (
  'FIDEICOMISO_EXTRANJERO_ZONA_RESTRINGIDA',
  'Constitución de Fideicomiso Bancario por Persona Extranjera en Zona Restringida',
  'Fideicomiso Extranjero',
  'Adquisición de derechos sobre inmueble en zona restringida (50 km costa o 100 km frontera) por persona extranjera a través de fideicomiso bancario, conforme al Art. 27 constitucional y Ley de Inversión Extranjera. El banco (fiduciaria) es el titular registral; el extranjero es fideicomisario con todos los derechos de uso y goce.',
  'Art. 27 CPEUM fracción I; Ley de Inversión Extranjera Art. 11; Art. 5 incisos e) y f) Ley ISABI QRoo; Art. 11-VII Ley ISABI QRoo (si colinda ZOFEMAT)',
  'Art. 5-e / Art. 27 CPEUM / LIE Art. 11',
  1, 2.0000, 1, 10.0000,
  'VALOR_MAS_ALTO', 15,
  'A los 15 días hábiles desde la escritura de constitución del fideicomiso.',
  1, 1, 1,
  1, 1,  -- contrato fideicomiso + ZOFEMAT si colinda
  0, NULL,
  1, 1,
  'Vendedor / Fideicomitente (puede ser mexicano o extranjero)', 'Banco fiduciario (titular registral) / Fideicomisario (extranjero beneficiario)',
  'ESPECIAL_TULUM', 1, 131,
  'EL tipo de operación más frecuente en Tulum para compradores internacionales. El banco BBVA, Scotiabank, Banamex, HSBC u otro actúa como fiduciaria. El fideicomiso tiene vigencia de 50 años renovables. Requiere permiso de la SRE (Secretaría de Relaciones Exteriores).',
  '{"requiere_permiso_sre": true, "vigencia_fideicomiso_anios": 50, "renovable": true, "bancos_habituales_tulum": ["BBVA","Scotiabank","Citibanamex","HSBC","Banorte"], "requiere_zofemat_si_colinda_costa": true, "observacion": "El extranjero no puede ser propietario directo pero sí tiene todos los derechos de uso, goce y disposición como fideicomisario"}'
);

-- ══════════════════════════════════════════════════════════════════
-- SECCIÓN 3: VISTAS ÚTILES PARA EL MÓDULO ISABI
-- ══════════════════════════════════════════════════════════════════

CREATE VIEW isabi.v_tipos_operacion_activos AS
SELECT
  id_tipo_operacion,
  clave,
  nombre,
  nombre_corto,
  grupo,
  es_onerosa,
  genera_isabi,
  tasa_isabi_pct,
  tasa_adicional_pct,
  aplica_factor_50pct,
  base_calculo,
  dias_pago_habiles,
  puede_ser_exento,
  exento_por_ley,
  requiere_avaluo,
  requiere_acta_defuncion,
  requiere_declaratoria_hered,
  requiere_const_zofemat,
  requiere_contrato_fideicom,
  requiere_resolucion_judicial,
  requiere_acta_asamblea,
  nombre_parte_transmite,
  nombre_parte_adquiere,
  momento_causacion,
  orden_display
FROM isabi.cat_tipo_operacion
WHERE activo = 1
GO

-- Vista resumen para el selector del formulario ISABI
CREATE VIEW isabi.v_selector_tipo_operacion AS
SELECT
  id_tipo_operacion,
  clave,
  nombre_corto          AS label,
  nombre                AS label_completo,
  grupo,
  genera_isabi,
  tasa_isabi_pct,
  CASE WHEN genera_isabi = 1
    THEN CAST(tasa_isabi_pct AS VARCHAR) + '% + ' + CAST(tasa_adicional_pct AS VARCHAR) + '% adicional turismo'
    ELSE 'EXENTO'
  END                   AS descripcion_tasa,
  aplica_factor_50pct,
  requiere_avaluo,
  requiere_const_zofemat,
  requiere_acta_defuncion,
  requiere_contrato_fideicom,
  puede_ser_exento
FROM isabi.cat_tipo_operacion
WHERE activo = 1
GO

-- ══════════════════════════════════════════════════════════════════
-- SECCIÓN 4: SP DE CÁLCULO DE ISABI
-- ══════════════════════════════════════════════════════════════════
CREATE PROCEDURE isabi.sp_calcular_isabi
  @id_tipo_operacion   INT,
  @valor_operacion     DECIMAL(14,2) = NULL,   -- precio pactado
  @valor_catastral     DECIMAL(14,2) = NULL,   -- de la cédula catastral
  @valor_avaluo        DECIMAL(14,2) = NULL,   -- avalúo bancario/perito
  @es_usufructo_nuda   BIT = 0                 -- aplica factor 50%
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE
    @tasa_isabi      DECIMAL(6,4),
    @tasa_adicional  DECIMAL(6,4),
    @genera_isabi    BIT,
    @aplica_50pct    BIT,
    @base_calculo    VARCHAR(50),
    @base_gravable   DECIMAL(14,2),
    @monto_isabi     DECIMAL(14,2),
    @monto_adicional DECIMAL(14,2),
    @total_impuesto  DECIMAL(14,2);

  SELECT
    @tasa_isabi     = tasa_isabi_pct / 100.0,
    @tasa_adicional = tasa_adicional_pct / 100.0,
    @genera_isabi   = genera_isabi,
    @aplica_50pct   = aplica_factor_50pct,
    @base_calculo   = base_calculo
  FROM isabi.cat_tipo_operacion
  WHERE id_tipo_operacion = @id_tipo_operacion AND activo = 1;

  IF @genera_isabi = 0
  BEGIN
    SELECT
      0                AS base_gravable,
      0                AS monto_isabi,
      0                AS monto_adicional_turismo,
      0                AS total_impuesto,
      'EXENTO'         AS tipo_resultado,
      'Operación exenta conforme Art. 7 Ley ISABI QRoo' AS observacion;
    RETURN;
  END

  -- Determinar base gravable: el valor MÁS ALTO
  SET @base_gravable = (
    SELECT MAX(v) FROM (VALUES
      (ISNULL(@valor_operacion, 0)),
      (ISNULL(@valor_catastral, 0)),
      (ISNULL(@valor_avaluo,    0))
    ) AS t(v)
  );

  -- Aplicar factor 50% para usufructo / nuda propiedad
  IF @aplica_50pct = 1 OR @es_usufructo_nuda = 1
    SET @base_gravable = @base_gravable * 0.5;

  SET @monto_isabi     = ROUND(@base_gravable * @tasa_isabi, 2);
  SET @monto_adicional = ROUND(@monto_isabi   * @tasa_adicional, 2);
  SET @total_impuesto  = @monto_isabi + @monto_adicional;

  SELECT
    @base_gravable              AS base_gravable,
    @tasa_isabi * 100           AS tasa_isabi_pct,
    @monto_isabi                AS monto_isabi,
    @tasa_adicional * 100       AS tasa_adicional_pct,
    @monto_adicional            AS monto_adicional_turismo,
    @total_impuesto             AS total_impuesto,
    'CALCULADO'                 AS tipo_resultado,
    CASE WHEN @aplica_50pct = 1
      THEN 'Base = 50% del valor por ser usufructo/nuda propiedad (Art. 8 Ley ISABI QRoo)'
      ELSE 'Base = valor más alto entre precio, catastral y avalúo (Art. 8 Ley ISABI QRoo)'
    END                         AS observacion;
END;
GO

-- ══════════════════════════════════════════════════════════════════
-- ENDPOINTS REST — Referencia para FastAPI
-- ══════════════════════════════════════════════════════════════════
/*
GET  /api/v1/isabi/tipos-operacion
     → Lista todos los tipos activos para el selector del formulario

GET  /api/v1/isabi/tipos-operacion/{id}
     → Detalle completo de un tipo: descripción legal, documentos requeridos,
       momento de causación, condiciones de exención

GET  /api/v1/isabi/tipos-operacion/{id}/requisitos
     → Solo los documentos requeridos del tipo de operación

GET  /api/v1/isabi/tipos-operacion/grupo/{grupo}
     → Filtrar por: ONEROSA / GRATUITA / JUDICIAL / FIDEICOMISO /
                    ESPECIAL / CORPORATIVA / EXENTA / ESPECIAL_TULUM

POST /api/v1/isabi/calcular
     Body: { id_tipo_operacion, valor_operacion, valor_catastral, valor_avaluo }
     → Retorna: base_gravable, monto_isabi, adicional_turismo, total
*/

-- ══════════════════════════════════════════════════════════════════
-- RESUMEN DEL CATÁLOGO
-- ══════════════════════════════════════════════════════════════════
/*
╔═══════════════════════════════════════════════════════════════════════════╗
║  TIPOS DE OPERACIÓN PARA TRASLADO DE DOMINIO — TULUM, QUINTANA ROO       ║
║  25 tipos totales                                                         ╠═══════════════════╦════════════════════════════════════════════════╣
║  GRUPO                ║  TIPOS                                            ║
╠═══════════════════════╬════════════════════════════════════════════════╣
║  ONEROSA (1-5)        ║  Compraventa, CV Reserva Dominio, Permuta,    ║
║                       ║  Dación en Pago, Cesión Derechos Contrato     ║
╠═══════════════════════╬════════════════════════════════════════════════╣
║  GRATUITA (6-9)       ║  Donación, Herencia, Legado,                  ║
║                       ║  Cesión Derechos Hereditarios                  ║
╠═══════════════════════╬════════════════════════════════════════════════╣
║  JUDICIAL (10-13)     ║  Remate Judicial, Remate Administrativo,      ║
║                       ║  Adjudicación Sucesoria, Usucapión            ║
╠═══════════════════════╬════════════════════════════════════════════════╣
║  FIDEICOMISO (14-16)  ║  Fideicomiso Constitución, Fideicomiso        ║
║                       ║  Cumplimiento, Cesión Derechos Fideicomiso    ║
╠═══════════════════════╬════════════════════════════════════════════════╣
║  ESPECIAL (17-19)     ║  Usufructo, Nuda Propiedad,                   ║
║                       ║  Arrendamiento Financiero (Leasing)           ║
╠═══════════════════════╬════════════════════════════════════════════════╣
║  CORPORATIVA (20-21)  ║  Aportación a Sociedad, Fusión/Escisión       ║
╠═══════════════════════╬════════════════════════════════════════════════╣
║  EXENTA (22-23)       ║  Organismo Vivienda (exento), VIS/VIP         ║
║                       ║  (con deducible)                              ║
╠═══════════════════════╬════════════════════════════════════════════════╣
║  ESPECIAL TULUM (24-25)║ CV Colindante ZOFEMAT, Fideicomiso           ║
║                       ║  Extranjero Zona Restringida                  ║
╚═══════════════════════╩════════════════════════════════════════════════╝

TASA VIGENTE TULUM 2026:
  ISABI base:              2.00% sobre base gravable
  Adicional turístico:    10.00% sobre el ISABI
  Efectivo total:          2.20% sobre base gravable
  Base:           MAX(precio_pactado, avalúo_catastral, avalúo_bancario)
  Plazo de pago:           15 días hábiles desde el acto

FUENTE LEGAL DIRECTA:
  · Art. 9 Ley ISABI Municipios QRoo (tasa 2%)
  · Arts. 46 Bis al 46 Undécies Ley Hacienda Municipio Tulum (adicional 10%)
  · Arts. 5, 7, 8, 10, 11, 12 Ley ISABI Municipios QRoo (tipos y reglas)
*/
