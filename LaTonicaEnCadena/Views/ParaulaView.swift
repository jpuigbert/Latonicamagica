import SwiftUI

struct ParaulaView: View {
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                VStack(spacing: 12) {
                    ProgressView().scaleEffect(1.4)
                    Text("Buscant una paraula bonica… 🔍✨")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
                .padding()
            } else if let word = viewModel.currentWord {
                VStack(spacing: 10) {
                    Text(word.origen == .api ? "🌐 Paraula d'Internet" : "📚 Paraula del joc")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.7))
                        .cornerRadius(12)
                    
                    Text(word.text)
                        .font(.system(size: 64, weight: .heavy, design: .rounded))
                        .foregroundColor(Theme.lilaFort)
                        .shadow(color: .white.opacity(0.9), radius: 2, x: 0, y: 2)
                }
                .padding(.vertical, 18)
                .padding(.horizontal, 40)
                .background(
                    RoundedRectangle(cornerRadius: 30)
                        .fill(Color.white.opacity(0.75))
                        .shadow(color: Theme.rosaFort.opacity(0.25), radius: 10, y: 6)
                )
            } else {
                Text("—")
                    .font(.system(size: 64, weight: .heavy, design: .rounded))
                    .padding()
            }
        }
        .frame(minHeight: 150)
    }
}
