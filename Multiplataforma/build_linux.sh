#!/bin/bash
# Compila la versió de terminal per a Linux.
#   - Si l'executes DINS d'un Linux: usa el swift instal·lat directament.
#   - Si l'executes des d'aquest macOS: fa servir Docker (Dockerfile.linux)
#     per generar el binari, i l'extreu a dist/.
set -euo pipefail
CARPETA="$(cd "$(dirname "$0")" && pwd)"
cd "$CARPETA"
mkdir -p dist

if [ "$(uname)" = "Linux" ]; then
    echo "==> Compilant nativament amb Swift PM..."
    swift build -c release
    cp "$(swift build -c release --show-bin-path)/laTonicaCLI" dist/laTonicaCLI-linux
    echo "Fet! Binari: $CARPETA/dist/laTonicaCLI-linux"
else
    if ! command -v docker >/dev/null 2>&1; then
        echo "⚠️  Per compilar des de macOS cal Docker (o executa aquest"
        echo "    script dins d'un Linux amb el Swift Toolchain instal·lat)."
        exit 1
    fi
    echo "==> Compilant per a Linux amb Docker..."
    docker build -f Dockerfile.linux -t la-tonica-linux .
    docker run --rm -v "$CARPETA/dist:/out" la-tonica-linux \
        cp /pkg/.build/release/laTonicaCLI /out/laTonicaCLI-linux
    chmod +x dist/laTonicaCLI-linux
    echo "Fet! Binari: $CARPETA/dist/laTonicaCLI-linux"
fi
