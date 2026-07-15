# ╔══════════════════════════════════════════════════════════════════════╗
# ║   CÁLCULO DEL VALOR CATASTRAL                                        ║
# ║   Municipio de Tulum, Quintana Roo                                   ║
# ║   Marco legal vigente 2026 — Guía técnica completa                   ║
# ╚══════════════════════════════════════════════════════════════════════╝

---

# ══════════════════════════════════════════════
# 1. MARCO LEGAL APLICABLE
# ══════════════════════════════════════════════

| Instrumento legal | Publicación | Relevancia |
|---|---|---|
| Ley de Catastro del Estado de Quintana Roo | POE original, última reforma 2021 | Define todo el sistema catastral |
| Reglamento de la Ley de Catastro del Estado de QRoo | Vigente | Metodología técnica de valuación |
| Ley de Hacienda de los Municipios del Estado de QRoo | POE 15-12-1997, última reforma 30-11-2015 | Tasas de predial y base del impuesto |
| Ley de Hacienda del Municipio de Tulum | Última reforma POE 10-12-2025 | Reglas locales, ISABI, descuentos |
| Ley de Ingresos del Municipio de Tulum 2026 | Decreto 162, POE 10-12-2025 | Tarifas vigentes del ejercicio |
| Ley del ISABI de los Municipios del Estado de QRoo | Vigente | Impuesto sobre adquisición |
| **Tablas de Valores Unitarios de Suelo y Construcción Tulum** | **Decreto 91 XVI Legislatura, POE 25-12-2020** | **Base técnica de valuación — vigente para 2026 por no haberse aprobado tabla nueva** |

> ⚠️ **NOTA CRÍTICA PARA EL SIIM**: La Ley de Ingresos de Tulum 2026 confirmó expresamente que se continúan aplicando las Tablas del **Decreto 91** (publicadas el 25-12-2020) para la valuación catastral durante el ejercicio fiscal 2025 — y en tanto no se publique decreto nuevo, rigen también para 2026. A diferencia de Benito Juárez, Playa del Carmen o Puerto Morelos (que publican tablas nuevas cada año), Tulum ha mantenido las mismas desde 2021.

---

# ══════════════════════════════════════════════
# 2. CONCEPTO DE VALOR CATASTRAL
# ══════════════════════════════════════════════

Según el **Art. 2 fracc. IV de la Ley de Catastro de QRoo**, el **Avalúo** es:

> *"La determinación del valor, mediante la aplicación del conjunto de datos técnicos, jurídicos y administrativos sobre un bien inmueble, considerando sus características cualitativas y cuantitativas."*

El **Valor Catastral (VC)** es la suma del valor del terreno más el valor de la construcción, fijado por la Autoridad Catastral Municipal con base en las Tablas de Valores Unitarios vigentes:

```
╔══════════════════════════════════════════╗
║                                          ║
║        VC  =  VS  +  VCo                ║
║                                          ║
║  VC  = Valor Catastral Total             ║
║  VS  = Valor del Suelo                   ║
║  VCo = Valor de la Construcción          ║
║                                          ║
╚══════════════════════════════════════════╝
```

---

# ══════════════════════════════════════════════
# 3. CLASIFICACIÓN DE PREDIOS
# ══════════════════════════════════════════════

## 3.1 Por Categoría (ubicación respecto al límite urbano)

| Categoría | Definición |
|---|---|
| **URBANO** | Dentro del perímetro urbano definido por el PDU vigente del municipio |
| **SUBURBANO** | Fuera del perímetro urbano pero con potencialidad de convertirse en zona urbana |
| **RÚSTICO** | Fuera del límite urbano |

## 3.2 Por Condición de uso

| Condición | Descripción |
|---|---|
| **EN FUNCIONAMIENTO** | Construcción fija que lo hace funcional y aprovechable según el PDU |
| **CON CONSTRUCCIÓN** | Tiene construcción pero no suficiente para considerarse en funcionamiento |
| **BALDÍO** | Sin construcción fija (o solo barda perimetral) |

## 3.3 Tipos especiales de suelo en Tulum

| Tipo | Tratamiento especial |
|---|---|
| **PREDIO CON MANGLAR** | Valor unitario especial: **$30.00/m²** (no aplica zona de valor ni factores) |
| **PREDIO CON CAMPO DE GOLF** | Valor unitario especial: **$850.00/m²** |
| **PREDIO CON SASCABERA** | Valor unitario especial: **$410.00/m²** |
| **PREDIO CON PRODUCCIÓN AGRÍCOLA** | Factor especial: **0.80** sobre el VUS de la zona |
| **PREDIO CON CENOTE** | Factor especial: **0.80** sobre el VUS de la zona |
| **COLINDANTE CON ZOFEMAT** | Aplica Factor de Zona especial: **1.15** (mérito) |

---

# ══════════════════════════════════════════════
# 4. COMPONENTE A: VALOR DEL SUELO (VS)
# ══════════════════════════════════════════════

## 4.1 Fórmula

El suelo puede tener partes con características distintas (ej. parte frente a calle y parte con manglar). Cada parte se calcula por separado y se suman:

```
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║   VS  =  Σ ( m²Ti  ×  VUSi  ×  Frei )                      ║
║                                                              ║
║   m²Ti  = Superficie de la parte i del terreno               ║
║   VUSi  = Valor Unitario de Suelo de la zona i ($/m²)       ║
║   Frei  = Factor Resultante de la parte i                    ║
║   i     = Índice para cada tipo de superficie (1, 2, ..., n) ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
```

## 4.2 Valor Unitario de Suelo (VUS)

Determinado por la **Zona de Valor** a la que pertenece el predio, publicada en las Tablas del Congreso. Para Tulum, las zonas de valor se dividen en:

- **Zonas urbanas**: Por localidades (Tulum centro, Akumal, Cobá, Muyil, Boca Paila, etc.) con valor en **$/m²**
- **Zonas rústicas**: Con valor en **$/m²** que se multiplica por 10,000 para obtener el **valor por hectárea**

> 📌 Los valores específicos de las zonas de Tulum están en las Tablas del Decreto 91 POE 25-12-2020. En municipios vecinos como Puerto Morelos (referencia metodológica 2026), los valores van desde **$2.00/m²** (manglares protegidos) hasta **$8,165.00/m²** (frente de playa con resorts).

## 4.3 Factor Resultante (Fre) — Fórmula

```
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║   Fre  =  Fzo  ×  Fubi  ×  Fesp  ×  Fsup  ×  Furb          ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
```

---

### FACTOR DE ZONA (Fzo) — ¿Qué tipo de vía da frente al predio?

| Ubicación del predio respecto a la vía | Factor |
|---|---|
| Calle secundaria o terciaria | **1.00** |
| Avenida principal | **1.05** |
| Frente a Zona Federal Marítimo Terrestre (ZOFEMAT) | **1.15** |

---

### FACTOR DE UBICACIÓN (Fubi) — ¿Dónde está en la manzana?

| Ubicación en manzana | Factor HABITACIONAL | Factor NO HABITACIONAL |
|---|---|---|
| Intermedio | 1.00 | 1.00 |
| **Esquinero** | 1.05 | 1.07 |
| **Cabecero** (frente en dos calles opuestas) | 1.10 | 1.12 |
| **Manzanero** (todo el frente de la manzana) | 1.12 | 1.15 |

---

### FACTOR ESPECIAL (Fesp) — Características particulares del suelo

| Utilización o característica | Valor o Factor especial |
|---|---|
| Predio con **Manglar** | $30.00/m² — **sustituye** al VUS, no aplica ningún otro factor |
| Predio con **Campo de Golf** | $850.00/m² — sustituye al VUS, no aplica ningún otro factor |
| Predio con **Sascabera en producción** | $410.00/m² — sustituye al VUS |
| Predio o UPE con **Producción Agrícola** | Factor **0.80** sobre el VUS |
| Predio o UPE con **Cenote** | Factor **0.80** sobre el VUS |
| Sin característica especial | **1.00** (no aplica) |

> La superficie con característica especial se calcula por separado. La superficie restante del predio aplica su zona de valor normal con los demás factores.

---

### FACTOR DE SUPERFICIE (Fsup) — Demérito por predios muy grandes

**Predios Habitacionales:**

| Superficie del predio | Factor de demérito |
|---|---|
| Menos de 50,000 m² | 1.00 (sin demérito) |
| 50,000 a 100,000.99 m² | **0.90** |
| 100,001 a 200,000.99 m² | **0.85** |
| 200,001 a 400,000.99 m² | **0.80** |
| 400,001 a 600,000.99 m² | **0.70** |
| Más de 600,001 m² | **0.60** |

**Predios No Habitacionales:**

| Superficie del predio | Factor de demérito |
|---|---|
| Menos de 50,000 m² | 1.00 (sin demérito) |
| 50,000 a 100,000.99 m² | **0.90** |
| 100,001 a 500,000.99 m² | **0.80** |
| Más de 500,001 m² | **0.70** |

---

### FACTOR DE URBANIZACIÓN (Furb) — Nivel de servicios públicos

| Servicios con que cuenta el predio / zona | Factor |
|---|---|
| Con todos los servicios (agua, drenaje, electricidad, pavimento, alumbrado) | **1.00** |
| Con la mayoría de servicios | **0.95** |
| Con servicios mínimos | **0.85** |
| Sin servicios | **0.70** |

---

# ══════════════════════════════════════════════
# 5. COMPONENTE B: VALOR DE LA CONSTRUCCIÓN (VCo)
# ══════════════════════════════════════════════

## 5.1 Fórmula

```
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║   VCo  =  Σ ( m²Ci  ×  VUCi  ×  FEi )                     ║
║                                                              ║
║   m²Ci  = Superficie de cada tipo de construcción            ║
║   VUCi  = Valor Unitario de Construcción ($/m²) según        ║
║            la CLASIFICACIÓN del tipo constructivo            ║
║   FEi   = Factor de Edad (depreciación por antigüedad)       ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
```

## 5.2 Tipología de Construcciones

Las construcciones se clasifican según dos grupos de características:

### A) CARACTERÍSTICAS ESTRUCTURALES — ¿Cómo está construido?

| Categoría | Descripción |
|---|---|
| **TIPO I — Lujosa** | Estructura especial de concreto/acero, acabados de primera, materiales importados |
| **TIPO II — Primera** | Estructura de concreto con acabados de primera calidad, instalaciones completas |
| **TIPO III — Económica** | Estructura de block/tabique con acabados medianos, instalaciones básicas |
| **TIPO IV — Precaria** | Materiales de segunda, sin acabados terminados, instalaciones incompletas |

### B) CARACTERÍSTICAS DE CALIDAD Y CONSERVACIÓN — ¿En qué estado está?

| Estado | Factor de conservación |
|---|---|
| **Excelente** | 1.00 |
| **Buena** | 0.90 |
| **Regular** | 0.75 |
| **Mala** | 0.60 |
| **Ruinosa** | 0.40 o menos |

### C) CLASIFICACIÓN RESULTANTE

La combinación de características estructurales × calidad y conservación produce la **CLASIFICACIÓN** del predio, que determina el **Valor Unitario de Construcción (VUC)** en $/m² de la Tabla.

Ejemplos de tipos de construcción que tienen VUC específicos:
- Vivienda habitacional tipos económico, medio, residencial y residencial plus
- Locales comerciales de uno hasta cuatro niveles
- Edificios de departamentos / condominios de tipo hotelero (hasta 4 niveles, más de 4 niveles)
- Bodegas industriales
- Instalaciones especiales (albercas, canchas, estacionamientos)
- Construcciones precarias / provisionales

## 5.3 Factor de Edad (FE) — Depreciación por antigüedad

Este factor reduce el Valor Unitario de Construcción en función de los años transcurridos desde la construcción:

| Años de antigüedad | Factor de Edad (FE) |
|---|---|
| 0 a 5 años | 1.00 |
| 6 a 10 años | 0.90 |
| 11 a 20 años | 0.80 |
| 21 a 30 años | 0.70 |
| 31 a 40 años | 0.60 |
| 41 a 50 años | 0.50 |
| Más de 50 años | 0.40 (mínimo) |

> ⚠️ El Factor de Edad puede ser ajustado por el valuador catastral si la construcción ha sido remodelada o restaurada, previa verificación física.

## 5.4 Construcciones en Régimen de Condominio (UPE)

Para **Unidades de Propiedad Exclusiva (UPE)** bajo régimen de condominio:

- **Superficie de suelo**: superficie propia de la UPE + **indiviso proporcional** de las áreas comunes de terreno
- **Superficie de construcción**: superficie propia de la UPE + **indiviso proporcional** de las áreas comunes de construcción (pasillos, lobby, cisterna, estacionamiento común, etc.)

```
Sup. suelo UPE    = m² exclusivos de suelo + (m² área común suelo × % indiviso)
Sup. const. UPE   = m² exclusivos construcción + (m² área común const. × % indiviso)
```

---

# ══════════════════════════════════════════════
# 6. PROCESO COMPLETO PASO A PASO
# ══════════════════════════════════════════════

```
PASO 1: IDENTIFICAR EL PREDIO
       ├── Obtener clave catastral
       ├── Verificar cédula catastral vigente
       ├── Confirmar categoría: URBANO / RÚSTICO
       └── Verificar condición: EN FUNCIONAMIENTO / CON CONSTRUCCIÓN / BALDÍO

PASO 2: DETERMINAR LA ZONA DE VALOR
       ├── Localizar el predio en los planos de zonas de valor
       ├── Identificar la zona (ej. Z-01, ZU-TULUM-A, ZR-01)
       └── Obtener el VUS ($/m²) de la Tabla de Valores vigente

PASO 3: CALCULAR LOS FACTORES DE AJUSTE DEL SUELO
       ├── Fzo: ¿frente a qué tipo de vía?
       ├── Fub: ¿posición en la manzana?
       ├── Fesp: ¿hay manglar, cenote, golf, agricultura, sascabera?
       ├── Fsup: ¿la superficie supera los 50,000 m²?
       └── Furb: ¿con qué servicios cuenta la zona?

PASO 4: CALCULAR EL FACTOR RESULTANTE
       └── Fre = Fzo × Fub × Fesp × Fsup × Furb

PASO 5: CALCULAR EL VALOR DE SUELO (VS)
       └── VS = Σ(m²Ti × VUSi × Frei)
           (Si hay partes heterogéneas, calcular cada una por separado)

PASO 6: CLASIFICAR LAS CONSTRUCCIONES
       ├── Tipología estructural (I, II, III, IV)
       ├── Calidad y conservación (Excelente / Buena / Regular / Mala / Ruinosa)
       └── Obtener Clasificación → VUC de la tabla

PASO 7: APLICAR FACTOR DE EDAD
       ├── Determinar año de construcción
       ├── Calcular antigüedad en años
       └── Obtener FE de la tabla de depreciación

PASO 8: CALCULAR EL VALOR DE CONSTRUCCIÓN (VCo)
       └── VCo = Σ(m²Ci × VUCi × FEi)
           (Si hay distintos tipos constructivos, calcular por separado)

PASO 9: OBTENER EL VALOR CATASTRAL TOTAL
       └── VC = VS + VCo

PASO 10: REGISTRAR EN CÉDULA CATASTRAL
        └── Notificar al contribuyente del nuevo valor
```

---

# ══════════════════════════════════════════════
# 7. IMPUESTO PREDIAL — TASAS TULUM 2026
# ══════════════════════════════════════════════

Tulum pertenece a la **ZONA "C"** (junto con Benito Juárez, Solidaridad y Cozumel) según el Art. 4 BIS de la Ley de Hacienda de los Municipios del Estado.

## 7.1 Base del Impuesto

Según el Art. 11 de la Ley de Hacienda Municipal, la base es el **valor más alto** entre:
- Valor catastral
- Valor bancario (avalúo bancario)
- Valor declarado por el contribuyente
- Valor de renta que produzca o sea susceptible de producir el predio

## 7.2 Tasas aplicables — ZONA C (Tulum)

### Predios Urbanos y Suburbanos

| Supuesto | Tasa anual |
|---|---|
| Valor no excede $18,000 | **2.5 SMG** (monto fijo) |
| **Predios urbanos con construcción** | **6.9 al millar (0.69%)** |
| Predios que no tengan banquetas | 7 al millar |
| Predios que no tengan bardas | 7 al millar |
| **Predios sin construcciones permanentes (baldíos)** | **18 al millar (1.8%)** |
| Predios sin bardas y sin banquetas | 7.5 al millar |
| **Predios sin bardas, banquetas NI construcciones** | **19 al millar (1.9%)** |

### Predios Rústicos

| Supuesto | Tasa anual |
|---|---|
| **Predios rústicos** (general) | **8.0 al millar (0.80%)** |
| Predios rústicos dentro de Reserva o Zona Protegida | 18.4 al millar |
| Predios rústicos colindantes con ZOFEMAT | **18.4 al millar** |
| Predios rústicos clasificados como pequeña propiedad rural | 8.0 al millar |

> 📌 **Clave para Tulum**: Dado el boom inmobiliario de la zona costera, muchos predios rústicos que colindan con la ZOFEMAT tributan a la tasa alta de **18.4 al millar** en lugar del 8 al millar general.

## 7.3 Forma de Pago

El Impuesto Predial se cubre por **bimestres adelantados** en los primeros 10 días de los meses de: **enero, marzo, mayo, julio, septiembre y noviembre** (Art. 16 Ley de Hacienda de Tulum).

## 7.4 Descuentos por pronto pago (Tulum)

Según el Art. 18 de la Ley de Hacienda del Municipio de Tulum:

| Fecha de pago | Descuento |
|---|---|
| Hasta el **31 de enero** (pago anual completo adelantado) | **Hasta 25%** |
| Hasta el **último día hábil de febrero** (pago anual adelantado) | **Hasta 15%** |

---

# ══════════════════════════════════════════════
# 8. ISABI — IMPUESTO SOBRE ADQUISICIÓN DE BIENES INMUEBLES
# ══════════════════════════════════════════════

## 8.1 ¿Qué es?

El ISABI (llamado también ISAI o Traslado de Dominio) se genera al momento de la **compraventa, donación, permuta, adjudicación, fideicomiso traslativo** o cualquier otra operación que implique adquisición de un bien inmueble.

## 8.2 Sujeto

**El adquiriente (comprador)** es quien lo paga. Los fedatarios públicos (notarios) tienen la obligación de calcular, retener y enterar el impuesto ante el municipio antes de escriturar.

## 8.3 Base del ISABI

La base es el **valor más alto** entre:
1. Valor del contrato de compraventa (precio de operación)
2. Valor catastral vigente del predio
3. Avalúo bancario / comercial

## 8.4 Tasa

La tasa del ISABI en **Tulum es del 2%** sobre la base (a diferencia de Benito Juárez/Cancún que subió al 3% desde 2017).

```
ISABI  =  Base (valor más alto)  ×  2%
```

## 8.5 Impuesto adicional para el Fomento Turístico (IAFODETUR)

Sobre el monto de los impuestos y derechos a cargo del comprador, se adiciona un **10%** para el fomento turístico, desarrollo social y cultural, conforme al Art. 46-BIS de la Ley de Hacienda Municipal.

## 8.6 Exenciones comunes

- Donaciones entre familiares en línea recta (padres-hijos, abuelos-nietos)
- Adjudicaciones derivadas de herencia
- Transmisiones a organismos públicos para uso público

## 8.7 Documentación requerida para el cálculo

1. Escritura o contrato de compraventa con precio
2. Cédula catastral vigente (con el valor catastral actualizado)
3. Avalúo bancario / comercial (si el precio de mercado supera el catastral)
4. Acreditación de propiedad del enajenante
5. Identificaciones oficiales de comprador y vendedor

---

# ══════════════════════════════════════════════
# 9. CÉDULA CATASTRAL — Documento base
# ══════════════════════════════════════════════

La **Cédula Catastral** es el documento oficial que:
- Acredita el registro del predio en el padrón catastral
- Contiene todos los datos actualizados del inmueble
- Tiene **vigencia de 1 a 2 años** según las modificaciones al predio
- Es obligatoria para: escrituración, licencias de construcción, trámites de licencias de funcionamiento, obtención del CRI y cualquier operación sobre el inmueble

### Datos que contiene la Cédula Catastral

```
Datos de identificación:
  - Clave catastral
  - Cuenta predial
  - Clave de valuación
  - Ejercicio fiscal

Datos del titular:
  - Nombre o razón social
  - RFC / CURP
  - Domicilio fiscal

Datos físicos del predio:
  - Ubicación (calle, número, colonia, CP)
  - Coordenadas geográficas
  - Superficie de terreno (m²)
  - Superficie construida (m²)
  - Número de niveles
  - Colindancias

Datos valuatorios:
  - Zona de valor
  - Valor Unitario de Suelo ($/m²)
  - Factores aplicados (Fre)
  - Valor del suelo (VS)
  - Tipo y clasificación de construcción
  - Factor de edad
  - Valor de construcción (VCo)
  - VALOR CATASTRAL TOTAL (VC)
  - Fecha del avalúo
  - Vigencia del avalúo
```

---

# ══════════════════════════════════════════════
# 10. AUTORIDADES CATASTRALES EN TULUM
# ══════════════════════════════════════════════

| Nivel | Autoridad | Función principal |
|---|---|---|
| **Municipal** | Dirección de Catastro del H. Ayuntamiento de Tulum | Registro, valuación, cédulas, padrón, cobranza |
| **Estatal** | Dirección General de Catastro del Estado de QRoo (IGCEQROO) | Normatividad técnica, aprobación de tablas, capacitación, convenios |
| **Legislativa** | H. Congreso del Estado de Quintana Roo | Aprobación anual de Tablas de Valores Unitarios mediante Decreto |

> La Dirección de Catastro Municipal puede celebrar **convenio con la Secretaría de Hacienda del Estado** para que ésta realice las funciones técnicas de valuación cuando el municipio no cuente con capacidad suficiente.

---

# ══════════════════════════════════════════════
# 11. ACTUALIZACIÓN DE VALORES Y AVISOS
# ══════════════════════════════════════════════

## 11.1 Obligaciones del propietario

El contribuyente tiene la obligación de **comunicar al Catastro Municipal en un plazo de 15 días hábiles** cualquier modificación a las características del predio, incluyendo:
- Nuevas construcciones
- Ampliaciones
- Demoliciones
- Cambio de uso
- Subdivisiones o fusiones
- Transmisiones de propiedad

## 11.2 Actualización periódica de tablas

- Las **Tablas de Valores Unitarios** tienen vigencia **anual**
- Son aprobadas por el **Congreso del Estado** previo al inicio del ejercicio fiscal
- El Catastro Municipal formula la propuesta, la somete al Ayuntamiento, y éste la presenta al Congreso

## 11.3 Actualización del INPC para contribuciones vencidas

Para calcular adeudos de predial de ejercicios anteriores, se aplica la fórmula de actualización conforme al INPC:

```
Factor de actualización = INPC del mes anterior al pago
                          ─────────────────────────────
                          INPC del mes anterior al período de causación
```

---

# ══════════════════════════════════════════════
# 12. EJEMPLO PRÁCTICO DE CÁLCULO
# ══════════════════════════════════════════════

**Predio:** Casa habitación urbana en Tulum centro
- Superficie terreno: 300 m²
- Superficie construida: 180 m²
- Zona de valor: ZU-05 → VUS = $3,500/m² (ejemplo ilustrativo)
- Ubicación en manzana: Esquinero, uso habitacional → Fub = 1.05
- Frente a: Calle secundaria → Fzo = 1.00
- Sin características especiales → Fesp = 1.00
- Superficie < 50,000 m² → Fsup = 1.00
- Con servicios básicos, pero sin todos → Furb = 0.95
- Tipo construcción: Segunda (económica) → VUC = $7,500/m² (ejemplo)
- Antigüedad: 12 años → FE = 0.80

**Cálculo:**

```
Fre = 1.00 × 1.05 × 1.00 × 1.00 × 0.95  =  0.9975

VS  = 300 m² × $3,500/m² × 0.9975        =  $1,047,375.00

VCo = 180 m² × $7,500/m² × 0.80          =  $1,080,000.00

VC  = $1,047,375 + $1,080,000             =  $2,127,375.00

Predial anual (urbano Zona C: 6.9 al millar):
  = $2,127,375 × 0.0069                   =  $14,678.89 / año
  = $14,678.89 / 6 bimestres              =  $2,446.48 / bimestre

ISABI (si se vende en $5,000,000 y VC es $2,127,375):
  Base = $5,000,000 (valor más alto)
  ISABI = $5,000,000 × 2%                 =  $100,000.00
  IAFODETUR (10% sobre ISABI y derechos)  =  $10,000.00+
  Total adquisición en impuestos          ≈  $110,000.00+
```

---

# ══════════════════════════════════════════════
# 13. CAMPOS REQUERIDOS EN LA BD — SIIM
# ══════════════════════════════════════════════

Para implementar el motor de cálculo del valor catastral en el SIIM, la tabla `predial.predio` debe contener o relacionar:

```sql
-- DATOS DE SUELO (para VS)
zona_catastral_id          → FK a cat_zona_catastral (lleva VUS)
vus_aplicado               DECIMAL(12,2)   -- valor unitario de suelo del año
factor_zona                DECIMAL(6,4)    -- Fzo
factor_ubicacion           DECIMAL(6,4)    -- Fub
factor_especial            DECIMAL(6,4)    -- Fesp
factor_superficie          DECIMAL(6,4)    -- Fsup
factor_urbanizacion        DECIMAL(6,4)    -- Furb
factor_resultante          DECIMAL(6,4)    -- Fre = Fzo×Fub×Fesp×Fsup×Furb
valor_catastral_suelo      DECIMAL(14,2)   -- VS calculado

-- DATOS DE CONSTRUCCIÓN (para VCo)
tipo_construccion          VARCHAR(30)     -- I/II/III/IV
estado_conservacion        VARCHAR(20)     -- EXCELENTE/BUENA/REGULAR/MALA/RUINOSA
clasificacion_construccion VARCHAR(10)     -- resultado combinado
vuc_aplicado               DECIMAL(12,2)   -- valor unitario construcción
anio_construccion          INT
antiguedad_anios           AS (YEAR(GETDATE()) - anio_construccion) PERSISTED
factor_edad                DECIMAL(5,3)    -- FE por antigüedad
valor_catastral_construccion DECIMAL(14,2) -- VCo calculado

-- RESULTADO FINAL
valor_catastral_total      AS (valor_catastral_suelo + valor_catastral_construccion) PERSISTED
fecha_ultimo_avaluo        DATE
ejercicio_avaluo           INT
vigencia_avaluo            DATE

-- CATÁLOGO: cat_zona_catastral
-- Agregar campo:
vus_por_ejercicio          → tabla separada: predial.zona_valor_historia
  id_zona, ejercicio_fiscal, vus_m2, decreto_aprobacion, fecha_vigencia_desde
```

### Función de cálculo del Factor de Edad (SQL Server)

```sql
CREATE FUNCTION predial.fn_factor_edad(@anio_construccion INT)
RETURNS DECIMAL(5,3) AS
BEGIN
  DECLARE @antiguedad INT = YEAR(GETDATE()) - @anio_construccion
  RETURN CASE
    WHEN @antiguedad <= 5  THEN 1.000
    WHEN @antiguedad <= 10 THEN 0.900
    WHEN @antiguedad <= 20 THEN 0.800
    WHEN @antiguedad <= 30 THEN 0.700
    WHEN @antiguedad <= 40 THEN 0.600
    WHEN @antiguedad <= 50 THEN 0.500
    ELSE 0.400
  END
END
GO

-- Stored Procedure para calcular y actualizar el valor catastral de un predio
CREATE PROCEDURE predial.sp_calcular_valor_catastral
  @id_predio BIGINT
AS BEGIN
  UPDATE predial.predio
  SET
    factor_resultante = factor_zona * factor_ubicacion * factor_especial
                       * factor_superficie * factor_urbanizacion,
    valor_catastral_suelo = superficie_terreno_m2 * vus_aplicado
                           * (factor_zona * factor_ubicacion * factor_especial
                              * factor_superficie * factor_urbanizacion),
    factor_edad = predial.fn_factor_edad(anio_construccion),
    valor_catastral_construccion = superficie_construida_m2 * vuc_aplicado
                                  * predial.fn_factor_edad(anio_construccion),
    fecha_ultimo_avaluo = CAST(GETDATE() AS DATE),
    ejercicio_avaluo = YEAR(GETDATE())
  WHERE id_predio = @id_predio
END
GO
```

---

# ══════════════════════════════════════════════
# FUENTES Y REFERENCIAS
# ══════════════════════════════════════════════

| Documento | URL / Referencia |
|---|---|
| Ley de Catastro del Estado de QRoo | congresoqroo.gob.mx/leyes/13/ |
| Reglamento de la Ley de Catastro QRoo | archivo.transparencia.qroo.gob.mx |
| Tablas de Valores Unitarios Tulum 2021 (Decreto 91, vigentes 2025-2026) | congresoqroo.gob.mx/leyes/241/ |
| Tablas de Valores Puerto Morelos 2026 (referencia metodológica) | documentos.congresoqroo.gob.mx — Decreto 159 POE 10-12-2025 |
| Ley de Hacienda Municipios QRoo (Zona C — tasas predial) | documentos.congresoqroo.gob.mx/leyes/L1420151130354.pdf |
| Ley de Hacienda del Municipio de Tulum | tulum.gob.mx/Transparenciaftp/MarcoNormativo/ |
| Ley de Ingresos Tulum 2025 (Decreto vigente) | tulum.gob.mx ArmonizacionContable |
| Ley del ISABI Municipios QRoo | congresoqroo.gob.mx/leyes/154/ |
| IGCEQROO (Instituto Geográfico y Catastral del Estado) | qroo.gob.mx |

---

*Documento técnico elaborado para el SIIM — Sistema Integral de Ingresos Municipales*
*H. Ayuntamiento del Municipio de Tulum, Quintana Roo*
*Versión 1.0 — Mayo 2026*
