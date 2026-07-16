"""Endpoints de autenticación: login, perfil, logout y cambio de contraseña."""
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Request, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user, obtener_permisos, obtener_roles
from app.core.database import get_db
from app.core.security import (
    crear_access_token,
    decodificar_token,
    hashear_password,
    verificar_password,
)
from app.models.core import LogAcceso, SesionUsuario, Usuario
from app.schemas.auth import CambiarPasswordRequest, Token, UsuarioMe

router = APIRouter(prefix="/auth", tags=["autenticación"])

MAX_INTENTOS = 5


def _contexto(request: Request) -> tuple[str | None, str | None]:
    ip = request.client.host if request.client else None
    return ip, request.headers.get("user-agent")


@router.post("/login", response_model=Token)
async def login(
    request: Request,
    form: OAuth2PasswordRequestForm = Depends(),
    db: AsyncSession = Depends(get_db),
):
    """Autentica por usuario y contraseña. Devuelve un token JWT."""
    ip, ua = _contexto(request)
    usuario = (
        await db.execute(select(Usuario).where(Usuario.username == form.username))
    ).scalar_one_or_none()

    # Credenciales incorrectas
    if usuario is None or not verificar_password(form.password, usuario.password_hash):
        if usuario is not None:
            usuario.intentos_fallidos = (usuario.intentos_fallidos or 0) + 1
            if usuario.intentos_fallidos >= MAX_INTENTOS:
                usuario.bloqueado = True
                usuario.motivo_bloqueo = "Bloqueo automático por intentos fallidos"
        db.add(
            LogAcceso(
                id_usuario=usuario.id_usuario if usuario else None,
                username_intento=form.username,
                tipo_evento="LOGIN_FAIL",
                ip_origen=ip,
                user_agent=ua,
                detalle="Usuario o contraseña incorrectos",
            )
        )
        await db.commit()
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Usuario o contraseña incorrectos",
        )

    # Usuario inactivo o bloqueado
    if not usuario.activo or usuario.bloqueado:
        db.add(
            LogAcceso(
                id_usuario=usuario.id_usuario,
                username_intento=form.username,
                tipo_evento="LOGIN_FAIL",
                ip_origen=ip,
                user_agent=ua,
                detalle="Usuario inactivo o bloqueado",
            )
        )
        await db.commit()
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Usuario inactivo o bloqueado. Contacta al administrador.",
        )

    # Éxito: emitir token, registrar sesión y bitácora
    token, jti, expira = crear_access_token(usuario.id_usuario)
    usuario.intentos_fallidos = 0
    usuario.ultimo_login = datetime.now(timezone.utc)
    db.add(
        SesionUsuario(
            id_usuario=usuario.id_usuario,
            token_jti=jti,
            ip_origen=ip,
            user_agent=ua,
            fecha_expiracion=expira,
        )
    )
    db.add(
        LogAcceso(
            id_usuario=usuario.id_usuario,
            username_intento=form.username,
            tipo_evento="LOGIN_OK",
            ip_origen=ip,
            user_agent=ua,
        )
    )
    await db.commit()
    return Token(
        access_token=token,
        debe_cambiar_password=usuario.debe_cambiar_password,
    )


@router.get("/me", response_model=UsuarioMe)
async def me(
    usuario: Usuario = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Perfil del usuario autenticado, con sus roles y permisos efectivos."""
    roles = sorted(await obtener_roles(db, usuario.id_usuario))
    permisos = sorted(await obtener_permisos(db, usuario.id_usuario))
    return UsuarioMe(
        id_usuario=usuario.id_usuario,
        username=usuario.username,
        email=usuario.email,
        nombre_completo=usuario.nombre_completo,
        debe_cambiar_password=usuario.debe_cambiar_password,
        roles=roles,
        permisos=permisos,
    )


@router.post("/logout")
async def logout(
    request: Request,
    usuario: Usuario = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Revoca la sesión del token actual."""
    auth = request.headers.get("authorization", "")
    token = auth[7:] if auth.lower().startswith("bearer ") else ""
    payload = decodificar_token(token)
    if payload and payload.get("jti"):
        sesion = (
            await db.execute(
                select(SesionUsuario).where(SesionUsuario.token_jti == payload["jti"])
            )
        ).scalar_one_or_none()
        if sesion is not None:
            sesion.revocado = True
            sesion.fecha_revocacion = datetime.now(timezone.utc)
    db.add(LogAcceso(id_usuario=usuario.id_usuario, tipo_evento="LOGOUT"))
    await db.commit()
    return {"mensaje": "Sesión cerrada correctamente"}


@router.post("/cambiar-password")
async def cambiar_password(
    datos: CambiarPasswordRequest,
    usuario: Usuario = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Cambia la contraseña del usuario autenticado."""
    if not verificar_password(datos.password_actual, usuario.password_hash):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="La contraseña actual no es correcta",
        )
    usuario.password_hash = hashear_password(datos.password_nueva)
    usuario.debe_cambiar_password = False
    usuario.fecha_ultimo_password = datetime.now(timezone.utc)
    db.add(LogAcceso(id_usuario=usuario.id_usuario, tipo_evento="CAMBIO_PASSWORD"))
    await db.commit()
    return {"mensaje": "Contraseña actualizada correctamente"}
