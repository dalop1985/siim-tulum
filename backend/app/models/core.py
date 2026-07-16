"""Modelos ORM del schema `core` necesarios para autenticación y RBAC."""
from datetime import datetime

from sqlalchemy import BigInteger, Boolean, DateTime, Integer, SmallInteger, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class Usuario(Base):
    __tablename__ = "usuario"
    __table_args__ = {"schema": "core"}

    id_usuario: Mapped[int] = mapped_column(Integer, primary_key=True)
    id_area: Mapped[int | None] = mapped_column(Integer)
    username: Mapped[str] = mapped_column(String(50))
    email: Mapped[str] = mapped_column(String(200))
    password_hash: Mapped[str] = mapped_column(String(255))
    nombre: Mapped[str] = mapped_column(String(100))
    apellido_paterno: Mapped[str] = mapped_column(String(100))
    apellido_materno: Mapped[str | None] = mapped_column(String(100))
    nombre_completo: Mapped[str] = mapped_column(Text)  # columna generada en la BD
    ultimo_login: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    intentos_fallidos: Mapped[int] = mapped_column(SmallInteger, default=0)
    bloqueado: Mapped[bool] = mapped_column(Boolean, default=False)
    motivo_bloqueo: Mapped[str | None] = mapped_column(String(300))
    activo: Mapped[bool] = mapped_column(Boolean, default=True)
    debe_cambiar_password: Mapped[bool] = mapped_column(Boolean, default=True)
    fecha_ultimo_password: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))


class CatRol(Base):
    __tablename__ = "cat_rol"
    __table_args__ = {"schema": "core"}

    id_rol: Mapped[int] = mapped_column(Integer, primary_key=True)
    clave: Mapped[str] = mapped_column(String(50))
    nombre: Mapped[str] = mapped_column(String(200))


class UsuarioRol(Base):
    __tablename__ = "usuario_rol"
    __table_args__ = {"schema": "core"}

    id_usuario_rol: Mapped[int] = mapped_column(Integer, primary_key=True)
    id_usuario: Mapped[int] = mapped_column(Integer)
    id_rol: Mapped[int] = mapped_column(Integer)
    activo: Mapped[bool] = mapped_column(Boolean, default=True)


class CatPermiso(Base):
    __tablename__ = "cat_permiso"
    __table_args__ = {"schema": "core"}

    id_permiso: Mapped[int] = mapped_column(Integer, primary_key=True)
    id_modulo: Mapped[int] = mapped_column(Integer)
    clave: Mapped[str] = mapped_column(String(100))
    nombre: Mapped[str] = mapped_column(String(200))


class RolPermiso(Base):
    __tablename__ = "rol_permiso"
    __table_args__ = {"schema": "core"}

    id_rol_permiso: Mapped[int] = mapped_column(Integer, primary_key=True)
    id_rol: Mapped[int] = mapped_column(Integer)
    id_permiso: Mapped[int] = mapped_column(Integer)


class SesionUsuario(Base):
    __tablename__ = "sesion_usuario"
    __table_args__ = {"schema": "core"}

    id_sesion: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    id_usuario: Mapped[int] = mapped_column(Integer)
    token_jti: Mapped[str] = mapped_column(String(100))
    ip_origen: Mapped[str | None] = mapped_column(String(45))
    user_agent: Mapped[str | None] = mapped_column(String(500))
    fecha_expiracion: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    revocado: Mapped[bool] = mapped_column(Boolean, default=False)
    fecha_revocacion: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))


class LogAcceso(Base):
    __tablename__ = "log_acceso"
    __table_args__ = {"schema": "core"}

    id_log: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    id_usuario: Mapped[int | None] = mapped_column(Integer)
    username_intento: Mapped[str | None] = mapped_column(String(50))
    tipo_evento: Mapped[str] = mapped_column(String(30))
    ip_origen: Mapped[str | None] = mapped_column(String(45))
    user_agent: Mapped[str | None] = mapped_column(String(500))
    detalle: Mapped[str | None] = mapped_column(String(500))
