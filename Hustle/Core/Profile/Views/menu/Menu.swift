import SwiftUI

struct MenuT: View {
    @State private var isOptionsPresented: Bool = false
    @Binding var selectedOption:  Option?
    let placeholder: String
    let options: [Option]
    
    var body: some View {
        Button {
            withAnimation {
                self.isOptionsPresented.toggle()
            }
        } label: {
            HStack(spacing: 2){
                Text(placeholder).fontWeight(.medium).font(.caption).foregroundColor(.gray)
                Image(systemName: self.isOptionsPresented ? "chevron.up" : "chevron.down")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .frame(width: 55)
            .scaleEffect(1.3)
        }
        .padding()
        .overlay(alignment: .topTrailing) {
            VStack {
                if self.isOptionsPresented {
                    Spacer(minLength: 60)
                    MenuList(options: self.options) { option in
                        self.isOptionsPresented = false
                        self.selectedOption = option
                    }
                }
            }
        }
    }
}

