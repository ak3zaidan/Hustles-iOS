import SwiftUI

struct DownMenu: View {
    @State private var isOptionsPresented: Bool = false
    @Binding var selectedOption: MenuOption?
    let placeholder: String
    let options: [MenuOption]
    @Environment(\.colorScheme) var colorScheme
    var body: some View {
        Button {
            withAnimation {
                self.isOptionsPresented.toggle()
            }
        } label: {
            HStack {
                if let picked = selectedOption, picked.option == "Closest first" {
                    Text("Closest")
                        .fontWeight(.medium).font(.caption)
                        .foregroundColor(colorScheme == .dark ? .gray : .black)
                } else if let picked = selectedOption, picked.option == "Price: Low to High" {
                    Text("$ -> $$")
                        .fontWeight(.medium).font(.caption)
                        .foregroundColor(colorScheme == .dark ? .gray : .black)
                } else if let picked = selectedOption, picked.option == "Price: High to Low" {
                    Text("$$ -> $")
                        .fontWeight(.medium).font(.caption)
                        .foregroundColor(colorScheme == .dark ? .gray : .black)
                } else if let picked = selectedOption, picked.option == "Newest first"{
                    Text("Newest")
                        .fontWeight(.medium).font(.caption)
                        .foregroundColor(colorScheme == .dark ? .gray : .black)
                } else {
                    Text(placeholder)
                        .fontWeight(.medium)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
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
            VStack{
                if self.isOptionsPresented {
                    Spacer(minLength: 50)
                    MenuShopList(options: self.options) { option in
                        self.isOptionsPresented = false
                        self.selectedOption = option
                    }
                }
            }.offset(x: -40)
        }
    }
}
