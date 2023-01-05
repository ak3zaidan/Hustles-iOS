import Foundation
import SwiftUI

extension View{
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View{
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape{
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path{
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

struct ToastView: View {
    @Environment(\.colorScheme) var colorScheme
    let message: String
    @State private var opacity: Double = 0.0
    
    var body: some View {
        ZStack {
            Text(message)
                .padding(5)
                .font(.subheadline)
                .foregroundColor(colorScheme == .dark ? .black : .white)
                .background(colorScheme == .dark ? .white : .black.opacity(0.7))
                .cornerRadius(10)
        }
        .opacity(opacity)
        .transition(.opacity)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.3)) {
                self.opacity = 0.9
            }
        }
    }
}
