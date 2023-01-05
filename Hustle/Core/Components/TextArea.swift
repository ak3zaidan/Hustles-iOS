import SwiftUI

struct TextArea: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var text: String
    let placeholder: String
    
    init(_ placeholder: String, text: Binding<String>){
        self.placeholder = placeholder
        self._text = text
        UITextView.appearance().backgroundColor = .clear
    }
    
    var body: some View {
        ZStack(alignment: .topLeading){
            TextEditor(text: $text)
                .padding(4)
                .tint(colorScheme == .dark ? .white : .black)
            if text.isEmpty{
                VStack(alignment: .leading){
                    HStack{
                        Text(placeholder)
                            .foregroundColor(Color(.placeholderText))
                            .font(.system(size: 18))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 12)
                        Spacer()
                    }
                }
            }
        }
        .font(.body)
    }
}
