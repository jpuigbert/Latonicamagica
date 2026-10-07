import SwiftUI

/// Fons de la finestra: el degradat pastel de sempre o, si l'usuari n'ha
/// triat una, la imatge de fons (wallpaper) amb un vel clar per no perdre
/// la llegibilitat dels textos.
struct FonsView: View {
    @ObservedObject var wallpaper: WallpaperService

    var body: some View {
        ZStack {
            Theme.fons

            if let img = wallpaper.image {
                Image(nsImage: img)
                    .resizable()
                    .scaledToFill()

                // Vel blanc fluix perquè els textos es segueixin llegint bé
                Color.white.opacity(0.30)
            }
        }
        .ignoresSafeArea()
    }
}
