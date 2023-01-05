import SwiftUI

struct AICircle: View {
    let width: Double
    var body: some View {
        Circle()
            .stroke(LinearGradient(gradient: Gradient(colors: [Color.green, Color.blue]), startPoint: .leading, endPoint: .trailing), lineWidth: 4)
            .frame(width: CGFloat(width), height: CGFloat(width))
    }
}

struct AskIcon: View {
    @State private var text = ""
    @State private var text1 = "Ask me something"
    @State private var currentIndex = 0
    @Binding var isTop: Bool
    
    var body: some View {
        VStack(spacing: 10){
            LottieView(loopMode: .loop, name: "greenAnim")
                .frame(width: 65, height: 65).scaleEffect(0.7)
            Text(text).font(Font.custom("Revalia-Regular", size: 17, relativeTo: .title))
                .onAppear {
                    DispatchQueue.global().asyncAfter(deadline: .now() + 1.5) {
                        addCharacter()
                    }
                }
        }
    }

    func addCharacter() {
        if currentIndex < text1.count {
            let index = text1.index(text1.startIndex, offsetBy: currentIndex)
            text.append(text1[index])
            currentIndex += 1
            if isTop {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                addCharacter()
            }
        }
    }
}


