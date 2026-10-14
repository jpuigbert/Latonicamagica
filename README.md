# 🦄 La Tònica Màgica

Joc educatiu per aprendre la **síl·laba tònica** de les paraules en català. Pensat per a infantil i primària: els jugadors han d'endevinar on «sona més fort» cada paraula — aguda, plana, esdrúixola o sobresdrúixola — i sumen punts per torns.

- **App macOS** (SwiftUI): interfície de colors, música i sons personalitzables, fons de pantalla configurable i fins a 6 jugadors.
- **CLI multiplataforma** (SwiftPM): la mateixa lògica de joc en versió de text per a **Linux, Windows i macOS**, sense dependència de SwiftUI.
- **Mode Internet opcional**: cerca paraules noves a [dictionaryapi.dev](https://api.dictionaryapi.dev) (entrada en català) i les classifica a partir de la transcripció fonètica.

---

## ⬇️ Descàrrega (instal·lar sense compilar ni fer servir Git)

Ves a la pestanya **[Releases](https://github.com/jpuigbert/Latonicamagica/releases/latest)** i baixa el fitxer del teu sistema. No cal instal·lar res més.

| Sistema | Fitxer a baixar | Com instal·lar-lo |
|---|---|---|
| **macOS** | `LaTonicaMagica-macOS-v1.0.0.dmg` | Obre el DMG i **arrossega l'app a la carpeta Aplicacions** (com qualsevol programeta de Mac). |
| **Linux** (64 bits) | `LaTonicaCLI-linux-v1.0.0.tar.gz` | Descomprimeix, i a la carpeta executa `chmod +x laTonicaCLI-linux && ./laTonicaCLI-linux`. |
| **Windows** | `LaTonicaCLI-windows-v1.0.0.zip` | Descomprimeix i fes doble clic a `laTonicaCLI-windows.exe`. |

Enllaços directes de descàrrega:
- macOS: <https://github.com/jpuigbert/Latonicamagica/releases/download/v1.0.0/LaTonicaMagica-macOS-v1.0.0.dmg>
- Linux: <https://github.com/jpuigbert/Latonicamagica/releases/download/v1.0.0/LaTonicaCLI-linux-v1.0.0.tar.gz>

> **Primer cop a macOS**: com que l'app no està signada amb compte de desenvolupador d'Apple, obre-la la primera vegada amb **clic dret → Obre** (accepta l'avís). Els binaris de Linux i Windows del release es generen automàticament amb [GitHub Actions](https://github.com/jpuigbert/Latonicamagica/actions); si un dia falta algun, consulta la wiki → *Compilació i distribució*.

---

## Com es juga

1. Cada torn apareix una paraula (p. ex. `MÚSICA`).
2. El jugador activa actual tria el **tipus de paraula** prement el botó corresponent:

| Tipus | Regla | Exemple |
|---|---|---|
| **Aguda** 🔥 | La tònica és l'**última** síl·laba | `ca · MÍ` |
| **Plana** 🌿 | La tònica és la **penúltima** síl·laba | `MU · SI · ca` |
| **Esdrúixola** 🎈 | La tònica és l'**antepenúltima** síl·laba | `PA · gi · na` |
| **Sobresdrúixola** 🚀 | La tònica va **abans de l'antepenúltima** | `RÀ · pi · da · ment` |

3. Amb **Intro** (⏎) es valida la resposta: si és correcta, el jugador suma 1 punt i sona el so d'encert; si no, el joc explica per què.
4. Un altre Intro passa al **torn del següent jugador**. Es pot reiniciar la partida i afegir/treure jugadors (1–6).

Cada paraula només surt una vegada fins que s'esgota el diccionari (aleshores es barreja de nou).

---

## Com funciona (arquitectura)

### Versió macOS (`LaTonicaEnCadena/`)

Patró **MVVM** amb SwiftUI:

```
LaTonicaEnCadenaApp ── AppState (finestra + panells)
   └── ContentView
       ├── FonsView ◄──────── WallpaperService (imatge a Application Support)
       ├── MarcadorView ┐
       ├── ParaulaView  │◄── GameViewModel (@Published: jugadors, paraula,
       ├── Classificacio│    feedback, torn…)
       ├── FeedbackView │
       └── ControlsView ┘
                        ▲
              MusicService (AVFoundation: música de fons + 4 slots de SFX,
                            amb WAVs sintetitzats per BuiltinSounds)
              DictionaryService (cahu + classificació fonètica/heurística)
                  └── DictionaryAPI (URLSession → dictionaryapi.dev)
              DiccionariLocal (≈160 paraules pre-classificades, generatees
                  per tools/genera_diccionari.py)
```

- **`GameViewModel`** és el cor del joc: gestiona torns, puntuació, selecció de paraula (local o API) i validació de la resposta.
- **`TipusTonica`** (model) defineix els 4 tipus i la seva explicació didàctica; s'usa tant per validar com per generar el missatge de retroalimentació.
- **`DictionaryService`**: si el mode Internet és actiu, demana la paraula a l'API i la classifica comptant separadors sil·làbics després del marca d'accent principal (`ˈ`) en la transcripció IPA; si no hi ha fonètica, aplica una heurística (accent gràfic, sufix `-ment`, terminació a/e/o).
- **`MusicService` + `BuiltinSounds`**: cada moment del joc (fons, encert, error, canvi de torn, reinici) té un *slot* de so. Per defecte sonen WAVs generats per síntesi en memòria; l'usuari pot triar els seus propis MP3/WAV des del panell **Música i sons** (⌘,).
- **`WallpaperService`**: copia la imatge triada a `~/Library/Application Support/LaTonicaEnCadena/` perquè sobrevisqui si l'original es mou.

### Versió multiplataforma (`Multiplataforma/`)

Paquet **SwiftPM** amb dos targets:

- **`LaTonicaCore`** — models purs de Foundation (`Paraula`, `TipusTonica`, `DiccionariLocal`), sense UI.
- **`laTonicaCLI`** — bucle de joc de terminal (respon 1–4, `p` puntuació, `s` sortir).

El nucli és **compartit** amb la versió macOS: el script `build_cli_mac.sh` compila `Sources/LaTonicaCore` directament amb `swiftc`, i per això el codi contingui `#if canImport(LaTonicaCore)` per funcionar tant amb SPM com compilat junt.

### Generació del diccionari (`tools/`)

`genera_diccionari.py` llegeix `tools/paraules/{agudes,planes,esdruixoles,sobresdruixoles}.txt`, **verifica independentment** la classificació amb regles ortogràfiques i síl·labificació heurística del català (diftons/hiats, «u» post-q/g, descarts d'apostrofs i guionets), i genera `Data/DiccionariLocal.swift`. Així el diccionari del joc mai conté paraules mal classificades.

---

## Compilació i instal·lació

> ⚠️ **Aquest projecte es desenvolupa i es verifica en un Mac.** La versió
> macOS està comprovada; les versions Linux i Windows compilen el **mateix nucli
> pur de Foundation** (`LaTonicaCore`), però no s'han executat en maquinari real
> d'aquestes plataformes. Per això cada secció inclou una **guia pas a pas** i
> una llista de **problemes freqüents**: si alguna cosa no funciona, segueix els passos
> i consulta la wiki → [Compilació-i-distribució](../../wiki/Compilació-i-distribució).

### Requisits per Plataforma

| Plataforma | Producte | Què cal tenir instal·lat |
|---|---|---|
| **macOS** | App `.app` gràfica | Command Line Tools (`xcode-select --install`) — **no** cal Xcode |
| **macOS / Linux / Windows** | CLI de text | Swift 5.9+ toolchain |
| **Linux (cross-compile des del Mac)** | CLI ELF | Docker Desktop |

### 1 · App de macOS (des del mateix Mac)

```bash
./build_app.sh                  # compila, signa ad-hoc i instal·la a /Applications
./build_app.sh ~/Applications   # o en un destí alternatiu
```

El script fa `swiftc` sobre tots els `.swift` de `LaTonicaEnCadena/`, munta el bundle `.app` (amb `Packaging/Info.plist` i `AppIcon.icns`), el signa *ad-hoc* i el copia al destí.

> **Workaround inclòs**: el script aplica una ombra VFS (`Packaging/clt_overlay.yaml`) que corregeix un `module.modulemap` duplicat que redefineix `SwiftBridging` en certs Command Line Tools (compilador i SDK desfasats). Si veus l'error `redefinition of module 'SwiftBridging'`, aquest és el motiu.

### 2 · CLI natiu (funciona igual als tres sistemes)

```bash
# macOS o Linux, amb el Swift toolchain al PATH (o a Windows amb xcrun/swift.exe):
cd Multiplataforma
swift run laTonicaCLI           # compila i executa en mode debug
swift build -c release          # només compila; binari a .build/release/laTonicaCLI(.exe)
```

### 3 · CLI per a Linux — pas a pas

**Opció A — des d'un Linux real (recomanada, el que fas servir):**
```bash
# 1. Instal·la Swift:
#    Ubuntu/Debian: https://swift.org/install/linux/ (o «apt install swiftlang» si hi és)
curl -sL https://swift.org | grep -q . || echo "comprova connexió"
swift --version                 # ha de dir 5.9 o superior

# 2. Baixa el repo i compila:
git clone https://github.com/jpuigbert/Latonicamagica.git
cd Latonicamagica/Multiplataforma
./build_linux.sh
#    → binari a: dist/laTonicaCLI-linux
./dist/laTonicaCLI-linux
```

**Opció B — des del Mac, amb Docker (cross-compile):**
```bash
cd Multiplataforma
./build_linux.sh                # detecta que no ets a Linux i usa Docker
```
El script fa `docker build -f Dockerfile.linux` (imatge `swift:5.9-jammy`) i n'extreu el binari a `dist/laTonicaCLI-linux`.

**Problemes freqüents a Linux:**
- *«command not found: swift»* → el toolchain no és al `PATH`. Afegeix-ne la carpeta `usr/bin` (o l'equivalent de la teva instal·lació) al `PATH` i torna-ho a intentar.
- *«docker: permission denied»* (Opció B) → afegeix el teu usuari al grup `docker` (`sudo usermod -aG docker $USER`), tanca i reobre sessió, o executa el script amb `sudo`.
- *Error de llicència/SDK de Swift al Docker* → la imatge `swift:5.9-jammy` oficial ja ve preparada; si la teva xarxa bloci Docker Hub, prova `docker pull swift:5.9-jammy` primer.
- *Emoji i accents es veuen com a `?`* → cal terminal UTF-8: `export LANG=C.UTF-8`.

### 4 · CLI per a Windows — pas a pas

**Requisit:** [Swift toolchain per a Windows](https://www.swift.org/download/#windows) (instal·lador `.msi`). Durant la instal·lació, activa l'opció d'afegir Swift al `PATH`. També cal **Visual Studio Build Tools** (compilador C++) perquè SwiftPM pugui enllaçar.

```powershell
# 1. Obre PowerShell i comprova Swift:
swift --version                 # ha de sortir 5.9+

# 2. Baixa el repo (git o ZIP) i ves a la carpeta:
git clone https://github.com/jpuigbert/Latonicamagica.git
cd Latonicamagica\Multiplataforma

# 3. Executa el script (habilita execució de scripts un cop):
powershell -ExecutionPolicy Bypass -File .\build_windows.ps1
#    → binari a: dist\laTonicaCLI-windows.exe
dist\laTonicaCLI-windows.exe
```

**Problemes freqüents a Windows:**
- *«swift no es reconeix com a cmdlet»* → el toolchain no és al `PATH`. Reinstal·la Swift marcant l'opció del `PATH`, o afegeix manualment `C:\Program Files\Swift\usr\bin`.
- *error de linker `link.exe not found`* → falta **Visual Studio Build Tools** amb el component *Desktop development with C++*.
- *PowerShell bloqueja el script* → executa'l amb `-ExecutionPolicy Bypass` (com a dalt) o desbloquex-lo per a l'usuari: `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`.
- *Consola amb `?` en lloc d'accentos/emoji* → el script ja fa `chcp 65001`; si mateix falla, canvia la font de la consola a una compatible amb Unicode (Windows Terminal ho és per defecte).
- *El `.exe` no arrenca en un altre PC* → cal que el destí tingui la mateixa toolchain/runtime o distribueix el binari estàtic; revisa que l'arquitectura (x86_64) coincideixi.

### 5 · CLI per a aquest Mac (variant sense Xcode, amb swiftc)

```bash
cd Multiplataforma
./build_cli_mac.sh              # usa el mateix workaround VFS que build_app.sh
# → executable a: build/laTonicaCLI-mac
```

---

## Estructura del repositori

```
├── LaTonicaEnCadena/     # App SwiftUI per a macOS
│   ├── Data/             #   DiccionariLocal (generado) + APIResponse
│   ├── Models/           #   Paraula, Player, TipusTonica
│   ├── Services/         #   Música, sons, diccionari API, fons
│   ├── ViewModels/       #   GameViewModel (logica del joc)
│   └── Views/            #   Vistes SwiftUI (tem visual a Theme.swift)
├── Multiplataforma/      # Paquet SwiftPM: nucli + CLI (Linux/Windows/macOS)
├── Packaging/            # Info.plist, icona, overlay VFS de compilació
├── tools/                # Generador del diccionari + llestes de paraules
├── build_app.sh          # Compilacio i instal·acio de l'app macOS
└── Wiki                  # Documentacio ampliada (vegeu a baix)
```

## 📖 Wiki del projecte

La wiki ampliada és a la pestanya **Wiki** del repositori:

1. [Com funciona el joc](../../wiki/Com-funciona-el-joc) — mecànica, regles i modes
2. [Arquitectura](../../wiki/Arquitectura) — codi a nivell de mòdul
3. [Guia d'usuari](../../wiki/Guia-d'usuari) — manual complet de l'app
4. [Compilació i distribució](../../wiki/Compilació-i-distribució) — macOS, Linux i Windows
5. [Manual de GitHub](../../wiki/Manual-de-GitHub) — com es gestiona aquest repositori
6. [Manual de Releases](../../wiki/Manual-de-Releases) — com es publiquen versions

---

## Llicència i credits

Desenvolupat com a projecte educatiu. Els sons per defecte es generen per síntesi (no s'usen fitxers de tercers). La mode d'Internet consulta l'API pública de Free Dictionary Dictionary (entrada català).
