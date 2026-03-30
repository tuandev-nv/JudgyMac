import SwiftUI

struct MenuBarIcon: View {
    let mood: Mood

    var body: some View {
        Image(systemName: systemImage(for: mood))
            .symbolRenderingMode(.hierarchical)
            .contentTransition(.symbolEffect(.replace))
    }

    private func systemImage(for mood: Mood) -> String {
        switch mood {
        case .neutral:   return "face.smiling"
        case .judging:   return "face.smiling.inverse"
        case .horrified: return "exclamationmark.triangle"
        case .sleeping:  return "zzz"
        case .raging:    return "flame"
        case .impressed: return "star"
        }
    }
}
