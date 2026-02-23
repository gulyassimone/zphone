# Simple runner for z-phone Lua tests
# Usage: set $env:LUA_EXE to override the Lua executable path (defaults to LuaForWindows 5.1)

$lua = $env:LUA_EXE
if (-not $lua) {
    $lua = "C:\Program Files (x86)\Lua\5.1\lua.exe"
}

if (-not (Test-Path $lua)) {
    Write-Error "Lua executable not found. Set LUA_EXE or install Lua. Tried '$lua'."
    exit 1
}

& $lua "client/tests/run.lua"
exit $LASTEXITCODE
