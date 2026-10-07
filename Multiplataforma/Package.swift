// swift-tools-version:5.9
// Paquet SPM de "La Tònica Màgica" per a Linux, Windows i macOS.
// El nucli (models + diccionari) és pur Foundation, sense SwiftUI.
import PackageDescription

let package = Package(
    name: "LaTonicaEnCadena",
    targets: [
        .target(name: "LaTonicaCore"),
        .executableTarget(
            name: "laTonicaCLI",
            dependencies: ["LaTonicaCore"]
        ),
    ]
)
