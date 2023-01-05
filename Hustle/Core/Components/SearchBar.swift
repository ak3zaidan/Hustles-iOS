import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    let fill: String
    var body: some View {
        HStack {
            TextField("Search \(fill)...", text: $text)
                .tint(.blue)
                .autocorrectionDisabled(true)
                .padding(8)
                .padding(.horizontal, 24)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .overlay(
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 8)
                )
        }
    }
}
