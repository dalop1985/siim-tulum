"""Configuración central del SIIM. Lee variables desde el entorno / .env."""
from urllib.parse import quote_plus

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    # ── Identidad de la app ──
    project_name: str = "SIIM — Sistema Integral de Ingresos Municipales"
    api_v1_prefix: str = "/api/v1"
    environment: str = "development"

    # ── PostgreSQL ──
    postgres_host: str = "localhost"
    postgres_port: int = 5432
    postgres_db: str = "siim"
    postgres_user: str = "postgres"
    postgres_password: str = ""

    # ── Seguridad / JWT ──
    secret_key: str = "cambiar-esta-clave-en-produccion"
    access_token_expire_minutes: int = 60
    algorithm: str = "HS256"

    @property
    def database_url(self) -> str:
        """Cadena de conexión async para SQLAlchemy + asyncpg.

        La contraseña se codifica (quote_plus) para que símbolos como
        ?, @, #, / no rompan la URL de conexión.
        """
        return (
            f"postgresql+asyncpg://{quote_plus(self.postgres_user)}:"
            f"{quote_plus(self.postgres_password)}"
            f"@{self.postgres_host}:{self.postgres_port}/{self.postgres_db}"
        )


settings = Settings()
