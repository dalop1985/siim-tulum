"""Utilidades de seguridad: hashing de contraseñas (bcrypt) y JWT (JOSE)."""
import uuid
from datetime import datetime, timedelta, timezone
from typing import Any

import bcrypt
from jose import JWTError, jwt

from app.core.config import settings


def verificar_password(plano: str, hash_almacenado: str) -> bool:
    """Compara una contraseña en claro contra su hash bcrypt."""
    try:
        return bcrypt.checkpw(plano.encode("utf-8"), hash_almacenado.encode("utf-8"))
    except (ValueError, TypeError):
        return False


def hashear_password(plano: str) -> str:
    """Genera un hash bcrypt (cost 12) para una contraseña."""
    return bcrypt.hashpw(plano.encode("utf-8"), bcrypt.gensalt(rounds=12)).decode("utf-8")


def crear_access_token(id_usuario: int) -> tuple[str, str, datetime]:
    """Crea un JWT firmado. Devuelve (token, jti, fecha_expiracion)."""
    jti = str(uuid.uuid4())
    expira = datetime.now(timezone.utc) + timedelta(
        minutes=settings.access_token_expire_minutes
    )
    payload = {"sub": str(id_usuario), "jti": jti, "exp": expira}
    token = jwt.encode(payload, settings.secret_key, algorithm=settings.algorithm)
    return token, jti, expira


def decodificar_token(token: str) -> dict[str, Any] | None:
    """Valida y decodifica un JWT. Devuelve el payload o None si es inválido."""
    try:
        return jwt.decode(token, settings.secret_key, algorithms=[settings.algorithm])
    except JWTError:
        return None
