import SwiftUI

struct FeedbackView: View {
    @ObservedObject var viewModel: GameViewModel
    @State private var batega = false
    
    var body: some View {
        VStack(spacing: 16) {
            if !viewModel.feedback.isEmpty {
                HStack(alignment: .top, spacing: 12) {
                    Text(viewModel.feedbackCorrecte ? "🎉" : "💭")
                        .font(.system(size: 36))
                    
                    Text(viewModel.feedback)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.white)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 22)
                        .fill(viewModel.feedbackCorrecte
                              ? Color(red: 0.30, green: 0.78, blue: 0.55)
                              : Theme.rosaFort)
                )
                .shadow(color: .black.opacity(0.1), radius: 6, y: 3)
                .scaleEffect(batega ? 1.03 : 1.0)
                .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true),
                           value: batega)
                .onAppear { batega = true }
                .onDisappear { batega = false }
            }
            
            HStack(spacing: 14) {
                Button {
                    viewModel.checkAnswer()
                } label: {
                    HStack(spacing: 8) {
                        Text("✨")
                        Text("Comprova")
                            .font(.system(size: 18, weight: .heavy, design: .rounded))
                    }
                    .padding(.horizontal, 26)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
                .foregroundColor(.white)
                .background(Capsule().fill(Theme.lilaFort))
                .shadow(color: Theme.lilaFort.opacity(0.4), radius: 6, y: 4)
                .disabled(viewModel.selectedTipus == nil
                          || viewModel.isAnswered
                          || viewModel.isLoading)
                .opacity(viewModel.selectedTipus == nil || viewModel.isAnswered ? 0.5 : 1.0)
                .help("O prem la tecla Intro ⏎")
                
                if viewModel.isAnswered {
                    Button {
                        viewModel.advanceTurn()
                    } label: {
                        HStack(spacing: 8) {
                            Text("➡️")
                            Text("Següent")
                                .font(.system(size: 18, weight: .heavy, design: .rounded))
                        }
                        .padding(.horizontal, 26)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.white)
                    .background(Capsule().fill(Color(red: 0.30, green: 0.78, blue: 0.55)))
                    .shadow(color: .black.opacity(0.15), radius: 6, y: 4)
                    .transition(.scale.combined(with: .opacity))
                    .help("O prem la tecla Intro ⏎")
                }
            }
        }
        .frame(minHeight: 140)
    }
}
