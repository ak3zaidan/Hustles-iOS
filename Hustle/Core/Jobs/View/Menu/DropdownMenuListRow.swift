import SwiftUI

struct DropdownMenuListRow: View {
    let option: DropdownMenuOption
    let onSelectedAction: (_ option: DropdownMenuOption) -> Void
    
    var body: some View {
        Button {
            self.onSelectedAction(option)
        } label: {
            Text(option.option).bold()
        }
        .padding(.vertical, 5).padding(.horizontal)
    }
}
