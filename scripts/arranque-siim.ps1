# ╔══════════════════════════════════════════════════════════════════╗
# ║  SIIM — Script de arranque de servidores (auto-instalador)        ║
# ║  H. Ayuntamiento del Municipio de Tulum, Quintana Roo             ║
# ║                                                                    ║
# ║  Qué hace:                                                         ║
# ║   1. Libera los puertos 6679 (backend) y 8900 (frontend).          ║
# ║   2. Backend: si no existe el venv, LO CREA e instala              ║
# ║      requirements.txt automáticamente. Luego levanta uvicorn.      ║
# ║   3. Frontend: si no existe node_modules, corre npm install        ║
# ║      automáticamente. Luego levanta SvelteKit en el 8900.          ║
# ║                                                                    ║
# ║  Uso:                                                              ║
# ║    .\arranque-siim.ps1              → reinicia y levanta todo      ║
# ║    .\arranque-siim.ps1 -SoloDetener → solo libera los puertos      ║
# ║                                                                    ║
# ║  Si Windows bloquea el script, ejecútalo así:                      ║
# ║    powershell -ExecutionPolicy Bypass -File .\arranque-siim.ps1    ║
# ╚══════════════════════════════════════════════════════════════════╝

param(
    [switch]$SoloDetener
)

# ── Autoelevación: si no somos administrador, relanzar con permisos ──
$esAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $esAdmin) {
    Write-Host "Solicitando permisos de administrador..." -ForegroundColor Yellow
    $argumentos = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$PSCommandPath`"")
    if ($SoloDetener) { $argumentos += '-SoloDetener' }
    Start-Process powershell -Verb RunAs -ArgumentList $argumentos
    exit
}

# ── Configuración de puertos ──
$PUERTO_BACKEND  = 6679
$PUERTO_FRONTEND = 8900

# ── Rutas del proyecto (el script vive en siim-tulum\scripts\) ──
$RaizProyecto = Split-Path -Parent $PSScriptRoot
$DirBackend   = Join-Path $RaizProyecto "backend"
$DirFrontend  = Join-Path $RaizProyecto "frontend"

function Escribir-Titulo($texto) {
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor DarkCyan
    Write-Host "  $texto" -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor DarkCyan
}

# ── Función: liberar un puerto matando al proceso que lo ocupa ──
function Liberar-Puerto([int]$puerto, [string]$nombre) {
    $conexiones = Get-NetTCPConnection -LocalPort $puerto -ErrorAction SilentlyContinue
    if ($conexiones) {
        $pids = $conexiones | Select-Object -ExpandProperty OwningProcess -Unique
        foreach ($procId in $pids) {
            try {
                $proc = Get-Process -Id $procId -ErrorAction SilentlyContinue
                if ($proc) {
                    Write-Host "  [x] Cerrando '$($proc.ProcessName)' (PID $procId) del puerto $puerto ($nombre)..." -ForegroundColor Yellow
                    Stop-Process -Id $procId -Force -ErrorAction SilentlyContinue
                }
            } catch {
                Write-Host "  [!] No se pudo cerrar el PID $procId (puede requerir admin)" -ForegroundColor Red
            }
        }
        Start-Sleep -Seconds 1
        Write-Host "  [OK] Puerto $puerto liberado." -ForegroundColor Green
    } else {
        Write-Host "  [OK] Puerto $puerto ($nombre) ya estaba libre." -ForegroundColor Green
    }
}

# ══════════════════════════════════════════════
# PASO 1: LIBERAR PUERTOS
# ══════════════════════════════════════════════
Escribir-Titulo "SIIM - Liberando puertos"
Liberar-Puerto $PUERTO_BACKEND  "backend"
Liberar-Puerto $PUERTO_FRONTEND "frontend"

if ($SoloDetener) {
    Write-Host ""
    Write-Host "Modo -SoloDetener: puertos liberados. No se levanta nada." -ForegroundColor Cyan
    exit 0
}

# ══════════════════════════════════════════════
# PASO 2: BACKEND — auto-instala venv si falta, luego uvicorn
# ══════════════════════════════════════════════
Escribir-Titulo "Levantando BACKEND en puerto $PUERTO_BACKEND"

if (-not (Test-Path $DirBackend)) {
    Write-Host "  [x] No se encontro la carpeta backend en: $DirBackend" -ForegroundColor Red
} else {
    $cmdBackend = @"
`$host.UI.RawUI.WindowTitle = 'SIIM - Backend :$PUERTO_BACKEND'
cd '$DirBackend'
if (-not (Test-Path 'venv')) {
    Write-Host '>> Primera vez: creando entorno virtual de Python...' -ForegroundColor Yellow
    python -m venv venv
    if (-not (Test-Path 'venv\Scripts\python.exe')) { Write-Host '[X] No se pudo crear el venv. Revisa que Python este instalado.' -ForegroundColor Red; pause; exit 1 }
}
if (-not (Test-Path 'venv\Scripts\uvicorn.exe')) {
    Write-Host '>> Faltan dependencias: instalando (tarda 1-2 min)...' -ForegroundColor Yellow
    .\venv\Scripts\python.exe -m pip install --upgrade pip --quiet
    .\venv\Scripts\pip.exe install -r requirements.txt
    Write-Host '>> Dependencias listas.' -ForegroundColor Green
}
if (-not (Test-Path '.env')) {
    Write-Host '[!] AVISO: no existe backend\.env - copia .env.example como .env y pon tu password de PostgreSQL.' -ForegroundColor Yellow
}
. .\venv\Scripts\Activate.ps1
uvicorn app.main:app --port $PUERTO_BACKEND --reload
"@
    Start-Process powershell -ArgumentList @("-NoExit", "-ExecutionPolicy", "Bypass", "-Command", $cmdBackend)
    Write-Host "  [OK] Backend arrancando en ventana nueva -> http://localhost:$PUERTO_BACKEND/docs" -ForegroundColor Green
}

# ══════════════════════════════════════════════
# PASO 3: FRONTEND — auto-instala node_modules si falta, luego SvelteKit
# ══════════════════════════════════════════════
Escribir-Titulo "Levantando FRONTEND en puerto $PUERTO_FRONTEND"

$PackageJson = Join-Path $DirFrontend "package.json"

if (Test-Path $PackageJson) {
    $cmdFrontend = @"
`$host.UI.RawUI.WindowTitle = 'SIIM - Frontend :$PUERTO_FRONTEND'
cd '$DirFrontend'
if (-not (Test-Path 'node_modules')) {
    Write-Host '>> Primera vez: instalando dependencias de Node (esto tarda 1-2 min)...' -ForegroundColor Yellow
    npm install --no-audit --no-fund
    Write-Host '>> Dependencias listas.' -ForegroundColor Green
}
npm run dev -- --port $PUERTO_FRONTEND
"@
    Start-Process powershell -ArgumentList @("-NoExit", "-ExecutionPolicy", "Bypass", "-Command", $cmdFrontend)
    Write-Host "  [OK] Frontend arrancando en ventana nueva -> http://localhost:$PUERTO_FRONTEND" -ForegroundColor Green
} else {
    Write-Host "  [!] No hay package.json en frontend\. Nada que levantar." -ForegroundColor Yellow
}

# ══════════════════════════════════════════════
# RESUMEN
# ══════════════════════════════════════════════
Write-Host ""
Write-Host "------------------------------------------" -ForegroundColor DarkCyan
Write-Host "  SIIM listo:" -ForegroundColor Cyan
Write-Host "   - Portal   -> http://localhost:$PUERTO_FRONTEND" -ForegroundColor White
Write-Host "   - API docs -> http://localhost:$PUERTO_BACKEND/docs" -ForegroundColor White
Write-Host "   - Usuario inicial: admin / Tulum2026!" -ForegroundColor Gray
Write-Host "   - Para reiniciar: vuelve a ejecutar este script." -ForegroundColor Gray
Write-Host "   - Para solo apagar: .\arranque-siim.ps1 -SoloDetener" -ForegroundColor Gray
Write-Host "------------------------------------------" -ForegroundColor DarkCyan
