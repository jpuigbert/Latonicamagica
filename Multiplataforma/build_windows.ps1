# Compila "La Tònica Màgica" (versió de terminal) per a Windows.
# Requereix el Swift Toolchain per a Windows: https://swift.org/download/
# Executa'l des de PowerShell en la carpeta Multiplataforma:
#   powershell -ExecutionPolicy Bypass -File .\build_windows.ps1

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

# Assegura't que la consola usa UTF-8 (per als accents i els emoji)
chcp 65001 | Out-Null

Write-Host "==> Compilant amb Swift PM..."
swift build -c release

New-Item -ItemType Directory -Force -Path dist | Out-Null
$bin = (swift build -c release --show-bin-path)
Copy-Item -Force "$bin\laTonicaCLI.exe" "dist\laTonicaCLI-windows.exe"

Write-Host "Fet! Binari: dist\laTonicaCLI-windows.exe"
