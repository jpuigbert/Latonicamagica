#!/bin/bash
# Compila i empaqueta "La Tònica Màgica" per a macOS sense Xcode.
# Ús: ./build_app.sh [directori_destí]
set -euo pipefail

PROJECTOR="$(cd "$(dirname "$0")" && pwd)"
NOM_APP="La Tònica Màgica"
NOM_EXEC="LaTonicaEnCadena"
ARXIU_PROJECTE="$PROJECTOR/build"
DESTI="${1:-/Applications}"

ARCH="$(uname -m)"
SDK="$(xcrun --show-sdk-path)"

# Correcció del Command Line Tools d'aquest Mac: el compilador (6.0.3.1.10)
# no coincideix amb l'SDK (6.0.3.1.5) i hi ha un module.modulemap duplicat
# que redefineix 'SwiftBridging'. Ombrejem aquell fitxer amb una capa VFS
# (s'aplica via -Xfrontend perque es propague al constructor de moduls).
SHADOW="$PROJECTOR/Packaging/modulemap_shadow.txt"
OVERLAY="$PROJECTOR/Packaging/clt_overlay.yaml"
sed "s#__SHADOW_PATH__#$SHADOW#" "$PROJECTOR/Packaging/clt_overlay.yaml.in" > "$OVERLAY"
VFS_FLAGS=(-Xfrontend -vfsoverlay -Xfrontend "$OVERLAY")

# Recollim els fitxers font en un array (maneja bé els noms amb espais)
FILES=()
while IFS= read -r -d '' f; do
  FILES+=("$f")
done < <(find "$PROJECTOR/$NOM_EXEC" -name "*.swift" -print0)

echo "==> 1/4 Compilant per a $ARCH (${#FILES[@]} fitxers)..."
rm -rf "$ARXIU_PROJECTE"
mkdir -p "$ARXIU_PROJECTE"

xcrun swiftc \
  -sdk "$SDK" \
  -target "${ARCH}-apple-macos13.0" \
  -swift-version 5 \
  "${VFS_FLAGS[@]}" \
  -o "$ARXIU_PROJECTE/$NOM_EXEC" \
  "${FILES[@]}"

echo "==> 2/4 Creant l'estructura de l'aplicació..."
APP="$ARXIU_PROJECTE/$NOM_APP.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$ARXIU_PROJECTE/$NOM_EXEC" "$APP/Contents/MacOS/$NOM_EXEC"
cp "$PROJECTOR/Packaging/Info.plist" "$APP/Contents/Info.plist"
printf 'APPL????' > "$APP/Contents/PkgInfo"

if [ -f "$PROJECTOR/Packaging/AppIcon.icns" ]; then
  cp "$PROJECTOR/Packaging/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"
fi

echo "==> 3/4 Signant l'aplicació (ad-hoc)..."
codesign --force --deep --sign - "$APP" 2>/dev/null || codesign --force --sign - "$APP"

echo "==> 4/4 Instal·lant a $DESTI..."
mkdir -p "$DESTI"
if [ -d "$DESTI/$NOM_APP.app" ]; then
  rm -rf "$DESTI/$NOM_APP.app"
fi
cp -R "$APP" "$DESTI/"

echo "Fet! Instal·lada a: $DESTI/$NOM_APP.app"
