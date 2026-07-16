"""Punto de entrada de la API del SIIM."""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text

from app.api.v1 import auth
from app.core.config import settings
from app.core.database import engine

app = FastAPI(
    title=settings.project_name,
    version="0.1.0",
    description=(
        "API del Sistema Integral de Ingresos Municipales — "
        "H. Ayuntamiento del Municipio de Tulum, Quintana Roo."
    ),
    openapi_url=f"{settings.api_v1_prefix}/openapi.json",
    docs_url="/docs",
)

# CORS: permitir al frontend SvelteKit (dev) consumir la API.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:8900", "http://127.0.0.1:8900"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Routers por módulo ──
app.include_router(auth.router, prefix=settings.api_v1_prefix)
# Próximos: usuarios, roles, contribuyentes, caja, ...


@app.get("/", tags=["sistema"])
async def root():
    return {
        "sistema": settings.project_name,
        "estado": "en linea",
        "version": "0.1.0",
        "docs": "/docs",
    }


@app.get("/health", tags=["sistema"])
async def health():
    """Verifica que la API responda y que la base de datos esté conectada."""
    try:
        async with engine.connect() as conn:
            await conn.execute(text("SELECT 1"))
        db_estado = "ok"
    except Exception:  # noqa: BLE001
        db_estado = "sin_conexion"
    return {"api": "ok", "base_datos": db_estado, "entorno": settings.environment}
