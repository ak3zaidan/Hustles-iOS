import SwiftUI

struct Loader: View {
    let flip: Bool
    @Environment(\.colorScheme) var colorScheme
    @State private var rotation: Double = 0
    var body: some View {
        VStack {
            Image("load")
                .resizable()
                .frame(width: 55, height: 55)
                .rotationEffect(Angle(degrees: rotation))
                .onAppear {
                    withAnimation(Animation.linear(duration: 0.8).repeatForever(autoreverses: false)) {
                        self.rotation += flip ? (colorScheme == .dark ? -360 : 360) : 360
                    }
                }
                .onDisappear {
                    rotation = 0
                }
            
        }
    }
}
