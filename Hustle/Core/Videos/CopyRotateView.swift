import SwiftUI

struct CopyRotateView: View {
    let link: String
    @State var animating: Bool = false
    @State var showText: Bool = false
    @State private var rotate: Double = 0
    @State private var offsetY: Double = 0
    @State private var offsetX: Double = 0

    var body: some View {
        VStack {
            Button {
                UIPasteboard.general.string = "https://youtube.com/shorts/\(link)"
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                if rotate == 0 {
                    startAnimating()
                }
            } label: {
                ZStack {
                    Circle().fill(.gray.gradient.opacity(0.6)).frame(width: 56, height: 56)
                    Image(systemName: "arrowshape.turn.up.left.fill")
                        .offset(x: offsetX, y: offsetY)
                        .rotationEffect(.degrees(rotate))
                        .font(.title2)
                        .foregroundColor(.white)
                        .scaleEffect(animating ? 0.65 : 1)
                    
                    if showText {
                        Text("copied").font(.caption).foregroundColor(.white).scaleEffect(y: 1.2).bold()
                    }
                }
            }
        }
    }
    private func startAnimating() {
        withAnimation(.easeInOut){
            animating = true
            Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
                withAnimation(.easeInOut){
                    showText = true
                }
            }
            Timer.scheduledTimer(withTimeInterval: 1.8, repeats: false) { _ in
                withAnimation(.easeInOut){
                    showText = false
                }
            }
            Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
                withAnimation(.easeInOut){
                    animating = false
                }
            }
        }
        withAnimation(.linear(duration: 0.2)) {
            rotate = -180
            offsetY = -38
        }
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            withAnimation {
                rotate -= 13
            }
            if rotate < -720 {
                rotate = 0
                withAnimation(.linear(duration: 0.2)) {
                    offsetY = 0
                    timer.invalidate()
                }
            }
        }
    }
}
