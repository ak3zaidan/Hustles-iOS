import SwiftUI

struct MenuList: View {
    @Environment(\.colorScheme) var colorScheme
    let options: [Option]
    let onSelectedAction: (_ option: Option) -> Void
    var body: some View {
        LazyVStack(alignment: .leading, spacing: 2) {
            ForEach(options) { option in
                MenuListRow(option: option)
            }
        }
        .frame(width: options == Option.queen ? 328 : 250, height: CGFloat(self.options.count * 32) > 300
               ? 300 : CGFloat(self.options.count * 32)
        )
        .background(colorScheme == .dark ? .gray : Color(UIColor.lightGray))
        .cornerRadius(5)
        .padding(.vertical, 10)
    }
}
