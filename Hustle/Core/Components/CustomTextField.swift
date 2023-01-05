import SwiftUI

struct CustomTextField1: View {
    @Binding var text: String
    @Environment(\.colorScheme) var colorScheme
    @FocusState private var isFocused: Bool
    @Binding var displayText: String
    
    var body: some View {
        HStack {
            Image(systemName: "lock")
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .foregroundColor((colorScheme == .dark) ? .white : .gray)
            
            TextField("Password", text: $displayText)
                .tint((colorScheme == .dark) ? .white : .black)
                .focused($isFocused)
                .onChange(of: displayText) { _ in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1){
                        if text.isEmpty {
                            text = displayText
                        } else {
                            if displayText.isEmpty {
                                text = ""
                            } else if displayText.count < text.count {
                                text.removeLast()
                            } else if let lastChar = displayText.last, lastChar != "*" {
                                text += String(lastChar)
                            } else if !displayText.contains("*"){
                                text = displayText
                            }
                        }
                        displayText = String(repeating: "*", count: displayText.count)
                    }
                }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 5)
        .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.gray, lineWidth: isFocused ? 2 : 1))
    }
}

struct CustomTextField2: View {
    @Binding var text: String
    @Environment(\.colorScheme) var colorScheme
    @FocusState private var isFocused: Bool
    var body: some View {
        HStack{
            Image(systemName: "envelope")
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .foregroundColor((colorScheme == .dark) ? .white : .gray)

            TextField("Email", text: $text)
                .tint((colorScheme == .dark) ? .white : .black)
                .focused($isFocused)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 5)
        .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.gray, lineWidth: isFocused ? 2 : 1))
    }
}

struct CustomTextField: View {
    let imageName: String
    let placeHolderText: String
    var isSecureField: Bool? = false
    @Binding var text: String
    @Environment(\.colorScheme) var colorScheme
    @FocusState private var isFocused: Bool
    var body: some View {
        HStack{
            Image(systemName: imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .foregroundColor((colorScheme == .dark) ? .white : .gray)
            
            if isSecureField ?? false {
                SecureField(placeHolderText, text: $text)
                    .tint((colorScheme == .dark) ? .white : .black)
                    .focused($isFocused)
            } else {
                TextField(placeHolderText, text: $text)
                    .tint((colorScheme == .dark) ? .white : .black)
                    .focused($isFocused)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 5)
        .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.gray, lineWidth: isFocused ? 2 : 1))
    }
}

struct RoundedRightAngleShape: Shape {
    func path(in rect: CGRect) -> Path {
        let width = rect.size.width
        let height = rect.size.height
        
        let radius: CGFloat = 20
        
        var path = Path()
        path.move(to: CGPoint(x: 0, y: height))
        path.addLine(to: CGPoint(x: 0, y: radius))
        path.addArc(center: CGPoint(x: radius, y: radius),
                    radius: radius,
                    startAngle: Angle(degrees: 180),
                    endAngle: Angle(degrees: 270),
                    clockwise: false)
        path.addLine(to: CGPoint(x: width, y: 0))
        return path
    }
}
