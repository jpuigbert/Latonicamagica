import SwiftUI

struct MarcadorView: View {
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                ForEach(Array(viewModel.players.enumerated()), id: \.element.id) { index, player in
                    PlayerCard(
                        player: player,
                        isActive: viewModel.currentPlayerIndex == index,
                        color: Theme.paletaJugadors[index % Theme.paletaJugadors.count]
                    )
                }
                
                // Botons per ajustar el nombre de jugadors
                VStack(spacing: 6) {
                    Button {
                        viewModel.addPlayer()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(Theme.lilaFort)
                    .opacity(viewModel.potAfegirJugador ? 1 : 0.35)
                    .disabled(!viewModel.potAfegirJugador)
                    .help("Afegeix un jugador (màx. 6)")
                    
                    Button {
                        viewModel.removePlayer()
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 22))
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(Theme.rosaFort)
                    .opacity(viewModel.potTreureJugador ? 1 : 0.35)
                    .disabled(!viewModel.potTreureJugador)
                    .help("Treu l'últim jugador (mín. 1)")
                }
            }
            
            HStack(spacing: 6) {
                Text("👉 Ara juga:")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                Text(viewModel.currentPlayer.name)
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundColor(Theme.lilaFort)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.7))
            .cornerRadius(20)
        }
    }
}

private struct PlayerCard: View {
    let player: Player
    let isActive: Bool
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Text(player.name)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            HStack(spacing: 4) {
                Text("\(player.score)")
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                Text("⭐️").font(.system(size: 18))
            }
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(isActive ? color.opacity(0.35) : Color.white.opacity(0.55))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(isActive ? color : Color.white, lineWidth: 4)
        )
        .scaleEffect(isActive ? 1.05 : 1.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isActive)
    }
}
