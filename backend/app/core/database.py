"""Motor y sesión async de SQLAlchemy 2.x contra PostgreSQL (asyncpg)."""
from collections.abc import AsyncGenerator

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.orm import DeclarativeBase

from app.core.config import settings

engine = create_async_engine(
    settings.database_url,
    echo=(settings.environment == "development"),
    pool_pre_ping=True,
    # PostgreSQL local en Windows sin SSL: evita el corte de conexión
    # (WinError 10054) durante la negociación. En producción, con un
    # servidor con SSL habilitado, cambiar a {"ssl": True}.
    connect_args={"ssl": False},
)

AsyncSessionLocal = async_sessionmaker(
    engine, class_=AsyncSession, expire_on_commit=False
)


class Base(DeclarativeBase):
    """Base declarativa para todos los modelos ORM del SIIM."""


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """Dependency de FastAPI: entrega una sesión y la cierra al terminar."""
    async with AsyncSessionLocal() as session:
        yield session
