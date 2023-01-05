import SwiftUI

struct CirclesExpand: View {
    @State private var animationFrame: CGFloat = 120.0
    @State private var animationOpacity: Double = 1.0
    @State private var animationOffset: Double = 0.0
    
    @State private var animationFrame1: CGFloat = 120.0
    @State private var animationOpacity1: Double = 1.0
    @State private var animationOffset1: Double = 0.0
    
    @State private var animationFrame2: CGFloat = 120.0
    @State private var animationOpacity2: Double = 1.0
    @State private var animationOffset2: Double = 0.0
    
    @State private var animationFrame3: CGFloat = 120.0
    @State private var animationOpacity3: Double = 1.0
    @State private var animationOffset3: Double = 0.0
    
    @State private var backgroundColor = Color.clear
    @State private var backgroundColor1 = Color.clear
    @State private var backgroundColor2 = Color.clear
    @State private var backgroundColor3 = Color.clear
    
    var body: some View {
        ZStack {
            ZStack {
                Circle()
                    .stroke(backgroundColor, lineWidth: 2)
                    .frame(width: animationFrame, height: animationFrame)
                    .opacity(self.animationOpacity)
                    .offset(y: animationOffset)
                Circle()
                    .stroke(backgroundColor1, lineWidth: 2)
                    .frame(width: animationFrame1, height: animationFrame1)
                    .opacity(self.animationOpacity1)
                    .offset(y: animationOffset1)
                Circle()
                    .stroke(backgroundColor2, lineWidth: 2)
                    .frame(width: animationFrame2, height: animationFrame2)
                    .opacity(self.animationOpacity2)
                    .offset(y: animationOffset2)
                Circle()
                    .stroke(backgroundColor3, lineWidth: 2)
                    .frame(width: animationFrame3, height: animationFrame3)
                    .opacity(self.animationOpacity3)
                    .offset(y: animationOffset3)
            }
            Image(systemName: "mappin.and.ellipse").foregroundStyle(.gray)
                .font(.title)
                .offset(y: animationOffset)
        }
        .padding(.top, 120)
        .onAppear {
            withAnimation(.easeIn(duration: 2.0).repeatForever(autoreverses: false)){
                self.animationFrame = 300
                self.animationOpacity = 0.0
                self.animationOffset = -90.0
                self.animationOffset1 = -90.0
                self.animationOffset2 = -90.0
                self.animationOffset3 = -90.0
                backgroundColor = .gray
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeIn(duration: 2.0).repeatForever(autoreverses: false)){
                    self.animationFrame1 = 300
                    self.animationOpacity1 = 0.0
                    backgroundColor1 = .gray
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeIn(duration: 2.0).repeatForever(autoreverses: false)){
                    self.animationFrame2 = 300
                    self.animationOpacity2 = 0.0
                    backgroundColor2 = .gray
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeIn(duration: 2.0).repeatForever(autoreverses: false)){
                    self.animationFrame3 = 300
                    self.animationOpacity3 = 0.0
                    backgroundColor3 = .gray
                }
            }
        }
    }
}
