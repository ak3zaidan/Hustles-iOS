import SwiftUI

struct MenuShopList: View {
    let options: [MenuOption]
    let onSelectedAction: (_ option: MenuOption) -> Void
    @Environment(\.colorScheme) var colorScheme
    var body: some View {
        LazyVStack(alignment: .leading, spacing: 2) {
            ForEach(options) { option in
                MenuRow(option: option, onSelectedAction: self.onSelectedAction)
            }
        }
        .frame(width: 185, height: 140)
        .background(colorScheme == .dark ? .black : .white)
        .cornerRadius(8)
        .padding(.vertical, 5)
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(.gray, lineWidth: 2)
                .frame(width: 185, height: 140)
        }
    }
}
