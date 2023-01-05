import Foundation

struct DropdownMenuOption: Identifiable, Hashable {
    let id = UUID().uuidString
    let option: String
}

extension DropdownMenuOption {
    static let testAllMonths: [DropdownMenuOption] = [
        DropdownMenuOption(option: "Nearby"),
        DropdownMenuOption(option: "Remote"),
    ]
}

