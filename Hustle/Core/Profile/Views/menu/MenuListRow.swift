import SwiftUI

struct MenuListRow: View {
    let option: Option

    var body: some View {
        Text(option.option)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 5).padding(.horizontal)
    }
}
