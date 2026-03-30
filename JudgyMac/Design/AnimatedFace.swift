import SwiftUI

struct AnimatedFace: View {
    let mood: Mood
    var size: CGFloat = 32

    var body: some View {
        Text(mood.emoji)
            .font(.system(size: size * 0.65))
            .frame(width: size, height: size)
            .background(
                Circle()
                    .fill(Theme.Colors.accent(for: mood).opacity(0.12))
            )
            .contentTransition(.symbolEffect(.replace))
            .animation(.easeInOut(duration: 0.3), value: mood)
    }
}
