import SwiftUI

struct ControlsView: View {
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        HStack {
            Spacer()
            Button {
                viewModel.resetGame()
            } label: {
                HStack(spacing: 6) {
                    Text("🔄")
                    Text("Tornar a començar")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.7))
                .cornerRadius(16)
            }
            .buttonStyle(.plain)
            .foregroundColor(Theme.lilaFort)
        }
    }
}
