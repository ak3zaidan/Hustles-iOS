import SwiftUI

struct DropdownMenuList: View {
    let options: [DropdownMenuOption]
    let onSelectedAction: (_ option: DropdownMenuOption) -> Void
    @Environment(\.colorScheme) var colorScheme
    var body: some View {
        LazyVStack(spacing: 2) {
            ForEach(options) { option in
                DropdownMenuListRow(option: option, onSelectedAction: self.onSelectedAction)
            }
        }
        .frame(width: 100, height: 75)
        .background(colorScheme == .dark ? .black : .white)
        .cornerRadius(12)
        .padding(.vertical, 8)
        .overlay {
            ZStack {
                RoundedRectangle(cornerRadius: 5)
                    .stroke(.gray, lineWidth: 2)
                    .frame(width: 100, height: 75)
                Divider().frame(width: 100)
            }
        }
    }
}
