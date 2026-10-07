#!/bin/bash
# Compila la versió de terminal per a aquest mateix Mac (Intel/x86_64)
# usant directament swiftc, amb el mateix workaround del VFS overlay que
# el build_app.sh (els Command Line Tools d'aquest Mac tenen un
# module.modulemap duplicat trencat).
set -euo pipefail
CARPETA="$(cd "$(dirname "$0")" && pwd)"
ARREL="$(dirname "$CARPETA")"
OUTPUT="$ARREL/build/laTonicaCLI-mac"

ARCH="$(uname -m)"
SDK="$(xcrun --show-sdk-path)"
OVERLAY="$ARREL/Packaging/clt_overlay.yaml"

# Si l'overlay no existeix (no s'ha executat el build_app.sh), el genera
if [ ! -f "$OVERLAY" ]; then
    sed "s#__SHADOW_PATH__#$ARREL/Packaging/modulemap_shadow.txt#" \
        "$ARREL/Packaging/clt_overlay.yaml.in" > "$OVERLAY"
fi

mkdir -p "$ARREL/build"
echo "==> Compilant CLI per a $ARCH..."
xcrun swiftc \
  -sdk "$SDK" \
  -target "${ARCH}-apple-macos13.0" \
  -swift-version 5 \
  -Xfrontend -vfsoverlay -Xfrontend "$OVERLAY" \
  -o "$OUTPUT" \
  "$CARPETA/Sources/LaTonicaCore/Paraula.swift" \
  "$CARPETA/Sources/LaTonicaCore/TipusTonica.swift" \
  "$CARPETA/Sources/LaTonicaCore/DiccionariLocal.swift" \
  "$CARPETA/Sources/laTonicaCLI/main.swift"

echo "Fet! Executable: $OUTPUT"
echo "Prova'l amb:      \"$OUTPUT\""
