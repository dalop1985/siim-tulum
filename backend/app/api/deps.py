"""Dependencias de FastAPI: usuario actual y verificación de permisos (RBAC)."""
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.security import decodificar_token
from app.models.core import CatPermiso, CatRol, RolPermiso, SesionUsuario, Usuario, UsuarioRol

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/login")

CRED_EXC = HTTPException(
    status_code=status.HTTP_401_UNAUTHORIZED,
    detail="Credenciales inválidas o expiradas",
    headers={"WWW-Authenticate": "Bearer"},
)


async def get_current_user(
    token: str = Depends(oauth2_scheme), db: AsyncSession = Depends(get_db)
) -> Usuario:
    payload = decodificar_token(token)
    if payload is None or payload.get("sub") is None:
        raise CRED_EXC

    # ¿La sesión de este token fue revocada (logout)?
    jti = payload.get("jti")
    if jti:
        sesion = (
            await db.execute(select(SesionUsuario).where(SesionUsuario.token_jti == jti))
        ).scalar_one_or_none()
        if sesion is not None and sesion.revocado:
            raise CRED_EXC

    usuario = await db.get(Usuario, int(payload["sub"]))
    if usuario is None or not usuario.activo or usuario.bloqueado:
        raise CRED_EXC
    return usuario


async def obtener_roles(db: AsyncSession, id_usuario: int) -> set[str]:
    stmt = (
        select(CatRol.clave)
        .join(UsuarioRol, UsuarioRol.id_rol == CatRol.id_rol)
        .where(UsuarioRol.id_usuario == id_usuario, UsuarioRol.activo.is_(True))
    )
    return set((await db.execute(stmt)).scalars().all())


async def obtener_permisos(db: AsyncSession, id_usuario: int) -> set[str]:
    """Permisos efectivos = unión de los permisos de todos los roles activos."""
    stmt = (
        select(CatPermiso.clave)
        .join(RolPermiso, RolPermiso.id_permiso == CatPermiso.id_permiso)
        .join(UsuarioRol, UsuarioRol.id_rol == RolPermiso.id_rol)
        .where(UsuarioRol.id_usuario == id_usuario, UsuarioRol.activo.is_(True))
    )
    return set((await db.execute(stmt)).scalars().all())


def require_permission(clave_permiso: str):
    """Dependency: exige un permiso. SUPER_ADMIN pasa siempre.

    Uso:  Depends(require_permission("PREDIAL:CONSULTAR"))
    """

    async def verificar(
        usuario: Usuario = Depends(get_current_user),
        db: AsyncSession = Depends(get_db),
    ) -> Usuario:
        roles = await obtener_roles(db, usuario.id_usuario)
        if "SUPER_ADMIN" in roles:
            return usuario
        permisos = await obtener_permisos(db, usuario.id_usuario)
        if clave_permiso not in permisos:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Acceso denegado: requiere el permiso {clave_permiso}",
            )
        return usuario

    return verificar
