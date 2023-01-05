import SwiftUI

struct MenuRow: View {
    let option: MenuOption
    let onSelectedAction: (_ option: MenuOption) -> Void
    
    var body: some View {
        Button {
            self.onSelectedAction(option)
        } label: {
            Text(option.option).bold().frame(alignment: .leading)
        }
        .padding(.vertical, 5)
        .padding(.horizontal)
    }
}
