import SwiftUI

// Interior content should be < by 11
struct StoryRingView: View {
    let color = LinearGradient(
        gradient: Gradient(colors: [Color(red: 0.54, green: 0.17, blue: 0.89), Color.red, Color.orange, Color.yellow]),
        startPoint: .topTrailing,
        endPoint: .bottomLeading
    )
    let size: CGFloat
    let active: Bool
    let strokeSize: CGFloat

    var body: some View {
        ZStack {
            if !active {
                Circle()
                    .stroke(Color.gray, lineWidth: strokeSize)
                    .frame(width: size - strokeSize, height: size - 4.0)
            } else {
                Circle()
                    .stroke(color, lineWidth: strokeSize)
                    .frame(width: size - strokeSize, height: size - 4.0)
            }
        }
    }
}
