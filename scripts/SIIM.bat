@echo off
rem ============================================================
rem  SIIM - Lanzador del sistema
rem  H. Ayuntamiento del Municipio de Tulum, Quintana Roo
rem
rem  Doble clic: arranca todo (pide permisos de administrador solo)
rem  Clic derecho -> "Ejecutar como administrador": tambien funciona
rem ============================================================
title SIIM - Lanzador
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0arranque-siim.ps1" %*
echo.
echo (Esta ventana se puede cerrar - los servidores corren en sus propias ventanas)
pause
