@echo off
setlocal
REM Godot MCP Server Launcher
cd /d "%~dp0"

where node >nul 2>&1
if errorlevel 1 (
  echo [ERROR] Node.js is not installed or not available in PATH.
  echo Install Node.js 18+ and retry.
  exit /b 1
)

where npx >nul 2>&1
if errorlevel 1 (
  echo [ERROR] npx is not available in PATH.
  echo Ensure npm is installed correctly with Node.js and retry.
  exit /b 1
)

echo Starting Godot MCP Server on ws://127.0.0.1:6505...
npx -y godot-mcp-server
set EXIT_CODE=%ERRORLEVEL%

if not "%EXIT_CODE%"=="0" (
  echo [ERROR] Failed to start godot-mcp-server ^(exit code %EXIT_CODE%^).
  echo If this is the first run, check npm/network access and retry.
)

exit /b %EXIT_CODE%
