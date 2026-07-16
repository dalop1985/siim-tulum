"""Esquemas Pydantic para autenticación."""
from pydantic import BaseModel, Field


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
    debe_cambiar_password: bool = False


class UsuarioMe(BaseModel):
    id_usuario: int
    username: str
    email: str
    nombre_completo: str
    debe_cambiar_password: bool
    roles: list[str]
    permisos: list[str]


class CambiarPasswordRequest(BaseModel):
    password_actual: str
    password_nueva: str = Field(min_length=8, description="Mínimo 8 caracteres")
