import SwiftUI

struct DropdownMenu: View {
    @State private var isOptionsPresented: Bool = false
    @Binding var selectedOption: DropdownMenuOption?
    let placeholder: String
    let options: [DropdownMenuOption]
    @Environment(\.colorScheme) var colorScheme
    var body: some View {
        Button {
            withAnimation {
                self.isOptionsPresented.toggle()
            }
        } label: {
            HStack {
                Text(selectedOption == nil ? placeholder : selectedOption!.option)
                    .fontWeight(.medium)
                    .font(.caption)
                    .foregroundColor(selectedOption == nil ? .gray : colorScheme == .dark ? .gray : .black)
                Image(systemName: self.isOptionsPresented ? "chevron.up" : "chevron.down")
                    .fontWeight(.medium)
                    .foregroundColor(colorScheme == .dark ? .gray : .black)
            }
        }
        .padding()
        .overlay {
            RoundedRectangle(cornerRadius: 5)
                .stroke(.gray, lineWidth: 2)
        }
        .overlay(alignment: .top) {
            VStack {
                if self.isOptionsPresented {
                    Spacer(minLength: 55)
                    DropdownMenuList(options: self.options) { option in
                        self.isOptionsPresented = false
                        self.selectedOption = option
                    }
                }
            }
        }
    }
}

