import SwiftUI

struct ClassificacioView: View {
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        VStack(spacing: 14) {
            Text("On sona més fort? 🔔")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(Theme.lilaFort)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(TipusTonica.allCases) { tipus in
                    BotonClassificacio(
                        tipus: tipus,
                        seleccionat: viewModel.selectedTipus == tipus,
                        desactivat: viewModel.isAnswered || viewModel.isLoading
                    ) {
                        viewModel.selectedTipus = tipus
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

private struct BotonClassificacio: View {
    let tipus: TipusTonica
    let seleccionat: Bool
    let desactivat: Bool
    let accio: () -> Void
    
    var body: some View {
        Button(action: accio) {
            HStack(spacing: 12) {
                Text(Theme.emoji(for: tipus)).font(.system(size: 30))
                VStack(alignment: .leading, spacing: 2) {
                    Text(tipus.rawValue)
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                    Text(pista)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(Theme.color(for: tipus).opacity(seleccionat ? 1.0 : 0.75))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(seleccionat ? Color.white : Color.clear, lineWidth: 4)
            )
            .foregroundColor(.white)
            .scaleEffect(seleccionat ? 1.05 : 1.0)
            .shadow(color: Theme.color(for: tipus).opacity(0.4), radius: 6, y: 4)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: seleccionat)
        }
        .buttonStyle(.plain)
        .disabled(desactivat)
        .opacity(desactivat ? 0.55 : 1.0)
    }
    
    private var pista: String {
        switch tipus {
        case .aguda:          return "a l'última síl·laba"
        case .plana:          return "a la penúltima"
        case .esdruixola:     return "a l'antepenúltima"
        case .sobresdruixola: return "encara més enrere"
        }
    }
}
